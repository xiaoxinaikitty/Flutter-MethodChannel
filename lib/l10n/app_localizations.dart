import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

/// 项目的国际化实现入口。
///
/// 这个文件专门负责：
/// - 支持哪些语言
/// - 每种语言的文案
/// - 如何根据 Locale 读取文案
/// - 如何暴露给 MaterialApp 使用
class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const supportedLocales = [
    Locale('zh'),
    Locale('en'),
  ];

  static const delegate = _AppLocalizationsDelegate();

  /// MaterialApp 直接复用这个列表即可。
  static const List<LocalizationsDelegate<dynamic>> localizationDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  /// 当前项目的文案表。
  ///
  /// 第一层 key 是语言代码，例如 zh / en。
  /// 第二层 key 是具体文案名称，例如 homeTitle / themeTitle。
  ///
  /// 页面永远通过 key 取文案，不直接关心当前是中文还是英文。
  static const Map<String, Map<String, String>> _values = {
    'zh': {
      'appTitle': 'MethodChannel 学习目录',
      'homeTitle': 'MethodChannel 学习目录',
      'homeSubtitle': '把每个原生通信示例拆成独立页面，按目录按钮进入，更方便逐个学习和调试。',
      'platformTitle': '当前平台',
      'batteryTitle': '获取原生手机电量',
      'batteryDescription':
          'Dart 调用 Android / iOS 原生方法 getBatteryLevel，并展示返回值。',
      'deviceTitle': '获取设备型号',
      'deviceDescription': '同一条 MethodChannel 里调用另一个方法 getDeviceModel。',
      'nativeMessageTitle': 'Dart 传参数给原生',
      'nativeMessageDescription': '把输入框里的 name 作为 Map 参数传给原生，再接收处理结果。',
      'mediaTitle': '调用系统相机 / 相册',
      'mediaDescription': '使用单独的媒体通道打开相机或相册，并把图片路径返回给 Flutter。',
      'i18nTitle': '国际化代码示例',
      'i18nDescription':
          '演示 Locale、LocalizationsDelegate、supportedLocales 和语言切换。',
      'themeTitle': '多主题切换',
      'themeDescription': '演示 ThemeMode、浅色/深色模式和主题色切换。',
      'themeModeTitle': '主题模式',
      'themeColorTitle': '主题色',
      'themePreviewTitle': '主题预览',
      'themePreviewContent': '切换模式或颜色后，整个 App 会立即使用新的 ThemeData。',
      'themeSystem': '跟随系统',
      'themeLight': '浅色',
      'themeDark': '深色',
      'themeColorBlue': '蓝色',
      'themeColorTeal': '青绿',
      'themeColorRose': '玫红',
      'themeColorPurple': '紫色',
      'themeColorOrange': '橙色',
      'openDemo': '进入示例',
      'learningFocus': '学习重点',
      'result': '调用结果',
      'requesting': '请求中...',
      'getBattery': '获取原生电量',
      'batteryInitial': '点击按钮后，这里会显示原生返回的手机电量。',
      'batteryLoading': '正在向原生平台请求电量...',
      'batteryEmpty': '原生返回了空数据，请检查返回值。',
      'batterySuccess': '当前电量：{value}%',
      'getDeviceModel': '获取设备型号',
      'deviceInitial': '点击按钮后，这里会显示原生返回的设备型号。',
      'deviceLoading': '正在向原生平台请求设备型号...',
      'deviceEmpty': '原生返回了空字符串，请检查返回值。',
      'deviceSuccess': '当前设备型号：{value}',
      'nativeInitial': '先在输入框里输入名字，再点击按钮把参数传给原生。',
      'nameLabel': '输入一个名字',
      'nameHint': '例如：小明',
      'sendName': '把名字传给原生',
      'nativeEmptyInput': '请先输入一个名字，再点击“把名字传给原生”。',
      'nativeLoading': '正在把参数传给原生，并等待原生处理结果...',
      'nativeEmpty': '原生返回了空字符串，请检查参数处理逻辑。',
      'mediaInitial': '点击按钮后，可以选择“拍照”或“从相册选择”，并把图片直接显示在页面上。',
      'chooseImageSource': '选择图片来源',
      'camera': '拍照',
      'cameraSubtitle': '调用原生系统相机拍一张新照片',
      'gallery': '从相册选择',
      'gallerySubtitle': '调用原生系统相册选择已有图片',
      'cancel': '取消',
      'cameraLoading': '正在请求原生系统相机...',
      'galleryLoading': '正在请求原生系统相册...',
      'cameraSuccess': '拍照成功，下面就是原生系统相机返回的图片。',
      'gallerySuccess': '选择成功，下面就是原生系统相册返回的图片。',
      'mediaEmpty': '原生媒体通道返回了空路径，请检查原生保存逻辑。',
      'previewHint': '点击图片可放大查看',
      'previewTitle': '图片预览',
      'close': '关闭',
      'reselectImage': '重新选择图片',
      'clearImage': '清空照片',
      'imageCleared': '图片已清空。你可以再次选择“拍照”或“从相册选择”继续测试。',
      'i18nCurrentTextTitle': '当前本地化文案',
      'i18nCurrentText': '这行文字会随着语言切换立即变化。',
      'language': '语言',
      'system': '跟随系统',
      'chinese': '中文',
      'english': 'English',
      'i18nStep1':
          '1. 在 MaterialApp 配置 supportedLocales 和 localizationsDelegates。',
      'i18nStep2': '2. 用 Locale 控制当前语言，传 null 可以恢复跟随系统。',
      'i18nStep3': '3. 页面里通过 AppLocalizations.of(context) 读取文案。',
      'codeMaterialApp': 'MaterialApp 配置示例',
      'codeLookup': '页面读取文案示例',
      'missingPlugin':
          '当前平台没有实现 `{method}`。\n如果你是在 Windows / Web 上运行，这是正常的，因为示例只实现了 Android/iOS。',
      'platformError': '调用原生失败：{code}\n错误信息：{message}',
      'unexpectedError': '发生未预期错误：{error}',
      'platformWeb': 'Web。Web 没有 Android/iOS 这一层原生代码，这里主要用于学习 Dart 写法。',
      'platformAndroid': 'Android。本项目已实现电量、设备型号、Dart 传参、相机/相册和国际化示例。',
      'platformIOS': 'iOS。本项目已实现电量、设备型号、Dart 传参、相机/相册和国际化示例。',
      'platformOther': '非 Android/iOS。页面可以正常打开，但调用原生方法时通常会提示未实现。',
    },
    'en': {
      'appTitle': 'MethodChannel Study Directory',
      'homeTitle': 'MethodChannel Study Directory',
      'homeSubtitle':
          'Each native communication demo is now a separate page, so you can enter, learn, and debug one topic at a time.',
      'platformTitle': 'Current platform',
      'batteryTitle': 'Native battery level',
      'batteryDescription':
          'Dart calls the Android / iOS getBatteryLevel method and renders the returned value.',
      'deviceTitle': 'Native device model',
      'deviceDescription':
          'Call another method, getDeviceModel, through the same MethodChannel.',
      'nativeMessageTitle': 'Send Dart arguments to native',
      'nativeMessageDescription':
          'Send the name from the text field as a Map argument and receive the native result.',
      'mediaTitle': 'Open camera / gallery',
      'mediaDescription':
          'Use a dedicated media channel to open camera or gallery and return the image path to Flutter.',
      'i18nTitle': 'Internationalization example',
      'i18nDescription':
          'Learn Locale, LocalizationsDelegate, supportedLocales, and runtime language switching.',
      'themeTitle': 'Theme switching',
      'themeDescription':
          'Learn ThemeMode, light/dark mode, and seed color switching.',
      'themeModeTitle': 'Theme mode',
      'themeColorTitle': 'Theme color',
      'themePreviewTitle': 'Theme preview',
      'themePreviewContent':
          'After switching mode or color, the whole app immediately uses the new ThemeData.',
      'themeSystem': 'System',
      'themeLight': 'Light',
      'themeDark': 'Dark',
      'themeColorBlue': 'Blue',
      'themeColorTeal': 'Teal',
      'themeColorRose': 'Rose',
      'themeColorPurple': 'Purple',
      'themeColorOrange': 'Orange',
      'openDemo': 'Open demo',
      'learningFocus': 'Learning focus',
      'result': 'Result',
      'requesting': 'Requesting...',
      'getBattery': 'Get battery level',
      'batteryInitial':
          'Tap the button to show the battery level returned by native code.',
      'batteryLoading': 'Requesting battery level from the native platform...',
      'batteryEmpty': 'Native code returned null. Check the return value.',
      'batterySuccess': 'Current battery level: {value}%',
      'getDeviceModel': 'Get device model',
      'deviceInitial':
          'Tap the button to show the device model returned by native code.',
      'deviceLoading': 'Requesting device model from the native platform...',
      'deviceEmpty':
          'Native code returned an empty string. Check the return value.',
      'deviceSuccess': 'Current device model: {value}',
      'nativeInitial':
          'Enter a name, then tap the button to send it to native code.',
      'nameLabel': 'Enter a name',
      'nameHint': 'For example: Alex',
      'sendName': 'Send name to native',
      'nativeEmptyInput': 'Enter a name before sending it to native code.',
      'nativeLoading':
          'Sending arguments to native code and waiting for the result...',
      'nativeEmpty':
          'Native code returned an empty string. Check the argument handling logic.',
      'mediaInitial':
          'Tap the button to choose camera or gallery, then show the returned image on this page.',
      'chooseImageSource': 'Choose image source',
      'camera': 'Camera',
      'cameraSubtitle': 'Open the native system camera',
      'gallery': 'Gallery',
      'gallerySubtitle': 'Open the native system gallery',
      'cancel': 'Cancel',
      'cameraLoading': 'Requesting the native system camera...',
      'galleryLoading': 'Requesting the native system gallery...',
      'cameraSuccess':
          'Photo captured. The image below is returned by the native camera.',
      'gallerySuccess':
          'Image selected. The image below is returned by the native gallery.',
      'mediaEmpty':
          'The media channel returned an empty path. Check the native save logic.',
      'previewHint': 'Tap the image to preview',
      'previewTitle': 'Image preview',
      'close': 'Close',
      'reselectImage': 'Choose again',
      'clearImage': 'Clear image',
      'imageCleared':
          'The image has been cleared. Choose camera or gallery again to continue testing.',
      'i18nCurrentTextTitle': 'Current localized text',
      'i18nCurrentText':
          'This text changes immediately when you switch languages.',
      'language': 'Language',
      'system': 'System',
      'chinese': '中文',
      'english': 'English',
      'i18nStep1':
          '1. Configure supportedLocales and localizationsDelegates in MaterialApp.',
      'i18nStep2':
          '2. Use Locale to control the current language. Pass null to follow the system.',
      'i18nStep3':
          '3. Read strings with AppLocalizations.of(context) inside widgets.',
      'codeMaterialApp': 'MaterialApp configuration example',
      'codeLookup': 'Reading localized text in a page',
      'missingPlugin':
          'The current platform does not implement `{method}`.\nThis is expected on Windows / Web because the native demos are implemented only for Android/iOS.',
      'platformError': 'Native call failed: {code}\nMessage: {message}',
      'unexpectedError': 'Unexpected error: {error}',
      'platformWeb':
          'Web. Web has no Android/iOS native layer, so this page mainly helps you study the Dart side.',
      'platformAndroid':
          'Android. This project implements battery, device model, Dart arguments, camera/gallery, and i18n demos.',
      'platformIOS':
          'iOS. This project implements battery, device model, Dart arguments, camera/gallery, and i18n demos.',
      'platformOther':
          'Not Android/iOS. The pages can open normally, but native calls usually report missing implementation.',
    },
  };

  /// 读取普通文案。
  ///
  /// 查找顺序：
  /// 1. 当前语言
  /// 2. 中文兜底
  /// 3. key 本身
  ///
  /// 这样即使某个翻译漏配，页面也不会因为找不到文案而崩溃。
  String text(String key) {
    return _values[locale.languageCode]?[key] ?? _values['zh']![key] ?? key;
  }

  /// 读取带参数的文案。
  ///
  /// 例如模板：'当前电量：{value}%'
  /// 调用：format('batterySuccess', {'value': 85})
  /// 结果：'当前电量：85%'
  String format(String key, Map<String, Object?> values) {
    var template = text(key);
    for (final entry in values.entries) {
      template = template.replaceAll('{${entry.key}}', '${entry.value}');
    }
    return template;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    /// Flutter 会先问代理：当前系统语言是否支持。
    return AppLocalizations.supportedLocales.any(
      (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
    );
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    /// 真正加载本地化对象。
    ///
    /// 当前文案写在内存 Map 中，所以这里可以直接同步创建并返回。
    return AppLocalizations(locale);
  }

  /// 文案是常量 Map，不需要重新加载代理。
  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

/// 给 BuildContext 增加 context.l10n 快捷入口。
///
/// 页面里使用 context.l10n.text('homeTitle')，
/// 比 AppLocalizations.of(context).text('homeTitle') 更简洁。
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
