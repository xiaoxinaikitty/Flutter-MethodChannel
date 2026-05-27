import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'local_file_preview_stub.dart'
    if (dart.library.io) 'local_file_preview_io.dart';

void main() {
  runApp(const MyApp());
}

/// 应用入口组件。
///
/// 你可以先把 Flutter 应用理解成一棵组件树：
/// `main()` -> `runApp()` -> `MyApp()` -> 首页组件
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MethodChannel Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const MethodChannelHomePage(),
    );
  }
}

/// 这是 MethodChannel 的演示首页。
///
/// 这个页面现在包含 4 个原生调用例子：
/// 1. 获取手机电量
/// 2. 获取设备型号
/// 3. Dart 把参数传给原生，原生处理后再返回结果
/// 4. Dart 调用原生系统相机
///
/// 之所以使用 `StatefulWidget`，是因为页面上的文字会随着调用结果变化。
class MethodChannelHomePage extends StatefulWidget {
  const MethodChannelHomePage({super.key});

  @override
  State<MethodChannelHomePage> createState() => _MethodChannelHomePageState();
}

class _MethodChannelHomePageState extends State<MethodChannelHomePage> {
  /// 这是一条“通信通道”。
  ///
  /// Dart 和原生都必须使用完全相同的通道名。
  /// 你可以把它理解成 Flutter 拨给原生的固定号码。
  static const MethodChannel _channel = MethodChannel(
    'samples.flutter.dev/battery',
  );

  /// 这是新的“相机通道”。
  ///
  /// 为什么这次不继续复用 `battery` 通道？
  /// 因为相机已经是一个新的功能模块了，单独拆成一条通道更容易理解：
  /// - `samples.flutter.dev/battery` 负责信息类示例
  /// - `samples.flutter.dev/camera` 负责相机类示例
  static const MethodChannel _cameraChannel = MethodChannel(
    'samples.flutter.dev/camera',
  );

  /// 第一块结果区域：显示电量调用结果。
  String _batteryText = '点击按钮后，这里会显示原生返回的手机电量';

  /// 第二块结果区域：显示设备型号调用结果。
  String _deviceModelText = '点击按钮后，这里会显示原生返回的设备型号';

  /// 第三块结果区域：显示“Dart 传参给原生”后的返回结果。
  String _nativeMessageText = '先在输入框里输入名字，再点击按钮把参数传给原生';

  /// 第四块结果区域：显示系统相机调用结果。
  String _cameraText = '点击按钮后，Dart 会调用原生系统相机，拍照完成后直接在页面显示图片';

  /// 这是拍照成功后保存下来的本地图片路径。
  ///
  /// 页面不再直接展示这段路径文字，
  /// 但仍然会把它保存在状态里，供图片预览组件读取。
  String? _cameraImagePath;

  /// 这是输入框控制器。
  ///
  /// `TextEditingController` 的作用是：
  /// 1. 读取输入框当前内容
  /// 2. 需要时修改输入框内容
  /// 3. 在 Dart 里拿到用户输入，再传给原生
  final TextEditingController _nameController = TextEditingController(
    text: 'Flutter 初学者',
  );

  /// 两个按钮各自独立控制加载状态。
  ///
  /// 这样当你请求“设备型号”时，不会把“获取电量”按钮也一起禁用。
  bool _isBatteryLoading = false;
  bool _isDeviceModelLoading = false;
  bool _isNativeMessageLoading = false;
  bool _isCameraLoading = false;

  @override
  void dispose() {
    /// `TextEditingController` 属于需要手动释放的对象。
    ///
    /// 页面销毁时调用 `dispose()`，是 Flutter 很常见的资源清理写法。
    _nameController.dispose();
    super.dispose();
  }

