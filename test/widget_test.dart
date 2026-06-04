import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:channel/main.dart';

/// 统一用中文启动测试。
///
/// 国际化项目如果不固定 Locale，测试环境可能因为系统语言不同而不稳定。
Future<void> pumpChineseApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp(initialLocale: Locale('zh')));
  await tester.pumpAndSettle();
}

void main() {
  /// 验证首页目录是否完整展示所有功能入口。
  testWidgets('shows directory home page', (WidgetTester tester) async {
    await pumpChineseApp(tester);

    expect(find.text('MethodChannel 学习目录'), findsWidgets);
    expect(find.text('获取原生手机电量'), findsOneWidget);
    expect(find.text('获取设备型号'), findsOneWidget);
    expect(find.text('Dart 传参数给原生'), findsOneWidget);
    expect(find.text('调用系统相机 / 相册'), findsOneWidget);
    expect(find.text('国际化代码示例'), findsOneWidget);
    expect(find.text('多主题切换'), findsOneWidget);
  });

  /// 专门验证窄屏中文布局不会再出现 RenderFlex overflow。
  testWidgets('home directory fits narrow Chinese layout', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpChineseApp(tester);

    expect(find.text('获取原生手机电量'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  /// 验证目录按钮可以跳转到电量示例页。
  testWidgets('opens feature page from directory', (WidgetTester tester) async {
    await pumpChineseApp(tester);

    await tester.tap(find.text('获取原生手机电量'));
    await tester.pumpAndSettle();

    expect(find.text('获取原生电量'), findsOneWidget);
    expect(find.text('调用结果'), findsOneWidget);
  });

  /// 验证国际化页面可以从中文切换到英文。
  testWidgets('opens i18n example and switches language', (
    WidgetTester tester,
  ) async {
    await pumpChineseApp(tester);

    await tester.tap(find.text('国际化代码示例'));
    await tester.pumpAndSettle();

    expect(find.text('当前本地化文案'), findsOneWidget);

    await tester.tap(find.text('English'));
    await tester.pumpAndSettle();

    expect(find.text('Internationalization example'), findsWidgets);
    expect(find.text('Current localized text'), findsOneWidget);
  });

  /// 验证媒体示例页可以通过首页目录进入。
  testWidgets('opens media page from directory', (WidgetTester tester) async {
    await pumpChineseApp(tester);

    await tester.tap(find.text('调用系统相机 / 相册'));
    await tester.pumpAndSettle();

    expect(find.text('选择图片来源'), findsOneWidget);
  });

  /// 验证主题设置页可以切换明暗模式和主题色。
  testWidgets('opens theme page and switches theme options', (
    WidgetTester tester,
  ) async {
    await pumpChineseApp(tester);

    await tester.tap(find.text('多主题切换'));
    await tester.pumpAndSettle();

    expect(find.text('主题模式'), findsOneWidget);
    expect(find.text('主题色'), findsOneWidget);

    await tester.tap(find.text('深色'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ChoiceChip, '玫红'));
    await tester.pumpAndSettle();

    expect(find.text('主题预览'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
