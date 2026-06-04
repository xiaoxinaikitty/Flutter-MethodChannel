import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'local_file_preview_stub.dart'
    if (dart.library.io) 'local_file_preview_io.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

/// 统一管理页面路由名。
///
/// 这样做的好处是：页面跳转时不需要在多个地方手写字符串，
/// 后续如果要改路径，只需要改这里。
class AppRoutes {
  static const home = '/';
  static const battery = '/battery';
  static const deviceModel = '/device-model';
  static const nativeMessage = '/native-message';
  static const media = '/media';
  static const i18n = '/i18n';
  static const theme = '/theme';
}

/// 统一管理 Flutter 与原生通信使用的 MethodChannel。
///
/// info 通道负责信息类能力：
/// - 电量
/// - 设备型号
/// - Dart 传参给原生
///
/// media 通道负责媒体类能力：
/// - 系统相机
/// - 系统相册
class PlatformChannels {
  static const MethodChannel info = MethodChannel(
    'samples.flutter.dev/battery',
  );

  static const MethodChannel media = MethodChannel(
    'samples.flutter.dev/camera',
  );
}

/// App 根组件。
///
/// 这里使用 StatefulWidget，是因为当前 App 有两个全局可变状态：
/// - 当前语言 Locale
/// - 当前主题 ThemeMode / seedColor
///
/// 这些状态需要挂在 MaterialApp 上，才能影响整个应用。
class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialLocale});

  final Locale? initialLocale;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  /// 当前手动选择的语言。
  ///
  /// null 表示不强制指定语言，让 App 跟随系统语言。
  Locale? _locale;

  /// 当前主题模式。
  ///
  /// system：跟随系统
  /// light：强制浅色
  /// dark：强制深色
  ThemeMode _themeMode = ThemeMode.system;

  /// 当前主题种子色。
  ///
  /// Material 3 会根据这个颜色自动生成完整 ColorScheme。
  Color _seedColor = AppTheme.defaultSeedColor;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
  }

  void _setLocale(Locale? locale) {
    setState(() {
      _locale = locale;
    });
  }

  void _setThemeMode(ThemeMode themeMode) {
    setState(() {
      _themeMode = themeMode;
    });
  }

  void _setSeedColor(Color seedColor) {
    setState(() {
      _seedColor = seedColor;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      /// onGenerateTitle 可以拿到 BuildContext，
      /// 所以这里能读取当前语言下的 App 标题。
      onGenerateTitle: (context) => context.l10n.text('appTitle'),
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationDelegates,

      /// theme / darkTheme / themeMode 共同完成多主题切换。
      ///
      /// 修改 _seedColor 会重新生成浅色和深色主题；
      /// 修改 _themeMode 会决定当前使用哪套主题。
      theme: AppTheme.light(_seedColor),
      darkTheme: AppTheme.dark(_seedColor),
      themeMode: _themeMode,

      /// routes 是“目录首页 -> 具体示例页”的跳转表。
      ///
      /// 语言页面和主题页面需要修改 MyApp 的全局状态，
      /// 所以这里把对应的 setter 作为回调传进去。
      routes: {
        AppRoutes.home: (context) => const HomeDirectoryPage(),
        AppRoutes.battery: (context) => const BatteryPage(),
        AppRoutes.deviceModel: (context) => const DeviceModelPage(),
        AppRoutes.nativeMessage: (context) => const NativeMessagePage(),
        AppRoutes.media: (context) => const MediaPage(),
        AppRoutes.i18n: (context) => I18nExamplePage(
              currentLocale: _locale,
              onLocaleChanged: _setLocale,
            ),
        AppRoutes.theme: (context) => ThemeSettingsPage(
              themeMode: _themeMode,
              seedColor: _seedColor,
              onThemeModeChanged: _setThemeMode,
              onSeedColorChanged: _setSeedColor,
            ),
      },
    );
  }
}

/// 首页目录中的一个功能入口配置。
///
/// titleKey / descriptionKey 使用国际化 key，
/// 所以首页目录可以跟随语言切换。
class FeatureEntry {
  const FeatureEntry({
    required this.titleKey,
    required this.descriptionKey,
    required this.routeName,
    required this.icon,
    required this.color,
  });