  /// 这是一个通用的原生调用辅助方法。
  ///
  /// 为什么要单独封装？
  /// 因为“获取电量”和“获取设备型号”的流程高度相似：
  /// 1. 设置加载状态
  /// 2. 调用原生方法
  /// 3. 成功后刷新结果
  /// 4. 失败后显示错误
  /// 5. 最后关闭加载状态
  ///
  /// 把公共流程抽出来后，页面代码会更容易阅读。
  Future<void> _invokePlatformMethod<T>({
    required String methodName,
    Object? arguments,
    required void Function() onStart,
    required void Function(T? result) onSuccess,
    required void Function(String message) onError,
    required void Function() onFinish,
  }) async {
    onStart();

    try {
      /// `arguments` 就是 Dart 传给原生的参数。
      ///
      /// 如果这个方法不需要参数，就保持 `null`。
      /// 如果这个方法需要参数，就可以传：
      /// - `String`
      /// - `int`
      /// - `bool`
      /// - `Map`
      /// - `List`
      final T? result = await _channel.invokeMethod<T>(methodName, arguments);
      onSuccess(result);
    } on MissingPluginException {
      onError(
        '当前平台没有实现 `$methodName`。'
        '\n如果你是在 Windows / Web 上运行，这是正常的，因为示例只实现了 Android/iOS。',
      );
    } on PlatformException catch (error) {
      onError(
        '调用原生失败：${error.code}'
        '\n错误信息：${error.message ?? '无详细信息'}',
      );
    } catch (error) {
      onError('发生未预期错误：$error');
    } finally {
      onFinish();
    }
  }

  /// 示例 1：获取原生手机电量。
  ///
  /// 这里调用的是原生方法名：`getBatteryLevel`
  Future<void> _getBatteryLevel() async {
    await _invokePlatformMethod<int>(
      methodName: 'getBatteryLevel',
      onStart: () {
        setState(() {
          _isBatteryLoading = true;
          _batteryText = '正在向原生平台请求电量...';
        });
      },
      onSuccess: (batteryLevel) {
        setState(() {
          if (batteryLevel == null) {
            _batteryText = '原生返回了空数据，请检查返回值';
          } else {
            _batteryText = '当前电量：$batteryLevel%';
          }
        });
      },
      onError: (message) {
        setState(() {
          _batteryText = message;
        });
      },
      onFinish: () {
        setState(() {
          _isBatteryLoading = false;
        });
      },
    );
  }

  /// 示例 2：获取原生设备型号。
  ///
  /// 这里调用的是另一个原生方法名：`getDeviceModel`
  ///
  /// 这正是 MethodChannel 很重要的一点：
  /// 同一条通道里，可以放多个不同的方法。
  Future<void> _getDeviceModel() async {
    await _invokePlatformMethod<String>(
      methodName: 'getDeviceModel',
      onStart: () {
        setState(() {
          _isDeviceModelLoading = true;
          _deviceModelText = '正在向原生平台请求设备型号...';
        });
      },
      onSuccess: (deviceModel) {
        setState(() {
          if (deviceModel == null || deviceModel.trim().isEmpty) {
            _deviceModelText = '原生返回了空字符串，请检查返回值';
          } else {
            _deviceModelText = '当前设备型号：$deviceModel';
          }
        });
      },
      onError: (message) {
        setState(() {
          _deviceModelText = message;
        });
      },
      onFinish: () {
        setState(() {
          _isDeviceModelLoading = false;
        });
      },
    );
  }

