import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    
    // 🔒 Bloqueador nativo: Vigia todas as janelas (incluindo Tela Cheia)
    NotificationCenter.default.addObserver(
        self,
        selector: #selector(protegerTodasAsTelas),
        name: UIWindow.didBecomeVisibleNotification,
        object: nil
    )
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  @objc func protegerTodasAsTelas(notification: Notification) {
      if let window = notification.object as? UIWindow {
          // Cria um campo de texto seguro nativo para cegar o print do iOS
          let field = UITextField()
          field.isSecureTextEntry = true
          
          if !window.subviews.contains(where: { $0 is UITextField }) {
              window.addSubview(field)
              window.layer.superlayer?.addSublayer(field.layer)
              field.layer.subviews?.first?.addSublayer(window.layer)
          }
      }
  }
}