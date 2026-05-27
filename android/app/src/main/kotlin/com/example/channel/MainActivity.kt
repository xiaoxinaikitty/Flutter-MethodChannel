package com.example.channel

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity() {
    /// 这是原来用于电量、设备型号、字符串处理的通道名。
    ///
    /// Dart 端对应：
    /// `MethodChannel('samples.flutter.dev/battery')`
    private val infoChannelName = "samples.flutter.dev/battery"

    /// 这是新加的“相机通道”。
    ///
    /// 我们故意把相机拆成单独通道，是为了让结构更清晰：
    /// - `battery` 通道负责信息类示例
    /// - `camera` 通道负责相机类示例
    ///
    /// Dart 端之后会对应：
    /// `MethodChannel('samples.flutter.dev/camera')`
    private val cameraChannelName = "samples.flutter.dev/camera"

    /// 这是系统相机请求码。
    ///
    /// 当系统相机关闭并回调 `onActivityResult` 时，
    /// 我们会通过这个数字判断：
    /// “这次返回的结果，是不是来自相机拍照请求。”
    private val cameraRequestCode = 1001

    /// 这个变量用来保存“当前等待返回结果的 Dart 调用”。
    ///
    /// 为什么需要它？
    /// 因为打开系统相机不是同步操作：
    /// 1. Dart 先调用 `openCamera`
    /// 2. Android 打开系统相机界面
    /// 3. 用户拍照或取消
    /// 4. Android 过一会儿才拿到结果
    ///
    /// 所以我们要先把 `result` 暂存起来，等拍照结束后再回传给 Dart。
    private var pendingCameraResult: MethodChannel.Result? = null

    /// 这个变量保存“当前拍照输出文件”的绝对路径。
    ///
    /// 拍照前会先创建一个临时图片文件，
    /// 然后把它交给系统相机 App 去写入照片内容。
    private var currentPhotoPath: String? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        /// 先注册“信息类”通道：
        /// - getBatteryLevel
        /// - getDeviceModel
        /// - processUserName
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, infoChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getBatteryLevel" -> {
                        val batteryLevel = getBatteryLevel()

                        if (batteryLevel != -1) {
                            result.success(batteryLevel)
                        } else {
                            result.error(
                                "UNAVAILABLE",
                                "Battery level not available on this device or emulator.",
                                null
                            )
                        }
                    }

                    "getDeviceModel" -> {
                        result.success(getDeviceModel())
                    }

                    "processUserName" -> {
                        val processedMessage = processUserName(call)

                        if (processedMessage == null) {
                            result.error(
                                "INVALID_ARGUMENT",
                                "The 'name' argument is missing or empty.",
                                null
                            )
                        } else {
                            result.success(processedMessage)
                        }
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }

        /// 再注册“相机类”通道：
        /// - openCamera
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cameraChannelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openCamera" -> {
                        openCamera(result)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
    }

    /// 读取 Android 设备当前电量。
    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

        if (batteryLevel in 0..100) {
            return batteryLevel
        }

        return getBatteryLevelFromIntent()
    }

    /// 通过系统电池广播获取电量。
    private fun getBatteryLevelFromIntent(): Int {
        val batteryStatus: Intent? = registerReceiver(
            null,
            IntentFilter(Intent.ACTION_BATTERY_CHANGED)
        )

        val level = batteryStatus?.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) ?: -1
        val scale = batteryStatus?.getIntExtra(BatteryManager.EXTRA_SCALE, -1) ?: -1

        if (level < 0 || scale <= 0) {
            return -1
        }

        return (level * 100) / scale
    }

    /// 获取 Android 设备型号。
    private fun getDeviceModel(): String {
        val brand = Build.BRAND
        val model = Build.MODEL
        val device = Build.DEVICE

        return "$brand $model ($device)"
    }

    /// 处理 Dart 传来的名字参数。
    private fun processUserName(call: MethodCall): String? {
        val name = call.argument<String>("name")?.trim()
        val from = call.argument<String>("from") ?: "unknown"

        if (name.isNullOrEmpty()) {
            return null
        }

        return buildString {
            append("Android 原生已收到名字：")
            append(name)
            append('\n')
            append("名字长度：")
            append(name.length)
            append('\n')
            append("请求来源：")
            append(from)
            append('\n')
            append("当前设备：")
            append(getDeviceModel())
        }
    }

    /// 打开系统相机。
    ///
    /// 这是第四个示例最核心的函数。
    ///
    /// 它的执行流程是：
    /// 1. Dart 调用 `openCamera`
    /// 2. Android 先创建一个临时图片文件
    /// 3. Android 把这个文件包装成 `content://` 的 Uri
    /// 4. 启动系统相机
    /// 5. 用户拍照完成后，在回调里把图片路径返回给 Dart
    private fun openCamera(result: MethodChannel.Result) {
        /// 如果上一次拍照还没结束，就先拒绝新的请求。
        if (pendingCameraResult != null) {
            result.error(
                "ALREADY_ACTIVE",
                "A camera request is already in progress.",
                null
            )
            return
        }

        val imageFile = try {
            createImageFile()
        } catch (error: Exception) {
            result.error(
                "FILE_ERROR",
                "Failed to create image file: ${error.message}",
                null
            )
            return
        }

        /// 先记录图片路径，等拍照成功后回传给 Dart。
        currentPhotoPath = imageFile.absolutePath

        /// 通过 FileProvider 把普通文件转换成安全的内容 Uri。
        val photoUri = FileProvider.getUriForFile(
            this,
            "${applicationContext.packageName}.fileprovider",
            imageFile
        )

        /// 创建系统拍照 Intent。
        val cameraIntent = Intent(MediaStore.ACTION_IMAGE_CAPTURE).apply {
            /// `EXTRA_OUTPUT` 的意思是：
            /// “请系统相机把拍到的照片直接写到这个 Uri 对应的文件里。”
            putExtra(MediaStore.EXTRA_OUTPUT, photoUri)

            /// 给系统相机临时读写这个 Uri 的权限。
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }

        /// 先检查系统里是否真的有相机应用能处理这个 Intent。
        if (cameraIntent.resolveActivity(packageManager) == null) {
            currentPhotoPath = null
            result.error(
                "UNAVAILABLE",
                "No camera app found on this device.",
                null
            )
            return
        }

        /// 暂存这次 Dart 调用的结果对象。
        pendingCameraResult = result

        /// 用经典方式启动系统相机。
        ///
        /// 之所以改成这套写法，是为了兼容当前项目环境。
        startActivityForResult(cameraIntent, cameraRequestCode)
    }

    /// 接收系统 Activity 的返回结果。
    ///
    /// 这里是经典 Android 写法：
    /// - `requestCode`：是哪一次请求回来的
    /// - `resultCode`：成功、取消还是其他状态
    /// - `data`：附加数据
    ///
    /// 对这个示例来说，我们主要关心：
    /// 1. `requestCode` 是否等于 `cameraRequestCode`
    /// 2. `resultCode` 是否等于 `Activity.RESULT_OK`
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode != cameraRequestCode) {
            return
        }

        val result = pendingCameraResult
        val photoPath = currentPhotoPath

        /// 回调结束后，先把状态清空，避免下次请求冲突。
        pendingCameraResult = null
        currentPhotoPath = null

        if (result == null) {
            return
        }

        if (resultCode == Activity.RESULT_OK && !photoPath.isNullOrEmpty()) {
            /// 拍照成功，直接把图片本地路径回传给 Dart。
            result.success(photoPath)
        } else {
            /// 这里把“取消拍照”也作为错误提示返回，方便入门学习时更容易观察结果。
            result.error(
                "CANCELED",
                "The camera operation was canceled or failed.",
                null
            )
        }
    }

    /// 创建一个用于保存拍照结果的临时图片文件。
    ///
    /// 为什么要提前创建文件？
    /// 因为 `TakePicture()` 这种系统拍照方式要求我们先提供一个目标文件，
    /// 系统相机才知道要把照片写到哪里。
    private fun createImageFile(): File {
        /// 用时间戳生成文件名，避免文件重名。
        val timeStamp = SimpleDateFormat("yyyyMMdd_HHmmss", Locale.US).format(Date())

        /// 在应用缓存目录下创建一个 `images` 子目录。
        val storageDir = File(cacheDir, "images")
        if (!storageDir.exists()) {
            storageDir.mkdirs()
        }

        return File.createTempFile(
            "JPEG_${timeStamp}_",
            ".jpg",
            storageDir
        )
    }
}
