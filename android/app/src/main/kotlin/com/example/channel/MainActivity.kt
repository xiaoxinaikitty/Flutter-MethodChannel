package com.example.channel

import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.os.Build
import android.os.BatteryManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    /// 这里的通道名必须和 Dart 端完全一致。
    ///
    /// Dart:
    /// `MethodChannel('samples.flutter.dev/battery')`
    ///
    /// Android:
    /// `MethodChannel(..., "samples.flutter.dev/battery")`
    ///
    /// 只要有一个字符不同，就会导致通信失败。
    private val channelName = "samples.flutter.dev/battery"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        /// 给 Flutter 注册一个 MethodChannel。
        ///
        /// 它做的事情可以理解为：
        /// “如果 Dart 那边拨打了 `samples.flutter.dev/battery`
        /// 这条通信线路，就由这里来接电话。”
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                /// `call.method` 就是 Dart 端 `invokeMethod(...)` 传来的方法名。
                ///
                /// 这里演示两种方法：
                /// 1. `getBatteryLevel`
                /// 2. `getDeviceModel`
                when (call.method) {
                    "getBatteryLevel" -> {
                        val batteryLevel = getBatteryLevel()

                        if (batteryLevel != -1) {
                            /// `result.success(...)` 表示调用成功，并把数据返回给 Dart。
                            result.success(batteryLevel)
                        } else {
                            /// `result.error(...)` 表示调用失败。
                            ///
                            /// Dart 端会收到一个 `PlatformException`。
                            result.error(
                                "UNAVAILABLE",
                                "Battery level not available on this device or emulator.",
                                null
                            )
                        }
                    }

                    "getDeviceModel" -> {
                        /// 设备型号通常总能拿到，所以这里直接返回字符串。
                        result.success(getDeviceModel())
                    }

                    else -> {
                        /// 如果 Dart 调用了一个原生没实现的方法，就返回“未实现”。
                        result.notImplemented()
                    }
                }
            }
    }

    /// 读取 Android 设备当前电量。
    ///
    /// 返回值说明：
    /// - 正常时返回 0~100 的整数
    /// - 失败时返回 -1
    private fun getBatteryLevel(): Int {
        val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
        val batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)

        if (batteryLevel in 0..100) {
            return batteryLevel
        }

        /// 某些设备或模拟器上，`BATTERY_PROPERTY_CAPACITY` 可能返回无效值。
        ///
        /// 这里增加第二套兜底方案：读取系统发出的电池广播。
        return getBatteryLevelFromIntent()
    }

    /// 通过系统电池广播获取电量。
    ///
    /// `level` 是当前电量值，`scale` 是最大刻度。
    /// 例如：
    /// - level = 50
    /// - scale = 100
    /// 那么当前电量就是 50%
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
    ///
    /// 这里组合了三个常见字段：
    /// - `Build.BRAND`：品牌，比如 Xiaomi / samsung
    /// - `Build.MODEL`：型号，比如 2211133C / SM-S9180
    /// - `Build.DEVICE`：设备代号
    ///
    /// 之所以拼成一个字符串，是为了让 Dart 页面更直观看到原生返回的数据。
    private fun getDeviceModel(): String {
        val brand = Build.BRAND
        val model = Build.MODEL
        val device = Build.DEVICE

        return "$brand $model ($device)"
    }
}
