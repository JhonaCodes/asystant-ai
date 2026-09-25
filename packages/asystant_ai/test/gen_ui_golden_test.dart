import 'dart:io';

import 'package:asystant_ai/asystant_ai.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    // Flutter test runs from either the workspace or package directory.
    final font = File('test/fonts/Roboto-Regular.ttf').existsSync()
        ? File('test/fonts/Roboto-Regular.ttf')
        : File('packages/asystant_ai/test/fonts/Roboto-Regular.ttf');
    final loader = FontLoader('Roboto')
      ..addFont(Future.value(ByteData.sublistView(await font.readAsBytes())));
    await loader.load();
    final icons = File('${font.parent.path}/MaterialIcons-Regular.otf');
    final iconLoader = FontLoader('MaterialIcons')
      ..addFont(Future.value(ByteData.sublistView(await icons.readAsBytes())));
    await iconLoader.load();
  });

  // Font rasterization differs between Flutter's macOS and Linux engines.
  // Keep exact pixel comparison against baselines recorded on the same host OS.
  // Existing macOS images remain stable documentation links.
  final goldenDirectory = Platform.isMacOS
      ? 'goldens'
      : 'goldens/${Platform.operatingSystem}';

  for (final width in [390.0, 900.0]) {
    testWidgets('English report at width $width', (tester) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: 'Roboto',
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    Text(
                      'Assistant',
                      style: ThemeData().textTheme.headlineSmall?.copyWith(
                        fontFamily: 'Roboto',
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Here is the activity summary for your workspace.',
                    ),
                    const SizedBox(height: 20),
                    const GenUiCard(
                      strings: AsystantStrings(spanish: false),
                      card: AssistantCard(
                        title: 'Weekly activity',
                        body: '146 appointments completed across three service areas.',
                        chart: AssistantChart(
                          title: 'Weekly activity',
                          source:
                              'Demo data · Sep 21–25, 2026 · Complete sample',
                          unit: 'appointments',
                          points: [
                            ChartPoint(label: 'Customer service', value: 72),
                            ChartPoint(label: 'Collections', value: 46),
                            ChartPoint(label: 'Information', value: 28),
                          ],
                        ),
                      ),
                    ),
                    const GenUiCard(
                      strings: AsystantStrings(spanish: false),
                      card: AssistantCard(
                        title: 'Daily trend',
                        kind: .result,
                        chart: AssistantChart(
                          title: 'Daily trend',
                          kind: .line,
                          source: 'Demo data · Mon–Fri · 146 appointments',
                          points: [
                            ChartPoint(label: 'Monday', value: 20),
                            ChartPoint(label: 'Tuesday', value: 26),
                            ChartPoint(label: 'Wednesday', value: 32),
                            ChartPoint(label: 'Thursday', value: 28),
                            ChartPoint(label: 'Friday', value: 40),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      expect(find.text('Customer service'), findsOneWidget);
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('$goldenDirectory/report_${width.toInt()}.png'),
      );
    });
  }
}
