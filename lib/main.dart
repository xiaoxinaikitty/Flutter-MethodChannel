import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
/// 这个页面现在包含两个原生调用例子：
/// 1. 获取手机电量
/// 2. 获取设备型号
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

  /// 第一块结果区域：显示电量调用结果。
  String _batteryText = '点击按钮后，这里会显示原生返回的手机电量';

  /// 第二块结果区域：显示设备型号调用结果。
  String _deviceModelText = '点击按钮后，这里会显示原生返回的设备型号';

  /// 两个按钮各自独立控制加载状态。
  ///
  /// 这样当你请求“设备型号”时，不会把“获取电量”按钮也一起禁用。
  bool _isBatteryLoading = false;
  bool _isDeviceModelLoading = false;

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
    required void Function() onStart,
    required void Function(T? result) onSuccess,
    required void Function(String message) onError,
    required void Function() onFinish,
  }) async {
    onStart();

    try {
      final T? result = await _channel.invokeMethod<T>(methodName);
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

  /// 根据当前平台显示提示文字。
  String _platformHint() {
    if (kIsWeb) {
      return '当前运行平台：Web。'
          '\nWeb 没有 Android/iOS 这一层原生代码，所以这里主要用于学习 Dart 写法。';
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return '当前运行平台：Android。'
          '\n本项目已实现两个原生方法：获取电量、获取设备型号。';
    }
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return '当前运行平台：iOS。'
          '\n本项目已实现两个原生方法：获取电量、获取设备型号。';
    }
    return '当前运行平台不是 Android/iOS。'
        '\n页面可以正常打开，但调用原生方法时通常会提示未实现。';
  }

  /// 把重复的“结果卡片”抽成一个小组件方法，页面结构更清晰。
  Widget _buildResultCard({
    required BuildContext context,
    required String title,
    required String content,
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
                '这个页面演示 Flutter 如何通过同一条 MethodChannel 调用多个原生方法，'
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
              Text(
                '你现在可以重点观察四件事：',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              const Text('1. Dart 端只创建了一条通道：samples.flutter.dev/battery'),
              const Text('2. 第一种调用的方法名：getBatteryLevel'),
              const Text('3. 第二种调用的方法名：getDeviceModel'),
              const Text('4. 原生端如何根据不同方法名返回不同数据'),
            ],
          ),
        ),
      ),
    );
  }
}
