# MethodChannel 学习笔记

这个项目现在已经包含 4 个最小可运行的 `MethodChannel` 示例：

1. 获取原生手机电量
2. 获取原生设备型号
3. Dart 传参数给原生，原生处理后再返回结果
4. Dart 调用原生媒体能力：
   - 打开系统相机拍照
   - 打开系统相册选择图片

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

### 媒体类通道

通道名：

```text
samples.flutter.dev/camera
```

它下面挂了 2 个方法：

- `openCamera`
- `pickImageFromGallery`

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
- `_cameraChannel` 负责媒体类示例

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

## 5. 第 4 个示例：Dart 调用原生媒体能力

这个示例现在已经不是“只打开系统相机”，而是升级成了统一上传入口：

1. Flutter 先弹出底部菜单
2. 用户选择：
   - 拍照
   - 从相册选择
3. Dart 再调用对应原生方法

### 5.1 为什么推荐这种方案

因为我不建议你依赖：

- “系统相机界面里刚好有相册入口”

原因是不同平台、不同厂商差异太大，Flutter 无法稳定控制。

更推荐的做法是：

1. Flutter 先自己让用户做选择
2. 再分别调用：
   - `openCamera`
   - `pickImageFromGallery`

这样更稳定，也更容易理解。

### 5.2 Dart 端统一入口

当前页面里的主按钮会先弹出底部菜单：

- 拍照
- 从相册选择
- 取消

这一步对应的方法是：

```dart
_showImageSourceActionSheet()
```

### 5.3 Dart 调用系统相机

```dart
await _cameraChannel.invokeMethod<String>('openCamera');
```

这表示：

- 通道名：`samples.flutter.dev/camera`
- 方法名：`openCamera`
- 原生最终返回：图片路径

### 5.4 Dart 调用系统相册

```dart
await _cameraChannel.invokeMethod<String>('pickImageFromGallery');
```

这表示：

- 通道名：`samples.flutter.dev/camera`
- 方法名：`pickImageFromGallery`
- 原生最终返回：图片路径

### 5.5 为什么两条路径都统一返回图片路径

因为 Dart 页面当前最容易统一处理的是：

- 本地图片路径

这样不管图片来自：

- 相机
- 相册

Flutter 页面都能用同一套预览逻辑去显示。

---

## 6. Android 原生端做了什么

位置：[android/app/src/main/kotlin/com/example/channel/MainActivity.kt](/D:/project/MethodChannel/android/app/src/main/kotlin/com/example/channel/MainActivity.kt)

Android 端现在注册了两条通道。

### 6.1 信息类通道

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, infoChannelName)
```

负责：

- `getBatteryLevel`
- `getDeviceModel`
- `processUserName`

### 6.2 媒体类通道

```kotlin
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, cameraChannelName)
```

负责：

- `openCamera`
- `pickImageFromGallery`

### 6.3 Android 打开系统相机的流程

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

### 6.4 Android 打开系统相册的流程

当 Dart 调用：

```text
pickImageFromGallery
```

Android 会做这些事：

1. 创建系统图片选择 Intent
2. 打开系统相册 / 文件选择器
3. 用户选中一张图片
4. 系统返回一个 `Uri`
5. Android 把这个 `Uri` 对应的内容复制到应用缓存目录
6. 返回新文件路径给 Dart

### 6.5 为什么 Android 相册返回后还要复制文件

因为系统相册返回给你的往往不是普通文件路径，而是：

```text
content://...
```

这种 Uri 对 Dart 页面当前的本地文件预览并不够直接。

所以 Android 做了一步转换：

1. 读取 `content://` Uri 的输入流
2. 复制到应用缓存目录
3. 返回缓存文件路径

这样 Dart 页面就能继续统一显示：

- 拍照得到的图片
- 相册选中的图片

### 6.6 为什么 Android 需要 FileProvider

位置：[AndroidManifest.xml](/D:/project/MethodChannel/android/app/src/main/AndroidManifest.xml) 和 [file_paths.xml](/D:/project/MethodChannel/android/app/src/main/res/xml/file_paths.xml)

这是因为：

- Android 7.0 以后，应用之间不能直接共享普通文件路径
- 必须通过 `FileProvider` 把文件包装成更安全的 `content://` Uri

这主要是为“拍照写入文件”这条路径服务的。

---

## 7. iOS 原生端做了什么

位置：[ios/Runner/AppDelegate.swift](/D:/project/MethodChannel/ios/Runner/AppDelegate.swift)

iOS 端也注册了两条通道：

1. `samples.flutter.dev/battery`
2. `samples.flutter.dev/camera`

### 7.1 iOS 打开系统相机的流程

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

### 7.2 iOS 打开系统相册的流程

当 Dart 调用：

```text
pickImageFromGallery
```

iOS 会做两层兼容：

#### iOS 14 及以上

优先使用：

- `PHPickerViewController`

这是更现代的系统相册选择器。

#### iOS 12 / 13

自动回退到：

- `UIImagePickerController`
- `sourceType = .photoLibrary`

这意味着：

- 你的项目最低支持版本虽然是 iOS 12
- 但高版本系统会优先走更现代的方案

