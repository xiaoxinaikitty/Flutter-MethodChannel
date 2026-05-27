import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  /// 这是原来的“信息类”通道。
  ///
  /// 它负责：
  /// - 获取电量
  /// - 获取设备型号
  /// - Dart 传字符串给原生处理
  private let infoChannelName = "samples.flutter.dev/battery"

  /// 这是新的“相机通道”。
  ///
  /// Dart 端会通过这条通道调用：
  /// `openCamera`
  private let cameraChannelName = "samples.flutter.dev/camera"

  /// 这个变量用来暂存“当前等待返回的 Dart 调用结果”。
  ///
  /// 为什么需要它？
  /// 因为打开系统相机不是同步操作：
  /// 1. Dart 先调用 `openCamera`
  /// 2. iOS 弹出系统相机
  /// 3. 用户拍照或取消
  /// 4. 过一会儿 delegate 回调才会触发
  ///
  /// 所以我们要先把 Flutter result 保存起来，等拍照结束后再返回给 Dart。
  private var pendingCameraResult: FlutterResult?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    guard let controller = window?.rootViewController as? FlutterViewController else {
      return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /// 注册“信息类”通道。
    let infoChannel = FlutterMethodChannel(
      name: infoChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    infoChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "getBatteryLevel":
        let batteryLevel = self.receiveBatteryLevel()

        if batteryLevel != -1 {
          result(batteryLevel)
        } else {
          result(
            FlutterError(
              code: "UNAVAILABLE",
              message: "Battery level not available.",
              details: nil
            )
          )
        }

      case "getDeviceModel":
        result(self.getDeviceModel())

      case "processUserName":
        if let processedMessage = self.processUserName(call: call) {
          result(processedMessage)
        } else {
          result(
            FlutterError(
              code: "INVALID_ARGUMENT",
              message: "The 'name' argument is missing or empty.",
              details: nil
            )
          )
        }

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    /// 注册“相机类”通道。
    let cameraChannel = FlutterMethodChannel(
      name: cameraChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    cameraChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "openCamera":
        self.openCamera(from: controller, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// 读取 iPhone / iPad 当前电量。
  private func receiveBatteryLevel() -> Int {
    UIDevice.current.isBatteryMonitoringEnabled = true
    let batteryLevel = UIDevice.current.batteryLevel

    if batteryLevel < 0 {
      return -1
    }

    return Int(batteryLevel * 100)
  }

  /// 获取 iOS 设备型号相关信息。
  private func getDeviceModel() -> String {
    let device = UIDevice.current
    return "\(device.model) / \(device.systemName) \(device.systemVersion)"
  }

  /// 处理 Dart 传来的名字参数。
  private func processUserName(call: FlutterMethodCall) -> String? {
    guard let arguments = call.arguments as? [String: Any] else {
      return nil
    }

    let name = (arguments["name"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines)
    let from = (arguments["from"] as? String) ?? "unknown"

    guard let name, !name.isEmpty else {
      return nil
    }

    return """
    iOS 原生已收到名字：\(name)
    名字长度：\(name.count)
    请求来源：\(from)
    当前设备：\(getDeviceModel())
    """
  }

  /// 打开系统相机。
  ///
  /// 这是第四个示例的核心函数。
  ///
  /// 执行流程：
  /// 1. Dart 调用 `openCamera`
  /// 2. iOS 检查当前设备是否支持相机
  /// 3. 创建系统相机控制器
  /// 4. 展示系统相机界面
  /// 5. 用户拍照完成后，在代理回调里保存图片并返回路径给 Dart
  private func openCamera(from controller: FlutterViewController, result: @escaping FlutterResult) {
    /// 如果上一次相机请求还没结束，就先拒绝新的调用。
    guard pendingCameraResult == nil else {
      result(
        FlutterError(
          code: "ALREADY_ACTIVE",
          message: "A camera request is already in progress.",
          details: nil
        )
      )
      return
    }

    /// 检查当前设备是否真的支持相机。
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      result(
        FlutterError(
          code: "UNAVAILABLE",
          message: "Camera is not available on this device.",
          details: nil
        )
      )
      return
    }

    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = self

    /// 先把 Flutter 结果保存起来，等代理回调时再返回。
    pendingCameraResult = result

    controller.present(picker, animated: true)
  }

  /// 用户拍照成功后的代理回调。
  ///
  /// 这里做三件事：
  /// 1. 从系统相机结果里拿到图片
  /// 2. 把图片写到临时目录
  /// 3. 把图片路径回传给 Dart
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let result = pendingCameraResult
    pendingCameraResult = nil

    picker.dismiss(animated: true)

    guard let result else {
      return
    }

    /// 从相机返回的数据里取出拍到的原始图片。
    guard let image = info[.originalImage] as? UIImage else {
      result(
        FlutterError(
          code: "IMAGE_ERROR",
          message: "Failed to get image from camera.",
          details: nil
        )
      )
      return
    }

    /// 把图片转成 JPEG 数据。
    guard let imageData = image.jpegData(compressionQuality: 0.9) else {
      result(
        FlutterError(
          code: "ENCODE_ERROR",
          message: "Failed to encode image data.",
          details: nil
        )
      )
      return
    }

    do {
      let imagePath = try saveImageToTemporaryDirectory(imageData)
      result(imagePath)
    } catch {
      result(
        FlutterError(
          code: "FILE_ERROR",
          message: "Failed to save image: \(error.localizedDescription)",
          details: nil
        )
      )
    }
  }

  /// 用户取消相机时的代理回调。
  ///
  /// 这里我们返回一个错误给 Dart，方便你在页面上明确看到“用户取消了”。
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    let result = pendingCameraResult
    pendingCameraResult = nil

    picker.dismiss(animated: true)

    result?(
      FlutterError(
        code: "CANCELED",
        message: "The camera operation was canceled.",
        details: nil
      )
    )
  }

  /// 把拍到的图片写入 iOS 临时目录，并返回图片路径。
  ///
  /// 为什么要存文件？
  /// 因为 Dart 侧最容易处理的就是“图片路径”：
  /// - 文字可以直接显示路径
  /// - 后面也可以用 `Image.file` 加载图片
  private func saveImageToTemporaryDirectory(_ imageData: Data) throws -> String {
    let directory = FileManager.default.temporaryDirectory
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let fileName = "camera_\(formatter.string(from: Date())).jpg"
    let fileURL = directory.appendingPathComponent(fileName)

    try imageData.write(to: fileURL)

    return fileURL.path
  }
}
