import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    let channel = FlutterMethodChannel(
      name: "samples.flutter.dev/battery",
      binaryMessenger: controller.binaryMessenger
    )

    /// 这里和 Android 一样，注册一个同名通道。
    ///
    /// Dart 调用：
    /// - `invokeMethod('getBatteryLevel')`
    /// - `invokeMethod('getDeviceModel')`
    ///
    /// iOS 都会在这里收到请求，然后根据方法名分别处理。
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "getBatteryLevel":
        let batteryLevel = self.receiveBatteryLevel()

        if batteryLevel != -1 {
          /// 返回成功结果给 Dart。
          result(batteryLevel)
        } else {
          /// 返回错误给 Dart。
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Battery level not available.",
              details: nil
            )
          )
        }

      case "getDeviceModel":
        /// 返回设备型号相关信息给 Dart。
        result(self.getDeviceModel())

      default:
        /// Dart 调用了未实现的方法时，告诉 Flutter：这里没有这个实现。
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 读取 iPhone / iPad 当前电量。
  ///
  /// `UIDevice.current.batteryLevel` 返回 0.0 ~ 1.0 之间的小数。
  /// 比如：
  /// - 0.55 表示 55%
  /// - -1.0 表示当前拿不到电量信息
  private func receiveBatteryLevel() -> Int {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel

    if batteryLevel < 0 {
      return -1
    }

    return Int(batteryLevel * 100)
  }

  /// 获取 iOS 设备型号相关信息。
  ///
  /// 这里为了教学更直观，返回的是“设备名 + 系统名 + 系统版本”。
  /// 例如：
  /// - iPhone / iOS 18.0
  /// - iPad / iPadOS 18.0
  ///
  /// 注意：
  /// `UIDevice.current.model` 返回的是用户可读的设备类别，
  /// 比如 iPhone / iPad，而不是底层硬件代号。
  private func getDeviceModel() -> String {
    let device = UIDevice.current
    return "\(device.model) / \(device.systemName) \(device.systemVersion)"
  }
}
