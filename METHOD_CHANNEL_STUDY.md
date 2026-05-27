# MethodChannel 学习笔记

这个项目现在已经加入了两个最小可运行的 `MethodChannel` 示例：

1. 点击按钮，向原生平台请求“当前电量”
2. 点击按钮，向原生平台请求“设备型号”

然后再把结果显示回 Flutter 页面。

你可以把这件事理解成 4 步：

1. Flutter 先创建一条通信通道
2. Flutter 通过这条通道发起不同的方法调用
3. Android / iOS 原生代码接收这个调用
4. 原生代码把结果返回给 Flutter

---

## 1. 你现在要先看哪些文件

最重要的 4 个文件：

1. [lib/main.dart](/D:/project/MethodChannel/lib/main.dart)
2. [android/app/src/main/kotlin/com/example/channel/MainActivity.kt](/D:/project/MethodChannel/android/app/src/main/kotlin/com/example/channel/MainActivity.kt)
3. [ios/Runner/AppDelegate.swift](/D:/project/MethodChannel/ios/Runner/AppDelegate.swift)
4. [test/widget_test.dart](/D:/project/MethodChannel/test/widget_test.dart)

建议阅读顺序：

1. 先看 `lib/main.dart`
2. 再看 Android 的 `MainActivity.kt`
3. 然后看 iOS 的 `AppDelegate.swift`
4. 最后看这个文档回顾整体流程

---

## 2. Dart 端做了什么

位置：[lib/main.dart](/D:/project/MethodChannel/lib/main.dart)

核心代码有两处。

第一处：定义通道

```dart
static const MethodChannel _channel = MethodChannel(
  'samples.flutter.dev/battery',
);
```

这句代码的意思是：

- Flutter 创建了一条名为 `samples.flutter.dev/battery` 的通信通道
- 这个名字是 Dart 和原生之间的“暗号”
- Android / iOS 必须也使用同一个名字

如果名字不一样，会发生什么？

- Flutter 调用时找不到原生接收方
- 常见结果是 `MissingPluginException`

第二处：调用原生方法

```dart
final int? batteryLevel = await _channel.invokeMethod<int>(
  'getBatteryLevel',
);
```

这句代码的意思是：

- Flutter 通过 `_channel` 发起一次调用
- 调用的方法名叫 `getBatteryLevel`
- 希望原生返回一个 `int`
- 因为是异步调用，所以要写 `await`

你可以把它理解为：

- 通道名 = 打给哪条线路
- 方法名 = 这次要办什么事
- 返回值 = 原生办完事以后给 Flutter 的答复

在当前项目里，Dart 端已经演示了两个方法名：

- `getBatteryLevel`
- `getDeviceModel`

这说明：

- 同一条通道，不一定只做一件事
- 你可以在同一条通道里定义多个原生方法
- 原生端再通过方法名区分应该执行哪段逻辑

---

## 3. Android 原生端做了什么

位置：[android/app/src/main/kotlin/com/example/channel/MainActivity.kt](/D:/project/MethodChannel/android/app/src/main/kotlin/com/example/channel/MainActivity.kt)

Android 端做了两件关键事情。

第一件：注册同名通道

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
```

其中 `channelName` 是：

```kotlin
"samples.flutter.dev/battery"
```

这必须和 Dart 完全一致。

第二件：处理方法调用

```kotlin
if (call.method == "getBatteryLevel") {
    val batteryLevel = getBatteryLevel()
    result.success(batteryLevel)
} else {
    result.notImplemented()
}
```

这段逻辑的意思是：

- 如果 Flutter 调用的是 `getBatteryLevel`
- 那么 Android 就真的去读取系统电量
- 读完以后通过 `result.success(...)` 把结果返回给 Dart

如果方法名对不上：

- 就会执行 `result.notImplemented()`
- Dart 侧会发现这个方法没被实现

Android 获取电量的关键 API 是：

```kotlin
BatteryManager.BATTERY_PROPERTY_CAPACITY
```

它返回的是当前设备电量百分比，通常是 `0 ~ 100`。

现在项目里又加了第二个 Android 原生方法：

```kotlin
"getDeviceModel" -> {
    result.success(getDeviceModel())
}
```

它的作用是：

- 当 Flutter 调用 `getDeviceModel`
- Android 读取设备品牌、型号、设备代号
- 再把拼好的字符串返回给 Dart

Android 获取设备型号使用的关键字段是：

```kotlin
Build.BRAND
Build.MODEL
Build.DEVICE
```

---

## 4. iOS 原生端做了什么

位置：[ios/Runner/AppDelegate.swift](/D:/project/MethodChannel/ios/Runner/AppDelegate.swift)

iOS 端和 Android 思路完全一样：

1. 建立同名通道
2. 监听不同的方法名
3. 调用 iOS 的系统 API 读取对应数据
4. 把结果返回给 Flutter

关键代码：

```swift
let channel = FlutterMethodChannel(
  name: "samples.flutter.dev/battery",
  binaryMessenger: controller.binaryMessenger
)
```

处理调用：

```swift
if call.method == "getBatteryLevel" {
  let batteryLevel = self.receiveBatteryLevel()
  result(batteryLevel)
} else {
  result(FlutterMethodNotImplemented)
}
```

iOS 获取电量的关键 API 是：

```swift
UIDevice.current.batteryLevel
```

注意这个值不是 `0 ~ 100`，而是：

- `0.0 ~ 1.0`

所以代码里做了转换：

```swift
Int(batteryLevel * 100)
```

现在项目里也加了第二个 iOS 原生方法：

```swift
case "getDeviceModel":
  result(self.getDeviceModel())