  /// 示例 3：Dart 传一个参数给原生，原生处理后再返回结果。
  ///
  /// 这个例子是学习 MethodChannel 的关键一步，因为它比“单纯调用原生”
  /// 多了一层“参数传递”。
  ///
  /// 这次的流程是：
  /// 1. 先从输入框取出用户输入的名字
  /// 2. 把名字放进一个 `Map`
  /// 3. Dart 调用原生方法 `processUserName`
  /// 4. Android / iOS 从参数里取出 `name`
  /// 5. 原生做一点字符串处理
  /// 6. 原生把处理后的结果返回给 Dart
  Future<void> _sendNameToNative() async {
    /// 先读取输入框内容。
    final String inputName = _nameController.text.trim();

    /// 如果输入为空，就不继续调用原生。
    if (inputName.isEmpty) {
      setState(() {
        _nativeMessageText = '请先输入一个名字，再点击“把名字传给原生”';
      });
      return;
    }

    await _invokePlatformMethod<String>(
      /// 这是第三个原生方法名。
      methodName: 'processUserName',

      /// 这里就是 Dart 传给原生的参数。
      ///
      /// 这次我们传的是一个 `Map<String, dynamic>`。
      /// 其中：
      /// - `name` 是用户输入的名字
      /// - `from` 用来告诉原生：这次请求来自 Dart
      arguments: <String, dynamic>{
        'name': inputName,
        'from': 'dart',
      },
      onStart: () {
        setState(() {
          _isNativeMessageLoading = true;
          _nativeMessageText = '正在把参数传给原生，并等待原生处理结果...';
        });
      },
      onSuccess: (nativeMessage) {
        setState(() {
          if (nativeMessage == null || nativeMessage.trim().isEmpty) {
            _nativeMessageText = '原生返回了空字符串，请检查参数处理逻辑';
          } else {
            _nativeMessageText = nativeMessage;
          }
        });
      },
      onError: (message) {
        setState(() {
          _nativeMessageText = message;
        });
      },
      onFinish: () {
        setState(() {
          _isNativeMessageLoading = false;
        });
      },
    );
  }

  /// 示例 4：Dart 调用原生系统相机。
  ///
  /// 这个例子和前面三个例子最大的不同是：
  /// 前面三个例子基本都是“调用后很快返回”
  /// 而相机是“先打开系统界面，等用户拍照完成后，原生再异步返回结果”
  ///
  /// 执行流程：
  /// 1. Dart 点击按钮
  /// 2. Dart 调用 `samples.flutter.dev/camera` 通道上的 `openCamera`
  /// 3. Android / iOS 原生打开系统相机
  /// 4. 用户拍照
  /// 5. 原生把图片路径返回给 Dart
  Future<void> _openNativeCamera() async {
    setState(() {
      _isCameraLoading = true;
      _cameraText = '正在请求原生系统相机...';
    });

    try {
      /// 这里返回的是拍照后图片的本地路径。
      final String? imagePath = await _cameraChannel.invokeMethod<String>(
        'openCamera',
      );

      setState(() {
        if (imagePath == null || imagePath.trim().isEmpty) {
          _cameraImagePath = null;
          _cameraText = '原生相机返回了空路径，请检查原生保存逻辑';
        } else {
          _cameraImagePath = imagePath;
          _cameraText = '拍照成功，下面就是原生系统相机返回的图片';
        }
      });
    } on MissingPluginException {
      setState(() {
        _cameraImagePath = null;
        _cameraText = '当前平台没有实现相机通道。'
            '\n如果你是在 Windows / Web 上运行，这是正常的。';
      });
    } on PlatformException catch (error) {
      setState(() {
        _cameraImagePath = null;
        _cameraText = '调用系统相机失败：${error.code}'
            '\n错误信息：${error.message ?? '无详细信息'}';
      });
    } catch (error) {
      setState(() {
        _cameraImagePath = null;
        _cameraText = '发生未预期错误：$error';
      });
    } finally {
      setState(() {
        _isCameraLoading = false;
      });
    }
  }

  /// 清空当前拍照结果。
  ///
  /// 这个操作只清 Flutter 页面上的状态，不会回头删除原生缓存文件。
  /// 对当前教学示例来说，这样更简单，也更容易理解。
  void _clearCameraImage() {
    setState(() {
      _cameraImagePath = null;
      _cameraText = '图片已清空。你可以点击“重新拍照”或“打开系统相机”继续测试。';
    });
  }

