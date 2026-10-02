import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var apnsToken: String?
  private var apnsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Register Flutter plugins with AppDelegate first
    GeneratedPluginRegistrant.register(with: self)

    // 2. Set delegate for foreground notification presentation
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
      let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
      UNUserNotificationCenter.current().requestAuthorization(
        options: authOptions,
        completionHandler: { _, _ in }
      )
    }

    // 3. Register for remote notifications directly on Apple APNs
    application.registerForRemoteNotifications()

    // 4. Required for local notifications background action isolate execution
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }

    let didLaunch = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    // 5. Setup native APNs MethodChannel directly on root FlutterViewController
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
    print("[AppDelegate] Remote notification registration note: \(error.localizedDescription)")
    super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
  }
}