```

它返回的是：

- 设备名
- 系统名
- 系统版本

例如：

- `iPhone / iOS 18.0`

对应的关键 API 是：

```swift
UIDevice.current.model
UIDevice.current.systemName
UIDevice.current.systemVersion
```

---

## 5. 整个调用链路怎么串起来

当你点击页面按钮时，实际发生的顺序是：

1. Flutter 按钮触发某个 Dart 函数
2. Dart 调用：
   `invokeMethod('某个方法名')`
3. 原生平台收到这个方法名
4. 原生根据方法名决定执行哪段逻辑
5. 原生把结果返回给 Flutter
6. Flutter `setState` 刷新页面

如果你点击“获取原生电量”：

- Dart 调用 `getBatteryLevel`
- 原生返回整数电量

如果你点击“获取设备型号”：

- Dart 调用 `getDeviceModel`
- 原生返回字符串型号信息

---

## 6. 你必须记住的 3 个“必须一致”

做 `MethodChannel` 最容易出错的地方，就是下面这 3 项不一致：

1. 通道名必须一致
2. 方法名必须一致
3. 返回值类型要基本对应

在这个项目里分别是：

- 通道名：`samples.flutter.dev/battery`
- 方法名 1：`getBatteryLevel`
- 方法名 2：`getDeviceModel`
- 返回值 1：`int`
- 返回值 2：`String`

举例：

- Dart 写的是 `getBatteryLevel`
- Android 写成了 `getBattery`
- 那么 Flutter 调用后就找不到这个方法

---

## 7. 常见返回方式

原生端常见有 3 种结果：

1. 成功：返回数据
2. 失败：返回错误
3. 未实现：告诉 Flutter 这个方法不存在

Android：

- 成功：`result.success(...)`
- 失败：`result.error(...)`
- 未实现：`result.notImplemented()`

iOS：

- 成功：`result(...)`
- 失败：`result(FlutterError(...))`
- 未实现：`result(FlutterMethodNotImplemented)`

---

## 8. Dart 侧为什么要写 try-catch

因为调用原生并不一定成功。

例如：

1. 你正在 Windows 上运行项目
2. 通道名写错了
3. 方法名写错了
4. 原生端主动返回错误

所以 Dart 端写了：

- `MissingPluginException`
- `PlatformException`
- `catch`

这样即使调用失败，页面也不会直接崩掉，而是把错误信息显示给你看。

---

## 9. 如何运行这个示例

### 在 Android 真机或模拟器运行

```bash
flutter run
```

如果你连接的是 Android 设备：

- 打开应用
- 点击“获取原生电量”
- 页面会显示当前电量百分比

### 在 iPhone 模拟器或真机运行

同样使用：

```bash
flutter run
```

前提是你在 macOS 上用 Xcode 环境运行 iOS。

### 在 Windows / Web / macOS / Linux 上运行

页面仍然能打开，但这个示例不会真的获取手机电量，因为你没有对应的 Android / iOS 原生层。

这是正常现象。

---

## 10. 下一步你可以练什么

学完这两个示例后，建议你自己动手改成下面这些练习：

1. 把 `getBatteryLevel` 改成 `getPlatformVersion`
2. 让 Dart 传参数给原生，比如用户名
3. 让原生返回一个 `Map`
4. 试着增加第三个方法，比如 `showNativeToast`
5. 尝试把“通道名”改成你自己的项目命名空间

---

## 12. 为什么这里继续用同一条通道

你可能会问：

“既然已经有获取电量的通道了，为什么获取设备型号不再新建一条通道？”

这是一个很好的问题。

这个项目故意继续使用同一条通道，是为了让你理解：

- 一条 `MethodChannel` 更像“一个服务入口”
- 它下面可以挂多个方法
- 就像后端一个接口模块下面可以有多个 API

什么时候适合继续用同一条通道？

- 这些功能属于同一类能力
- 你希望统一管理它们
- 方法数量不多，结构还比较清晰

什么时候可以拆成多条通道？

- 功能模块差异很大
- 想把不同能力拆开管理
- 原生端代码已经明显变复杂

---

## 11. 一句话总结

`MethodChannel` 的本质就是：

Flutter 用“通道名 + 方法名”去调用原生代码，原生根据方法名执行不同逻辑，再把结果回传给 Flutter。
