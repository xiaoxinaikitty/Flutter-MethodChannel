# MethodChannel 学习笔记

这个项目现在已经包含 4 个最小可运行的 `MethodChannel` 示例：

1. 获取原生手机电量
2. 获取原生设备型号
3. Dart 传参数给原生，原生处理后再返回结果
4. Dart 调用原生系统相机

你可以把这 4 个例子理解成一个逐步升级的学习过程：

1. 先学“Dart 调原生”
2. 再学“同一条通道处理多个方法”
3. 再学“Dart 给原生传参数”
4. 最后学“原生打开系统界面，并异步返回结果”

---

## 1. 你现在要先看哪些文件

最重要的文件：

1. [lib/main.dart](/D:/project/MethodChannel/lib/main.dart)
2. [android/app/src/main/kotlin/com/example/channel/MainActivity.kt](/D:/project/MethodChannel/android/app/src/main/kotlin/com/example/channel/MainActivity.kt)
3. [ios/Runner/AppDelegate.swift](/D:/project/MethodChannel/ios/Runner/AppDelegate.swift)
4. [android/app/src/main/AndroidManifest.xml](/D:/project/MethodChannel/android/app/src/main/AndroidManifest.xml)
5. [android/app/src/main/res/xml/file_paths.xml](/D:/project/MethodChannel/android/app/src/main/res/xml/file_paths.xml)
6. [ios/Runner/Info.plist](/D:/project/MethodChannel/ios/Runner/Info.plist)
7. [test/widget_test.dart](/D:/project/MethodChannel/test/widget_test.dart)

建议阅读顺序：

1. 先看 `lib/main.dart`
2. 再看 Android 的 `MainActivity.kt`
3. 然后看 iOS 的 `AppDelegate.swift`
4. 再看 AndroidManifest / Info.plist 这些平台配置
5. 最后回来看这份文档

---

## 2. MethodChannel 最核心的 4 个概念

学习 `MethodChannel` 时，你要一直记住这 4 个东西：

1. 通道名
2. 方法名
3. 参数
4. 返回值

在当前项目里，一共有 2 条通道：

1. `samples.flutter.dev/battery`
2. `samples.flutter.dev/camera`

其中：

### 信息类通道

通道名：

```text
samples.flutter.dev/battery
```

它下面挂了 3 个方法：

- `getBatteryLevel`
- `getDeviceModel`
- `processUserName`

### 相机类通道

通道名：

```text
samples.flutter.dev/camera
```

它下面挂了 1 个方法：

- `openCamera`

---

## 3. Dart 端做了什么

位置：[lib/main.dart](/D:/project/MethodChannel/lib/main.dart)

### 3.1 定义通道

当前 Dart 端定义了两条通道：

```dart
static const MethodChannel _channel = MethodChannel(
  'samples.flutter.dev/battery',
);

static const MethodChannel _cameraChannel = MethodChannel(
  'samples.flutter.dev/camera',
);
```

这表示：

- `_channel` 负责电量、设备型号、传参示例
- `_cameraChannel` 负责系统相机示例

如果通道名不一致，会怎样？

- Flutter 找不到原生接收方
- 常见结果是 `MissingPluginException`

---

## 4. 前 3 个示例：同步风格的原生调用

前 3 个示例的共同点是：

- Dart 调用原生方法
- 原生很快处理完
- 原生马上把结果回给 Dart

### 4.1 获取电量

```dart
await _channel.invokeMethod<int>('getBatteryLevel');
```

返回值：

- `int`

### 4.2 获取设备型号

```dart
await _channel.invokeMethod<String>('getDeviceModel');
```

返回值：

- `String`

### 4.3 Dart 传参给原生

```dart
await _channel.invokeMethod<String>(
  'processUserName',
  <String, dynamic>{
    'name': inputName,
    'from': 'dart',
  },
);
```

这个例子比前两个多了一个重点：

- Dart 不只是调用方法
- 还通过 `arguments` 把 `Map` 传给原生

---

## 5. 第 4 个示例：Dart 调用原生系统相机

这个例子是这次新增的重点。

### 5.1 Dart 端调用方式

```dart
final String? imagePath = await _cameraChannel.invokeMethod<String>(
  'openCamera',
);
```

这句代码的意思是：

- 通过 `samples.flutter.dev/camera` 这条通道
- 调用原生方法 `openCamera`
- 希望原生最终返回拍照后的图片路径

返回值：

- `String`

这个 `String` 不是图片内容本身，而是：

- 图片文件在本地磁盘上的路径

例如：

```text
/data/user/0/com.example.channel/cache/images/JPEG_20260527_123456_.jpg
```

或者：

