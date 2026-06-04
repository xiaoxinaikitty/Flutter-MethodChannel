import Flutter
import PhotosUI
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, PHPickerViewControllerDelegate {
  /// 这是原来的“信息类”通道。
  ///
  /// 它负责：
  /// - 获取电量
  /// - 获取设备型号
  /// - Dart 传字符串给原生处理
  private let infoChannelName = "samples.flutter.dev/battery"

  /// 这是“媒体类”通道。
  ///
  /// Dart 端会通过这条通道调用：
  /// - `openCamera`
  /// - `pickImageFromGallery`
  private let cameraChannelName = "samples.flutter.dev/camera"

  /// 这个变量用来暂存“当前等待返回的 Dart 调用结果”。
  ///
  /// 为什么现在不再叫 `pendingCameraResult`？
  /// 因为这条通道现在不只负责相机，也负责相册选择，
  /// 所以这里改成更通用的名字：`pendingMediaResult`
  private var pendingMediaResult: FlutterResult?

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

    /// 注册“媒体类”通道。
    let cameraChannel = FlutterMethodChannel(
      name: cameraChannelName,
      binaryMessenger: controller.binaryMessenger
    )

    cameraChannel.setMethodCallHandler { call, result in
      switch call.method {
      case "openCamera":
        self.openCamera(from: controller, result: result)

      case "pickImageFromGallery":
        self.pickImageFromGallery(from: controller, result: result)

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
  /// 这是媒体类通道里的第一个方法。
  /// 用户走的是“拍照”这条路径。
  private func openCamera(from controller: FlutterViewController, result: @escaping FlutterResult) {
    guard pendingMediaResult == nil else {
      result(
        FlutterError(
          code: "ALREADY_ACTIVE",
          message: "A media request is already in progress.",
          details: nil
        )
      )
      return
    }

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

    pendingMediaResult = result

    controller.present(picker, animated: true)
  }

  /// 打开系统相册选择图片。
  ///
  /// 这是媒体类通道里的第二个方法。
  /// 用户走的是“从相册选择”这条路径。
  ///
  /// 实现策略：
  /// - iOS 14 及以上：优先使用更现代的 `PHPickerViewController`
  /// - iOS 12 / 13：回退到 `UIImagePickerController` 的相册模式
  private func pickImageFromGallery(from controller: FlutterViewController, result: @escaping FlutterResult) {
    guard pendingMediaResult == nil else {
      result(
        FlutterError(
          code: "ALREADY_ACTIVE",
          message: "A media request is already in progress.",
          details: nil
        )
      )
      return
    }

    pendingMediaResult = result

    if #available(iOS 14, *) {
      /// 这是更现代的系统相册选择器。
      var configuration = PHPickerConfiguration(photoLibrary: .shared())

      /// `selectionLimit = 1` 表示当前示例只允许选一张图片。
      configuration.selectionLimit = 1

      /// 只允许选图片，不允许视频。
      configuration.filter = .images

      let picker = PHPickerViewController(configuration: configuration)
      picker.delegate = self
      controller.present(picker, animated: true)
    } else {
      /// iOS 12 / 13 回退到旧方案。
      guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
        pendingMediaResult = nil
        result(
          FlutterError(
            code: "UNAVAILABLE",
            message: "Photo library is not available on this device.",
            details: nil
          )
        )
        return
      }

      let picker = UIImagePickerController()
      picker.sourceType = .photoLibrary
      picker.delegate = self
      controller.present(picker, animated: true)
    }
  }

  /// `UIImagePickerController` 成功返回时的代理回调。
  ///
  /// 这个回调既可能来自：
  /// - 相机拍照
  /// - 老版本 iOS 的相册选择
  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let result = pendingMediaResult
    pendingMediaResult = nil

    picker.dismiss(animated: true)

    guard let result else {
      return
    }

    guard let image = info[.originalImage] as? UIImage else {
      result(
        FlutterError(
          code: "IMAGE_ERROR",
          message: "Failed to get image from media picker.",
          details: nil
        )
      )
      return
    }

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
      let imagePath = try saveImageToTemporaryDirectory(imageData, prefix: "media")
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

  /// `UIImagePickerController` 取消时的代理回调。
  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    let result = pendingMediaResult
    pendingMediaResult = nil

    picker.dismiss(animated: true)

    result?(
      FlutterError(
        code: "CANCELED",
        message: "The media operation was canceled.",
        details: nil
      )
    )
  }

  /// `PHPickerViewController` 返回时的代理回调。
  ///
  /// 这是 iOS 14+ 的现代相册选择器回调。
  @available(iOS 14, *)
  func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
    let result = pendingMediaResult
    pendingMediaResult = nil

    picker.dismiss(animated: true)

    guard let result else {
      return
    }

    guard let itemProvider = results.first?.itemProvider else {
      result(
        FlutterError(
          code: "CANCELED",
          message: "The gallery selection was canceled.",
          details: nil
        )
      )
      return
    }

    guard itemProvider.canLoadObject(ofClass: UIImage.self) else {
      result(
        FlutterError(
          code: "UNSUPPORTED",
          message: "The selected item is not a supported image.",
          details: nil
        )
      )
      return
    }

    /// `PHPicker` 的图片读取是异步的。
    itemProvider.loadObject(ofClass: UIImage.self) { object, error in
      DispatchQueue.main.async {
        if let error {
          result(
            FlutterError(
              code: "LOAD_ERROR",
              message: "Failed to load image: \(error.localizedDescription)",
              details: nil
            )
          )
          return
        }

        guard let image = object as? UIImage else {
          result(
            FlutterError(
              code: "IMAGE_ERROR",
              message: "Failed to get UIImage from picker.",
              details: nil
            )
          )
          return
        }

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
          let imagePath = try self.saveImageToTemporaryDirectory(imageData, prefix: "gallery")
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
    }
  }

  /// 把图片数据写入 iOS 临时目录，并返回图片路径。
  ///
  /// 为什么要存文件？
  /// 因为 Dart 侧现在统一按“图片路径”去做预览显示，
  /// 所以不管图片来自：
  /// - 相机
  /// - 相册
  ///
  /// 最终都转换成一个本地路径返回给 Dart。
  private func saveImageToTemporaryDirectory(_ imageData: Data, prefix: String) throws -> String {
    let directory = FileManager.default.temporaryDirectory
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyyMMdd_HHmmss"
    let fileName = "\(prefix)_\(formatter.string(from: Date())).jpg"
    let fileURL = directory.appendingPathComponent(fileName)

    try imageData.write(to: fileURL)

    return fileURL.path
  }
}
