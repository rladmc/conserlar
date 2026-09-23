import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var protectView: UIView?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Quando o app sai de foco (multitarefa, tentativa de print ou gravação de tela)
  override func applicationWillResignActive(_ application: UIApplication) {
    self.protectView = UIView(frame: self.window?.bounds ?? CGRect.zero)
    self.protectView?.backgroundColor = UIColor.black // Tela preta de proteção
    if let protectView = self.protectView, let window = self.window {
      window.addSubview(protectView)
    }
  }

  // Quando o app volta para o foco normal
  override func applicationDidBecomeActive(_ application: UIApplication) {
    self.protectView?.removeFromSuperview()
    self.protectView = nil
  }
}