```text
/private/var/mobile/Containers/Data/Application/.../tmp/camera_20260527_123456.jpg
```

---

## 6. 为什么相机示例单独拆成新通道

你可能会问：

“为什么相机这次不用 `samples.flutter.dev/battery`，而是新建 `samples.flutter.dev/camera`？”

这是为了让结构更清晰。

因为前 3 个示例更像“信息类能力”：

- 获取电量
- 获取设备信息
- 传参数做字符串处理

而相机是一个新的功能模块：

- 它需要打开系统界面
- 它是异步回调
- 它需要文件保存
- 它还涉及平台权限和配置

所以拆成独立通道更容易理解，也更接近真实项目结构。

---

## 7. Android 原生端做了什么

位置：[android/app/src/main/kotlin/com/example/channel/MainActivity.kt](/D:/project/MethodChannel/android/app/src/main/kotlin/com/example/channel/MainActivity.kt)

Android 端现在注册了两条通道。

### 7.1 信息类通道

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, infoChannelName)
```

负责：

- `getBatteryLevel`
- `getDeviceModel`
- `processUserName`

### 7.2 相机类通道

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cameraChannelName)
```

负责：

- `openCamera`

### 7.3 Android 打开系统相机的流程

当 Dart 调用：

```text
openCamera
```

Android 会做这些事：

1. 先创建一个临时图片文件
2. 把这个文件转换成安全的 `content://` Uri
3. 调用系统相机拍照
4. 用户拍照完成后
5. 把图片文件路径返回给 Dart

### 7.4 为什么 Android 需要 FileProvider

位置：[AndroidManifest.xml](/D:/project/MethodChannel/android/app/src/main/AndroidManifest.xml) 和 [file_paths.xml](/D:/project/MethodChannel/android/app/src/main/res/xml/file_paths.xml)

这是因为：

- Android 7.0 以后，应用之间不能直接共享普通文件路径
- 必须通过 `FileProvider` 把文件包装成更安全的 `content://` Uri

所以项目里加了：

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.fileprovider"
    ...
/>
```

以及：

```xml
<cache-path
    name="camera_images"
    path="images/" />
```

这表示：

- 允许共享缓存目录下 `images/` 里的文件

### 7.5 Android 为什么要先保存 `pendingCameraResult`

因为相机不是同步返回。

流程是：

1. Dart 调 `openCamera`
2. Android 立刻打开相机
3. 此时还没有最终结果
4. 等用户拍照完，系统回调才回来
5. Android 再把结果回传给 Dart

所以必须先把 Dart 的 `result` 暂存起来。

---

## 8. iOS 原生端做了什么

位置：[ios/Runner/AppDelegate.swift](/D:/project/MethodChannel/ios/Runner/AppDelegate.swift)

iOS 端也注册了两条通道：

1. `samples.flutter.dev/battery`
2. `samples.flutter.dev/camera`

### 8.1 iOS 打开系统相机的流程

当 Dart 调用：

```text
openCamera
```

iOS 会做这些事：

1. 检查设备是否支持相机
2. 创建 `UIImagePickerController`
3. 设置 `sourceType = .camera`
4. 弹出系统相机界面
5. 用户拍照完成
6. 在代理回调里拿到图片
7. 把图片写入临时目录
8. 把图片路径返回给 Dart

### 8.2 为什么 iOS 要实现 delegate

因为系统相机不是“函数一调用马上就返回图片”。

而是：

1. 先弹出系统界面
2. 等用户操作
3. 用户完成后系统再通知我们

所以要实现：

- `UIImagePickerControllerDelegate`
- `UINavigationControllerDelegate`

### 8.3 为什么 iOS 要加 NSCameraUsageDescription

位置：[Info.plist](/D:/project/MethodChannel/ios/Runner/Info.plist)

这里加了：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机来演示 Flutter 通过 MethodChannel 调用原生系统相机。</string>
```

这表示：

- 你必须告诉系统：为什么要用相机
- 没有这项配置，iOS 不会允许应用正常访问相机

---

## 9. 第 4 个示例的完整交互过程

这个流程建议你重点看。

### 9.1 第一步：Flutter 页面点击“打开系统相机”

用户点按钮后，Dart 进入：

```dart
_openNativeCamera()
```

### 9.2 第二步：Dart 调用相机通道

```dart
await _cameraChannel.invokeMethod<String>('openCamera');
```

这一步表示：

- 通道名：`samples.flutter.dev/camera`
- 方法名：`openCamera`
- 期望原生返回：图片路径

### 9.3 第三步：原生打开系统相机界面

Android / iOS 收到这个调用后：

- 不会立刻返回图片
- 而是先把系统相机界面打开

### 9.4 第四步：用户拍照

