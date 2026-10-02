import Flutter
import UIKit
import UserNotifications
import flutter_local_notifications
import workmanager_apple
import flutter_foreground_task
import FirebaseCore

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var apnsToken: String?
  private var apnsChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 0. Ensure Firebase is configured natively before any APNs or plugin callbacks
    if (FirebaseApp.allApps?.count ?? 0) == 0 {
      if let filePath = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
         let options = FirebaseOptions(contentsOfFile: filePath) {
        FirebaseApp.configure(options: options)
      }
    }

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
        if let tokenData = self?.apnsDeviceTokenData, self?.isFirebaseConfigured == true {
          self?.forwardDeviceTokenToPlugins(tokenData, application: UIApplication.shared)
          result(true)
        } else {
          result(false)
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private var apnsDeviceTokenData: Data?

  private var isFirebaseConfigured: Bool {
    return (FirebaseApp.allApps?.count ?? 0) > 0
  }

  private func forwardDeviceTokenToPlugins(
    _ deviceToken: Data,
    application: UIApplication
  ) {
    super.application(
      application,
      didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
    )
  }

  private func retryForwardingDeviceToken(
    _ deviceToken: Data,
    application: UIApplication
  ) {
    guard isFirebaseConfigured else {
      print("[AppDelegate] Firebase is still not configured; APNs token forwarding skipped.")
      return
    }

    forwardDeviceTokenToPlugins(
      deviceToken,
      application: application
    )
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
    let token = tokenParts.joined()
    self.apnsToken = token
    self.apnsDeviceTokenData = deviceToken
    apnsChannel?.invokeMethod("onTokenReceived", arguments: token)

    // Forward to FlutterAppDelegate plugins (including Firebase Messaging) ONLY if Firebase has been initialized.
    // This strictly prevents FIRAppNotConfiguredException crash when Firebase is not yet ready.
    if isFirebaseConfigured {
      super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    } else {
      print("[AppDelegate] APNs device token received; Firebase not yet configured natively, deferring plugin forwarding to prevent FIRAppNotConfiguredException.")
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
        guard let self = self,
              let tokenData = self.apnsDeviceTokenData else {
          return
        }

        self.retryForwardingDeviceToken(
          tokenData,
          application: UIApplication.shared
        )
      }
    }
  }

  override func application(
    _ application: UIApplication,
    didFailToRegisterForRemoteNotificationsWithError error: Error
  ) {
    print("Failed to register for APNs: \(error.localizedDescription)")
    if isFirebaseConfigured {
      super.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    setupApnsChannel(binaryMessenger: engineBridge.applicationRegistrar.messenger())
  }
}



