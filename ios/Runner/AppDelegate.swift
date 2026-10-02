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
    // 1. Required for foreground notification presentation and user interaction on iOS
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    }

    // 2. Register for remote notifications on APNs
    application.registerForRemoteNotifications()

    // 3. Required for background action isolate execution
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // 4. Required for flutter_foreground_task background isolate execution on iOS
    SwiftFlutterForegroundTaskPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // 5. Workmanager background handlers
    if #available(iOS 13.0, *) {
      WorkmanagerPlugin.registerLaunchHandlers()
    }

    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 6. Setup APNs MethodChannel fallback safely after super launch
    if let controller = window?.rootViewController as? FlutterViewController {
      setupApnsChannel(binaryMessenger: controller.binaryMessenger)
    } else if let registrar = self.registrar(forPlugin: "ApnsNotificationPlugin") {
      setupApnsChannel(binaryMessenger: registrar.messenger())
    }

    return didLaunch
  }

  private func setupApnsChannel(binaryMessenger: FlutterBinaryMessenger) {
    guard apnsChannel == nil else { return }
    apnsChannel = FlutterMethodChannel(name: "com.hamdy.app154score/apns", binaryMessenger: binaryMessenger)
    apnsChannel?.setMethodCallHandler { [weak self] (call, result) in
      switch call.method {
      case "getApnsToken":
        result(self?.apnsToken)
      case "registerForRemoteNotifications":
        UIApplication.shared.registerForRemoteNotifications()
        result(true)
      case "syncApnsToken":
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
    print("[AppDelegate] Failed to register for remote notifications: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupApnsChannel(binaryMessenger: engineBridge.applicationRegistrar.messenger())
  }
}