### 7.3 为什么 iOS 相册返回后也要存成文件

原因和 Android 一样：

- Dart 页面当前统一按“本地文件路径”显示图片

所以无论图片来自：

- 相机
- 相册

iOS 最终都会：

1. 得到图片对象
2. 转成 JPEG 数据
3. 写入临时目录
4. 返回图片路径给 Dart

### 7.4 为什么 iOS 要加权限说明

位置：[Info.plist](/D:/project/MethodChannel/ios/Runner/Info.plist)

这里现在有两项：

```xml
<key>NSCameraUsageDescription</key>
<string>需要使用相机来演示 Flutter 通过 MethodChannel 调用原生系统相机。</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>需要访问系统相册来演示 Flutter 通过 MethodChannel 选择图片。</string>
```

这表示：

- 用相机前要告诉系统原因
- 读相册前也要告诉系统原因

---

## 8. 第 4 个示例的完整交互过程

这个流程建议你重点看。

### 8.1 第一步：Flutter 页面点击“选择图片来源”

用户点按钮后，Dart 进入：

```dart
_showImageSourceActionSheet()
```

### 8.2 第二步：Flutter 弹出底部菜单

菜单选项有：

- 拍照
- 从相册选择
- 取消

### 8.3 第三步：用户做选择

如果用户选：

- `拍照`

那么 Dart 会调用：

```dart
openCamera
```

如果用户选：

- `从相册选择`

那么 Dart 会调用：

```dart
pickImageFromGallery
```

### 8.4 第四步：原生打开系统界面

此时原生会根据方法名决定：

- 打开系统相机
- 或打开系统相册

### 8.5 第五步：用户完成操作

可能发生三种情况：

1. 成功拍照
2. 成功选图
3. 取消操作

### 8.6 第六步：原生把图片转换成统一结果

为了让 Dart 页面更容易处理，原生会统一返回：

- 本地图片路径

### 8.7 第七步：Dart 收到路径并刷新页面

最后 Flutter 会：

1. 保存图片路径到状态
2. 更新结果文字
3. 页面显示缩略图
4. 支持点击放大查看

---

## 9. 为什么媒体类操作属于“异步返回结果”

前 3 个示例更像：

```text
Dart 调一下 -> 原生立刻算一下 -> 立刻返回
```

而媒体类操作更像：

```text
Dart 调一下 -> 原生打开系统界面 -> 用户操作 -> 原生稍后再返回
```

这就是为什么：

- Android 要暂存 `pendingCameraResult`
- iOS 也要暂存对应的待返回结果

---

## 10. 你必须记住的 5 个“必须一致”

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

- Dart 调用的是 `pickImageFromGallery`
- 原生也必须监听 `pickImageFromGallery`

---

## 11. 常见返回方式

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

在媒体类示例里：

- 拍照成功：返回图片路径
- 选图成功：返回图片路径
- 用户取消：返回错误
- 平台不可用：返回错误

---

## 12. Dart 侧为什么要写 try-catch

因为调用原生并不一定成功。

例如：

1. 你正在 Windows 上运行项目
2. 通道名写错了
3. 方法名写错了
4. 原生端主动返回错误
5. 原生没拿到参数
6. 用户取消拍照
7. 用户取消选图
8. 设备没有相机
9. 设备没有可用相册选择器

所以 Dart 端写了：

- `MissingPluginException`
- `PlatformException`
- `catch`

这样即使调用失败，页面也不会直接崩掉，而是把错误信息显示给你看。

---

## 13. 如何运行这个示例

### 在 Android 真机或模拟器运行

```bash
flutter run
```

你现在可以测试 4 个功能：

1. 点击“获取原生电量”
2. 点击“获取设备型号”
3. 输入名字后点击“把名字传给原生”
4. 点击“选择图片来源”，再选：
   - 拍照
   - 从相册选择

### 在 iPhone 真机运行

同样使用：

```bash
flutter run
```

前提是你在 macOS 上用 Xcode 环境运行 iOS。

注意：

- iOS 模拟器通常不适合测试真正的相机拍照
- 但相册选择一般更容易测试

### 在 Windows / Web / macOS / Linux 上运行

页面仍然能打开，但原生方法通常不会真的执行，因为没有对应的 Android / iOS 原生层。

这是正常现象。

---

## 14. 为什么这里有时用一条通道，有时拆成两条通道

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
- `pickImageFromGallery`

适合：

- 功能已经变成独立模块
- 需要单独管理
- 原生逻辑明显更复杂

---

## 15. 下一步你可以练什么

学完这 4 个示例后，建议你自己动手改成下面这些练习：

1. 让相机方法支持参数，比如是否使用前置摄像头
2. 让原生返回一个 `Map`，里面包含路径、宽高、时间
3. 支持多图选择
4. 增加第五个方法，比如录像
5. 把媒体模块继续拆成独立的 Dart service 类

---

## 16. 一句话总结

`MethodChannel` 的本质就是：

Flutter 用“通道名 + 方法名 + 参数”去调用原生代码，原生读取参数、执行逻辑、必要时打开系统界面，最后再把结果回传给 Flutter。
