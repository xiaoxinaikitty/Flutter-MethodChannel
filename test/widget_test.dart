import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

import 'package:channel/main.dart';

Future<void> pumpChineseApp(WidgetTester tester) async {
  await tester.pumpWidget(const MyApp(initialLocale: Locale('zh')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows directory home page', (WidgetTester tester) async {
    await pumpChineseApp(tester);

    expect(find.text('MethodChannel 学习目录'), findsWidgets);
    expect(find.text('获取原生手机电量'), findsOneWidget);
    expect(find.text('获取设备型号'), findsOneWidget);
    expect(find.text('Dart 传参数给原生'), findsOneWidget);
    expect(find.text('调用系统相机 / 相册'), findsOneWidget);
    expect(find.text('国际化代码示例'), findsOneWidget);
  });

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

  testWidgets('opens feature page from directory', (WidgetTester tester) async {
    await pumpChineseApp(tester);

    await tester.tap(find.text('获取原生手机电量'));
    await tester.pumpAndSettle();

    expect(find.text('获取原生电量'), findsOneWidget);
    expect(find.text('调用结果'), findsOneWidget);
  });

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

  testWidgets('opens media page from directory', (WidgetTester tester) async {
    await pumpChineseApp(tester);

    await tester.tap(find.text('调用系统相机 / 相册'));
    await tester.pumpAndSettle();

    expect(find.text('选择图片来源'), findsOneWidget);
  });
}
