import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications
import workmanager_apple
import flutter_foreground_task

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsToken: String?
  private var apnsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Required for foreground notification presentation and user interaction on iOS
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }

    // Required for background action isolate execution
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Required for flutter_foreground_task background isolate execution on iOS
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Required for workmanager background task re-registration (UIScene lifecycle)
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerLaunchHandlers()
      WorkmanagerPlugin.registerPeriodicTask(withIdentifier: "154score_notif_poll")
    }

    // Setup APNs MethodChannel for zero-delay notifications without Firebase
    if let registrar = self.registrar(forPlugin: "ApnsNotificationPlugin") {
      setupApnsChannel(binaryMessenger: registrar.messenger())
    } else if let controller = window?.rootViewController as? FlutterViewController {
      setupApnsChannel(binaryMessenger: controller.binaryMessenger)
    }

    application.registerForRemoteNotifications()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func setupApnsChannel(binaryMessenger: FlutterBinaryMessenger) {
    apnsChannel = FlutterMethodChannel(name: "com.hamdy.app154score/apns", binaryMessenger: binaryMessenger)
    apnsChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getApnsToken":
        result(self?.apnsToken)
      case "registerForRemoteNotifications":
        UIApplication.shared.registerForRemoteNotifications()
        result(true)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    self.apnsToken = token
    apnsChannel?.invokeMethod("onTokenReceived", arguments: token)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for APNs: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    completionHandler(.newData)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}


