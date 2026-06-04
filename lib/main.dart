import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'l10n/app_localizations.dart';
import 'local_file_preview_stub.dart'
    if (dart.library.io) 'local_file_preview_io.dart';

void main() {
  runApp(const MyApp());
}

class AppRoutes {
  static const home = '/';
  static const battery = '/battery';
  static const deviceModel = '/device-model';
  static const nativeMessage = '/native-message';
  static const media = '/media';
  static const i18n = '/i18n';
}

class PlatformChannels {
  static const MethodChannel info = MethodChannel(
    'samples.flutter.dev/battery',
  );

  static const MethodChannel media = MethodChannel(
    'samples.flutter.dev/camera',
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key, this.initialLocale});

  final Locale? initialLocale;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;

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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) => context.l10n.text('appTitle'),
      locale: _locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationDelegates,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
      ),
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
      },
    );
  }
}

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

class BatteryPage extends StatefulWidget {
  const BatteryPage({super.key});

  @override
  State<BatteryPage> createState() => _BatteryPageState();
}

class _BatteryPageState extends State<BatteryPage> {
  bool _isLoading = false;
  String? _resultText;

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
  final TextEditingController _nameController = TextEditingController(
    text: 'Flutter 初学者',
  );

  bool _isLoading = false;
  String? _resultText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

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
  String? _imagePath;

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

  void _clearImage() {
    setState(() {
      _imagePath = null;
      _resultText = context.l10n.text('imageCleared');
    });
  }

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