  final String titleKey;
  final String descriptionKey;
  final String routeName;
  final IconData icon;
  final Color color;
}

/// 目录式首页。
///
/// 首页不再直接堆叠所有 MethodChannel 示例，
/// 而是把功能拆成按钮入口，点击后进入对应页面。
class HomeDirectoryPage extends StatelessWidget {
  const HomeDirectoryPage({super.key});

  static const _features = [
    FeatureEntry(
      titleKey: 'batteryTitle',
      descriptionKey: 'batteryDescription',
      routeName: AppRoutes.battery,
      icon: Icons.battery_charging_full,
      color: Color(0xFF0F766E),
    ),
    FeatureEntry(
      titleKey: 'deviceTitle',
      descriptionKey: 'deviceDescription',
      routeName: AppRoutes.deviceModel,
      icon: Icons.phone_android,
      color: Color(0xFF2563EB),
    ),
    FeatureEntry(
      titleKey: 'nativeMessageTitle',
      descriptionKey: 'nativeMessageDescription',
      routeName: AppRoutes.nativeMessage,
      icon: Icons.sync_alt,
      color: Color(0xFFC2410C),
    ),
    FeatureEntry(
      titleKey: 'mediaTitle',
      descriptionKey: 'mediaDescription',
      routeName: AppRoutes.media,
      icon: Icons.add_photo_alternate,
      color: Color(0xFF7C3AED),
    ),
    FeatureEntry(
      titleKey: 'i18nTitle',
      descriptionKey: 'i18nDescription',
      routeName: AppRoutes.i18n,
      icon: Icons.translate,
      color: Color(0xFFBE123C),
    ),
    FeatureEntry(
      titleKey: 'themeTitle',
      descriptionKey: 'themeDescription',
      routeName: AppRoutes.theme,
      icon: Icons.palette,
      color: Color(0xFFC2410C),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.text('homeTitle')),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.text('homeTitle'),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.text('homeSubtitle'),
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              _PlatformHintCard(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  /// 宽屏使用双列，窄屏使用单列。
                  ///
                  /// mainAxisExtent 使用固定高度，是为了避免中文标题/描述在窄屏下
                  /// 因 GridView 自动计算高度过小而产生 RenderFlex overflow。
                  final isWide = constraints.maxWidth >= 720;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _features.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: isWide ? 128 : 124,
                    ),
                    itemBuilder: (context, index) {
                      return _FeatureButton(entry: _features[index]);
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页上的单个功能按钮。
///
/// 它负责展示图标、标题、说明和右侧箭头，
/// 点击后通过 routeName 跳到具体示例页面。
class _FeatureButton extends StatelessWidget {
  const _FeatureButton({required this.entry});

  final FeatureEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = context.l10n.text(entry.titleKey);
    final description = context.l10n.text(entry.descriptionKey);

    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pushNamed(entry.routeName),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: entry.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(entry.icon, color: entry.color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 首页平台提示卡片。
///
/// 因为 MethodChannel 的原生实现只写了 Android / iOS，
/// 所以这里会根据当前平台展示学习提示。
class _PlatformHintCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.text('platformTitle'),
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(_platformHint(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 根据当前运行平台返回对应说明文案。
String _platformHint(BuildContext context) {
  if (kIsWeb) {
    return context.l10n.text('platformWeb');
  }
  if (defaultTargetPlatform == TargetPlatform.android) {
    return context.l10n.text('platformAndroid');
  }
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    return context.l10n.text('platformIOS');
  }
  return context.l10n.text('platformOther');
}

/// 把 MethodChannel 常见异常转换成用户可读的本地化文案。
///
/// Dart 调用原生时常见错误：
/// - MissingPluginException：当前平台没有实现这个方法
/// - PlatformException：原生主动返回错误
/// - 其他异常：兜底展示
String _formatNativeError(
  BuildContext context,
  String methodName,
  Object error,
) {
  if (error is MissingPluginException) {
    return context.l10n.format('missingPlugin', {'method': methodName});
  }
  if (error is PlatformException) {
    return context.l10n.format('platformError', {
      'code': error.code,
      'message': error.message ?? '无详细信息',
    });
  }
  return context.l10n.format('unexpectedError', {'error': error});
}

/// 示例页通用外壳。
///
/// 每个功能页都有相同结构：
/// - AppBar
/// - 标题
/// - 简介
/// - 具体内容
///
/// 抽成组件后，每个页面只需要关注自己的业务逻辑。
class DemoPageScaffold extends StatelessWidget {
  const DemoPageScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  final String title;
  final String subtitle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: theme.colorScheme.inversePrimary,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(title, style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(subtitle, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// 统一的结果展示面板。
///
/// MethodChannel 示例都会展示“当前调用结果”，
/// extra 用于放图片预览、主题预览等额外内容。
class ResultPanel extends StatelessWidget {
  const ResultPanel({
    super.key,
    required this.title,
    required this.content,
    this.extra,
  });

  final String title;
  final String content;
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(content, style: theme.textTheme.bodyLarge),
        ),
        if (extra != null) ...[
          const SizedBox(height: 12),
          extra!,
        ],
      ],
    );
  }
}

/// 带加载状态的主按钮。
///
/// 当原生调用还在进行时，按钮禁用并显示 CircularProgressIndicator，
/// 避免用户连续点击触发重复请求。
class LoadingFilledButton extends StatelessWidget {
  const LoadingFilledButton({
    super.key,
    required this.isLoading,
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final bool isLoading;
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon),
        label: Text(isLoading ? context.l10n.text('requesting') : label),
      ),
    );
  }
}

/// 示例 1：获取原生手机电量。
class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  bool _isLoading = false;

  /// 结果文案为空时，build 阶段会按当前语言展示默认提示。
  ///
  /// 这样切换语言后，尚未调用过的结果区域也能跟着变。
  String? _resultText;

  /// 调用 Android / iOS 原生的 getBatteryLevel 方法。
  ///
  /// 成功时返回 int，失败时统一交给 _formatNativeError 转换文案。
  Future<void> _getBatteryLevel() async {
    setState(() {
      _isLoading = true;
      _resultText = context.l10n.text('batteryLoading');
    });

    try {
      final batteryLevel =
          await PlatformChannels.info.invokeMethod<int>('getBatteryLevel');
      setState(() {
        _resultText = batteryLevel == null
            ? context.l10n.text('batteryEmpty')
            : context.l10n.format('batterySuccess', {'value': batteryLevel});
      });
    } catch (error) {
      setState(() {
        _resultText = _formatNativeError(context, 'getBatteryLevel', error);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageScaffold(
      title: context.l10n.text('batteryTitle'),
      subtitle: context.l10n.text('batteryDescription'),
      children: [
        ResultPanel(
          title: context.l10n.text('result'),
          content: _resultText ?? context.l10n.text('batteryInitial'),
        ),
        const SizedBox(height: 16),
        LoadingFilledButton(
          isLoading: _isLoading,
          icon: Icons.battery_charging_full,
          label: context.l10n.text('getBattery'),
          onPressed: _getBatteryLevel,
        ),
      ],
    );
  }
}

class DeviceModelPage extends StatefulWidget {
  const DeviceModelPage({super.key});

  @override
  State<DeviceModelPage> createState() => _DeviceModelPageState();
}

class _DeviceModelPageState extends State<DeviceModelPage> {
  bool _isLoading = false;
  String? _resultText;

  /// 调用原生 getDeviceModel 方法。
  ///
  /// 这个示例展示“同一个 MethodChannel 中放多个方法名”的用法。
  Future<void> _getDeviceModel() async {
    setState(() {
      _isLoading = true;
      _resultText = context.l10n.text('deviceLoading');
    });

    try {
      final deviceModel =
          await PlatformChannels.info.invokeMethod<String>('getDeviceModel');
      setState(() {
        _resultText = deviceModel == null || deviceModel.trim().isEmpty
            ? context.l10n.text('deviceEmpty')
            : context.l10n.format('deviceSuccess', {'value': deviceModel});
      });
    } catch (error) {
      setState(() {
        _resultText = _formatNativeError(context, 'getDeviceModel', error);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageScaffold(
      title: context.l10n.text('deviceTitle'),
      subtitle: context.l10n.text('deviceDescription'),
      children: [
        ResultPanel(
          title: context.l10n.text('result'),
          content: _resultText ?? context.l10n.text('deviceInitial'),
        ),
        const SizedBox(height: 16),
        LoadingFilledButton(
          isLoading: _isLoading,
          icon: Icons.phone_android,
          label: context.l10n.text('getDeviceModel'),
          onPressed: _getDeviceModel,
        ),
      ],
    );
  }
}

class NativeMessagePage extends StatefulWidget {
  const NativeMessagePage({super.key});

  @override
  State<NativeMessagePage> createState() => _NativeMessagePageState();
}

class _NativeMessagePageState extends State<NativeMessagePage> {
  /// 输入框控制器用于读取用户输入，并把输入内容作为参数传给原生。
  final TextEditingController _nameController = TextEditingController(
    text: 'Flutter 初学者',
  );

  bool _isLoading = false;
  String? _resultText;

  @override
  void dispose() {
    /// TextEditingController 属于需要手动释放的对象。
    _nameController.dispose();
    super.dispose();
  }

  /// 示例 3：Dart 把 Map 参数传给原生，再接收原生处理后的字符串。
  ///
  /// 重点观察 invokeMethod 的第二个参数：
  /// `<String, dynamic>{'name': inputName, 'from': 'dart'}`
  ///
  /// Android / iOS 会按 key 取出 name 和 from。
  Future<void> _sendNameToNative() async {
    final String inputName = _nameController.text.trim();

    if (inputName.isEmpty) {
      setState(() {
        _resultText = context.l10n.text('nativeEmptyInput');
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _resultText = context.l10n.text('nativeLoading');
    });

    try {
      final nativeMessage = await PlatformChannels.info.invokeMethod<String>(
        'processUserName',
        <String, dynamic>{
          'name': inputName,
          'from': 'dart',
        },
      );
      setState(() {
        _resultText = nativeMessage == null || nativeMessage.trim().isEmpty
            ? context.l10n.text('nativeEmpty')
            : nativeMessage;
      });
    } catch (error) {
      setState(() {
        _resultText = _formatNativeError(context, 'processUserName', error);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageScaffold(
      title: context.l10n.text('nativeMessageTitle'),
      subtitle: context.l10n.text('nativeMessageDescription'),
      children: [
        ResultPanel(
          title: context.l10n.text('result'),
          content: _resultText ?? context.l10n.text('nativeInitial'),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            labelText: context.l10n.text('nameLabel'),
            hintText: context.l10n.text('nameHint'),
          ),
        ),
        const SizedBox(height: 16),
        LoadingFilledButton(
          isLoading: _isLoading,
          icon: Icons.send,
          label: context.l10n.text('sendName'),
          onPressed: _sendNameToNative,
        ),
        const SizedBox(height: 24),
        _CodeBlock(
          title: context.l10n.text('learningFocus'),
          code: """await PlatformChannels.info.invokeMethod<String>(
  'processUserName',
  <String, dynamic>{
    'name': inputName,
    'from': 'dart',
  },
);""",
        ),
      ],
    );
  }
}

class MediaPage extends StatefulWidget {
  const MediaPage({super.key});

  @override
  State<MediaPage> createState() => _MediaPageState();
}

class _MediaPageState extends State<MediaPage> {
  bool _isLoading = false;
  String? _resultText;

  /// 原生返回的本地图片路径。
  ///
  /// Flutter 页面只保存路径，不直接保存图片二进制数据。
  String? _imagePath;

  /// 媒体通道的通用调用方法。
  ///
  /// 相机和相册只有 methodName、加载文案、成功文案不同，
  /// 所以统一收敛到这个函数里，避免两套重复 try/catch。
  Future<void> _invokeMediaMethod({
    required String methodName,
    required String loadingKey,
    required String successKey,
  }) async {
    setState(() {
      _isLoading = true;
      _resultText = context.l10n.text(loadingKey);
    });

    try {
      final String? imagePath =
          await PlatformChannels.media.invokeMethod<String>(methodName);

      setState(() {
        if (imagePath == null || imagePath.trim().isEmpty) {
          _imagePath = null;
          _resultText = context.l10n.text('mediaEmpty');
        } else {
          _imagePath = imagePath;
          _resultText = context.l10n.text(successKey);
        }
      });
    } catch (error) {
      setState(() {
        _imagePath = null;
        _resultText = _formatNativeError(context, methodName, error);
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// 弹出底部菜单，让用户选择“拍照”或“从相册选择”。
  ///
  /// 这样 Flutter 侧先明确媒体来源，再调用对应的原生方法。
  Future<void> _showImageSourceActionSheet() async {
    final String? action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text(context.l10n.text('camera')),
                subtitle: Text(context.l10n.text('cameraSubtitle')),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text(context.l10n.text('gallery')),
                subtitle: Text(context.l10n.text('gallerySubtitle')),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.close),
                title: Text(context.l10n.text('cancel')),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    if (action == 'camera') {
      await _invokeMediaMethod(
        methodName: 'openCamera',
        loadingKey: 'cameraLoading',
        successKey: 'cameraSuccess',
      );
    } else if (action == 'gallery') {
      await _invokeMediaMethod(
        methodName: 'pickImageFromGallery',
        loadingKey: 'galleryLoading',
        successKey: 'gallerySuccess',
      );
    }
  }

  /// 只清空 Flutter 页面状态。
  ///
  /// 当前教学示例不回头删除原生缓存文件，避免把文件管理逻辑混进主流程。
  void _clearImage() {
    setState(() {
      _imagePath = null;
      _resultText = context.l10n.text('imageCleared');
    });
  }

  /// 点击缩略图时弹出大图预览。
  ///
  /// buildLocalFilePreview 会根据平台选择 IO 版本或非 IO 占位版本。
  void _showPreviewDialog() {
    final imagePath = _imagePath;
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
                  context.l10n.text('previewTitle'),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: SingleChildScrollView(
                    child: buildLocalFilePreview(imagePath, height: 420),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(context.l10n.text('close')),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DemoPageScaffold(
      title: context.l10n.text('mediaTitle'),
      subtitle: context.l10n.text('mediaDescription'),
      children: [
        ResultPanel(
          title: context.l10n.text('result'),
          content: _resultText ?? context.l10n.text('mediaInitial'),
          extra: _imagePath == null
              ? null
              : GestureDetector(
                  onTap: _showPreviewDialog,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      buildLocalFilePreview(_imagePath!),
                      const SizedBox(height: 8),
                      Text(
                        context.l10n.text('previewHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 16),
        LoadingFilledButton(
          isLoading: _isLoading,
          icon: Icons.add_photo_alternate,
          label: context.l10n.text('chooseImageSource'),
          onPressed: _showImageSourceActionSheet,
        ),
        if (_imagePath != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _showImageSourceActionSheet,
                  icon: const Icon(Icons.refresh),
                  label: Text(context.l10n.text('reselectImage')),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _clearImage,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(context.l10n.text('clearImage')),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class I18nExamplePage extends StatelessWidget {
  const I18nExamplePage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
  });

  final Locale? currentLocale;
  final ValueChanged<Locale?> onLocaleChanged;

  @override
  Widget build(BuildContext context) {
    /// currentLocale 为 null 表示跟随系统。
    final selectedLanguage = currentLocale?.languageCode ?? 'system';

    return DemoPageScaffold(
      title: context.l10n.text('i18nTitle'),
      subtitle: context.l10n.text('i18nDescription'),
      children: [
        ResultPanel(
          title: context.l10n.text('i18nCurrentTextTitle'),
          content: context.l10n.text('i18nCurrentText'),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.text('language'),
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          /// 语言模式是互斥选择，所以用 SegmentedButton。
          segments: [
            ButtonSegment<String>(
              value: 'system',
              label: Text(context.l10n.text('system')),
              icon: const Icon(Icons.settings_suggest),
            ),
            ButtonSegment<String>(
              value: 'zh',
              label: Text(context.l10n.text('chinese')),
              icon: const Icon(Icons.language),
            ),
            ButtonSegment<String>(
              value: 'en',
              label: Text(context.l10n.text('english')),
              icon: const Icon(Icons.translate),
            ),
          ],
          selected: {selectedLanguage},
          onSelectionChanged: (selection) {
            final value = selection.first;
            onLocaleChanged(value == 'system' ? null : Locale(value));
          },
        ),
        const SizedBox(height: 24),
        _LearningPoints(
          points: [
            context.l10n.text('i18nStep1'),
            context.l10n.text('i18nStep2'),
            context.l10n.text('i18nStep3'),
          ],
        ),
        const SizedBox(height: 20),
        _CodeBlock(
          title: context.l10n.text('codeMaterialApp'),
          code: """MaterialApp(
  locale: _locale,
  supportedLocales: const [
    Locale('zh'),
    Locale('en'),
  ],
  localizationsDelegates: const [
    AppLocalizations.delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ],
);""",
        ),
        const SizedBox(height: 16),
        _CodeBlock(
          title: context.l10n.text('codeLookup'),
          code: """Text(context.l10n.text('homeTitle'));

// 切换中文
onLocaleChanged(const Locale('zh'));

// 切换英文
onLocaleChanged(const Locale('en'));

// 恢复跟随系统
onLocaleChanged(null);""",
        ),
      ],
    );
  }
}

class ThemeSettingsPage extends StatelessWidget {
  const ThemeSettingsPage({
    super.key,
    required this.themeMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DemoPageScaffold(
      title: context.l10n.text('themeTitle'),
      subtitle: context.l10n.text('themeDescription'),
      children: [
        Text(
          context.l10n.text('themeModeTitle'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        SegmentedButton<ThemeMode>(
          /// 主题模式也是互斥选择：
          /// 系统、浅色、深色三者只能选一个。
          showSelectedIcon: false,
          segments: [
            ButtonSegment<ThemeMode>(
              value: ThemeMode.system,
              label: Text(context.l10n.text('themeSystem')),
              icon: const Icon(Icons.settings_suggest),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.light,
              label: Text(context.l10n.text('themeLight')),
              icon: const Icon(Icons.light_mode),
            ),
            ButtonSegment<ThemeMode>(
              value: ThemeMode.dark,
              label: Text(context.l10n.text('themeDark')),
              icon: const Icon(Icons.dark_mode),
            ),
          ],
          selected: {themeMode},
          onSelectionChanged: (selection) {
            onThemeModeChanged(selection.first);
          },
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.text('themeColorTitle'),
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          /// 主题色选项可能在窄屏放不下一整行，
          /// Wrap 会自动换行，避免横向溢出。
          spacing: 8,
          runSpacing: 8,
          children: AppTheme.options.map((option) {
            final isSelected = option.color == seedColor;
            return ChoiceChip(
              /// ChoiceChip 既能显示“当前选中”，又能作为轻量级选择控件。
              selected: isSelected,
              label: Text(context.l10n.text(option.nameKey)),
              avatar: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: option.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
              ),
              onSelected: (_) => onSeedColorChanged(option.color),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        ResultPanel(
          title: context.l10n.text('themePreviewTitle'),
          content: context.l10n.text('themePreviewContent'),
          extra: Container(
            /// 预览区不写死颜色，而是读取当前 Theme 的 ColorScheme。
            /// 这样切换主题色或深浅模式后，这块区域会自动变化。
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.palette,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.l10n.text('themeTitle'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                FilledButton(
                  onPressed: () {},
                  child: Text(context.l10n.text('openDemo')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LearningPoints extends StatelessWidget {
  const _LearningPoints({required this.points});

  final List<String> points;

  @override
  Widget build(BuildContext context) {
    return ResultPanel(
      title: context.l10n.text('learningFocus'),
      content: points.join('\n'),
    );
  }
}

class _CodeBlock extends StatelessWidget {
  const _CodeBlock({
    required this.title,
    required this.code,
  });

  final String title;
  final String code;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(8),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SelectableText(
              code,
              style: const TextStyle(
                color: Color(0xFFE5E7EB),
                fontFamily: 'monospace',
                height: 1.45,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