这一步是用户在系统相机里完成的，不是在 Flutter 页面里完成的。

### 9.5 第五步：原生拿到拍照结果

拍照完成后：

- Android 在拍照回调里拿到成功状态
- iOS 在 delegate 里拿到图片对象

### 9.6 第六步：原生保存图片文件

为什么保存文件？

因为 Dart 端最容易接收和展示的是：

- 一段图片路径字符串

而不是直接跨通道传整张图片的二进制数据。

### 9.7 第七步：原生把图片路径回传给 Dart

例如返回：

```text
/data/user/0/com.example.channel/cache/images/JPEG_20260527_123456_.jpg
```

或：

```text
/private/var/mobile/.../tmp/camera_20260527_123456.jpg
```

### 9.8 第八步：Dart 刷新页面

Dart 收到路径后：

- 更新结果文字
- 页面显示“拍照成功，原生返回的图片路径”

---

## 10. 为什么相机是“异步返回结果”

前 3 个示例更像：

```text
Dart 调一下 -> 原生立刻算一下 -> 立刻返回
```

而相机更像：

```text
Dart 调一下 -> 原生打开系统界面 -> 用户操作 -> 原生稍后再返回
```

所以相机示例和前 3 个示例有一个本质区别：

- 它不是单纯的方法计算
- 它涉及系统 UI 和用户交互

这就是为什么：

- Android 要暂存 `pendingCameraResult`
- iOS 也要暂存 `pendingCameraResult`

---

## 11. 你必须记住的 5 个“必须一致”

做 `MethodChannel` 最容易出错的地方，现在变成了 5 项：

1. 通道名必须一致
2. 方法名必须一致
3. 返回值类型要基本对应
4. 参数结构要对得上
5. 平台配置也要补齐

例如：

- Dart 用的是 `samples.flutter.dev/camera`
- Android / iOS 也必须注册同名通道

再比如：

- Dart 调用的是 `openCamera`
- 原生也必须监听 `openCamera`

---

## 12. 常见返回方式

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

在相机示例里：

- 拍照成功：返回图片路径
- 用户取消：返回错误
- 平台无相机：返回错误

---

## 13. Dart 侧为什么要写 try-catch

因为调用原生并不一定成功。

例如：

1. 你正在 Windows 上运行项目
2. 通道名写错了
3. 方法名写错了
4. 原生端主动返回错误
5. 原生没拿到参数
6. 用户取消拍照
7. 设备没有相机

所以 Dart 端写了：

- `MissingPluginException`
- `PlatformException`
- `catch`

这样即使调用失败，页面也不会直接崩掉，而是把错误信息显示给你看。

---

## 14. 如何运行这个示例

### 在 Android 真机或模拟器运行

```bash
flutter run
```

你现在可以测试 4 个功能：

1. 点击“获取原生电量”
2. 点击“获取设备型号”
3. 输入名字后点击“把名字传给原生”
4. 点击“打开系统相机”

### 在 iPhone 真机运行

同样使用：

```bash
flutter run
```

前提是你在 macOS 上用 Xcode 环境运行 iOS。

注意：

- iOS 模拟器通常不适合测试真正的相机拍照
- 真机体验更接近真实结果

### 在 Windows / Web / macOS / Linux 上运行

页面仍然能打开，但原生方法通常不会真的执行，因为没有对应的 Android / iOS 原生层。

这是正常现象。

---

## 15. 为什么这里有时用一条通道，有时拆成两条通道

这个项目故意同时演示了两种组织方式。

### 第一种：一条通道挂多个方法

例如：

- `samples.flutter.dev/battery`

下面挂：

- `getBatteryLevel`
- `getDeviceModel`
- `processUserName`

适合：

- 功能相近
- 数量不多
- 结构还比较清晰

### 第二种：拆成独立通道

例如：

- `samples.flutter.dev/camera`

下面挂：

- `openCamera`

适合：

- 功能已经变成独立模块
- 需要单独管理
- 原生逻辑明显更复杂

---

## 16. 下一步你可以练什么

学完这 4 个示例后，建议你自己动手改成下面这些练习：

1. 拍照完成后，在 Dart 页面直接显示图片
2. 让相机方法支持参数，比如是否使用前置摄像头
3. 让原生返回一个 `Map`，里面包含路径、宽高、时间
4. 增加第五个方法，比如打开系统相册
5. 把相机模块继续拆成独立的 Dart service 类

---

## 17. 一句话总结

`MethodChannel` 的本质就是：

Flutter 用“通道名 + 方法名 + 参数”去调用原生代码，原生读取参数、执行逻辑、必要时打开系统界面，最后再把结果回传给 Flutter。