  /// 点击预览图后，弹出一个放大查看的对话框。
  ///
  /// 这样你就能看到：
  /// 1. 页面上的缩略图
  /// 2. 点击后查看大图
  void _showCameraPreviewDialog() {
    final imagePath = _cameraImagePath;

    if (imagePath == null || imagePath.isEmpty) {
      return;
    }

    showDialog<void>(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  '拍照预览',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: buildLocalFilePreview(
                      imagePath,
                      height: 420,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('关闭'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// 根据当前平台显示提示文字。
  String _platformHint() {
    if (kIsWeb) {
      return '当前运行平台：Web。'
          '\nWeb 没有 Android/iOS 这一层原生代码，所以这里主要用于学习 Dart 写法。';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '当前运行平台：Android。'
          '\n本项目已实现 4 个原生示例：获取电量、获取设备型号、Dart 传参、调用系统相机。';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return '当前运行平台：iOS。'
          '\n本项目已实现 4 个原生示例：获取电量、获取设备型号、Dart 传参、调用系统相机。';
    }
    return '当前运行平台不是 Android/iOS。'
        '\n页面可以正常打开，但调用原生方法时通常会提示未实现。';
  }

  /// 把重复的“结果卡片”抽成一个小组件方法，页面结构更清晰。
  Widget _buildResultCard({
    required BuildContext context,
    required String title,
    required String content,
    Widget? extra,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            content,
            style: theme.textTheme.bodyLarge,
          ),
        ),
        if (extra != null) ...[
          const SizedBox(height: 12),
          extra,
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('MethodChannel 入门示例'),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '学习目标',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              const Text(
                '这个页面演示 Flutter 如何通过 MethodChannel 调用多个原生能力，'
                '并让 Android / iOS 把结果返回给 Dart 层。',
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_platformHint()),
                ),
              ),
              const SizedBox(height: 24),
              _buildResultCard(
                context: context,
                title: '示例 1：获取原生手机电量',
                content: _batteryText,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isBatteryLoading ? null : _getBatteryLevel,
                  icon: _isBatteryLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.battery_charging_full),
                  label: Text(_isBatteryLoading ? '请求中...' : '获取原生电量'),
                ),
              ),
              const SizedBox(height: 28),
              _buildResultCard(
                context: context,
                title: '示例 2：获取原生设备型号',
                content: _deviceModelText,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isDeviceModelLoading ? null : _getDeviceModel,
                  icon: _isDeviceModelLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.phone_android),
                  label: Text(_isDeviceModelLoading ? '请求中...' : '获取设备型号'),
                ),
              ),
              const SizedBox(height: 28),
              _buildResultCard(
                context: context,
                title: '示例 3：Dart 传参数给原生，原生处理后返回结果',
                content: _nativeMessageText,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: '输入一个名字',
                  hintText: '例如：小明',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isNativeMessageLoading ? null : _sendNameToNative,
                  icon: _isNativeMessageLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(
                    _isNativeMessageLoading ? '请求中...' : '把名字传给原生',
                  ),
                ),
              ),
              const SizedBox(height: 28),
              _buildResultCard(
                context: context,
                title: '示例 4：Dart 调用原生系统相机',
                content: _cameraText,
                extra: _cameraImagePath == null
                    ? null
                    : GestureDetector(
                        onTap: _showCameraPreviewDialog,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            buildLocalFilePreview(_cameraImagePath!),
                            const SizedBox(height: 8),
                            Text(
                              '点击图片可放大查看',
                              style: theme.textTheme.bodySmall,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isCameraLoading ? null : _openNativeCamera,
                  icon: _isCameraLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  label: Text(_isCameraLoading ? '请求中...' : '打开系统相机'),
                ),
              ),
              if (_cameraImagePath != null) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCameraLoading ? null : _openNativeCamera,
                        icon: const Icon(Icons.camera),
                        label: const Text('重新拍照'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isCameraLoading ? null : _clearCameraImage,
                        icon: const Icon(Icons.delete_outline),
                        label: const Text('清空照片'),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 28),
              Text(
                '你现在可以重点观察八件事：',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('1. 信息类示例使用的通道：samples.flutter.dev/battery'),
              const Text('2. 相机示例使用的通道：samples.flutter.dev/camera'),
              const Text('3. 第一种调用的方法名：getBatteryLevel'),
              const Text('4. 第二种调用的方法名：getDeviceModel'),
              const Text('5. 第三种调用的方法名：processUserName'),
              const Text('6. 第四种调用的方法名：openCamera'),
              const Text('7. Dart 如何通过 arguments 把 Map 传给原生'),
              const Text('8. 相机为什么属于“异步返回结果”的原生调用'),
            ],
          ),
        ),
      ),
    );
  }
}
