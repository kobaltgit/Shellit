import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:shellit/src/localization/default_strings.dart';
import 'package:shellit/src/localization/localization_providers.dart';
import 'package:shellit/src/localization/localization_service.dart';
import 'package:shellit/src/localization/template_exporter.dart';

void main() {
  group('AppLocalizationService', () {
    late AppLocalizationService service;

    setUp(() {
      service = AppLocalizationService();
    });

    test('returns default English strings when active locale is English', () {
      expect(service.currentLocale, equals('en'));
      expect(service.translate('common.connect'), equals('Connect'));
      expect(
        service.translate('settings.title'),
        equals('Settings & Security'),
      );
    });

    test('interpolates parameters accurately in strings', () {
      final text = service.translate(
        'settings.vault.auto_lock_subtitle',
        params: {'minutes': '15'},
      );
      expect(text, equals('Lock database after 15 minutes of inactivity'));
    });

    test('registers language pack and switches locale with fallback', () async {
      service.registerLanguagePack('ru_RU', {
        'common.connect': 'Подключиться',
        'common.cancel': 'Отмена',
      });

      expect(service.availableLocales, containsAll(['en', 'ru_RU']));

      await service.setLocale('ru_RU');
      expect(service.currentLocale, equals('ru_RU'));

      // Key present in Russian dictionary
      expect(service.translate('common.connect'), equals('Подключиться'));

      // Key NOT present in Russian dictionary -> falls back to default English
      expect(
        service.translate('settings.title'),
        equals('Settings & Security'),
      );

      // Key NOT present in either -> uses defaultText or returns key
      expect(
        service.translate('unknown.action', defaultText: 'Custom Fallback'),
        equals('Custom Fallback'),
      );
      expect(service.translate('unknown.action'), equals('unknown.action'));
    });

    test(
      'unregisters language pack and resets active locale to en if removed',
      () async {
        service.registerLanguagePack('de', {'common.connect': 'Verbinden'});
        expect(service.availableLocales, contains('de'));

        await service.setLocale('de');
        expect(service.currentLocale, equals('de'));
        expect(service.translate('common.connect'), equals('Verbinden'));

        // Unregister 'de'
        service.unregisterLanguagePack('de');
        expect(service.availableLocales, isNot(contains('de')));
        // Should automatically reset active locale to 'en'
        expect(service.currentLocale, equals('en'));
        // Translation should now fallback to English
        expect(service.translate('common.connect'), equals('Connect'));

        // Attempting to unregister built-in English should have no effect
        service.unregisterLanguagePack('en');
        expect(service.availableLocales, contains('en'));
        expect(service.currentLocale, equals('en'));
      },
    );

    test('exports full default English template', () {
      final template = service.exportTemplate();
      expect(template.length, equals(defaultEnglishStrings.length));
      expect(template['common.connect'], equals('Connect'));
    });
  });

  group('TemplateExporter', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shellit_l10n_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('exports valid formatted JSON file to target path', () async {
      final targetPath = p.join(tempDir.path, 'my_template.json');
      final result = await TemplateExporter.exportTemplateFile(
        targetFilePath: targetPath,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(targetPath));

      final file = File(targetPath);
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final decoded = json.decode(content);
      expect(decoded is Map<String, dynamic>, isTrue);
      expect(decoded['common.connect'], equals('Connect'));
      expect(decoded['settings.title'], equals('Settings & Security'));
    });
  });

  group('LocalizationScope & UI Reactivity', () {
    testWidgets('context.tr translates and re-renders on locale change', (
      tester,
    ) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final service = container.read(localizationServiceProvider);
      service.registerLanguagePack('ru_RU', {'common.connect': 'Подключиться'});

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Consumer(
            builder: (context, ref, _) {
              final activeLocale = ref.watch(activeLocaleProvider);
              final l10nService = ref.watch(localizationServiceProvider);

              return LocalizationScope(
                service: l10nService,
                locale: activeLocale,
                child: MaterialApp(
                  home: Scaffold(
                    body: Builder(
                      builder: (ctx) {
                        return Column(
                          children: [
                            Text(ctx.tr('common.connect')),
                            ElevatedButton(
                              onPressed: () {
                                ref
                                    .read(activeLocaleProvider.notifier)
                                    .changeLocale('ru_RU');
                              },
                              child: const Text('Switch to Russian'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Initial state: English
      expect(find.text('Connect'), findsOneWidget);
      expect(find.text('Подключиться'), findsNothing);

      // Switch language to Russian
      await tester.tap(find.text('Switch to Russian'));
      await tester.pumpAndSettle();

      // Updated state: Russian without app restart!
      expect(find.text('Подключиться'), findsOneWidget);
      expect(find.text('Connect'), findsNothing);
    });

    testWidgets(
      'availableLocalesProvider dynamically updates on register/unregister and resets active locale',
      (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: Consumer(
              builder: (context, ref, _) {
                final activeLocale = ref.watch(activeLocaleProvider);
                final availableLocales = ref.watch(availableLocalesProvider);
                final l10nService = ref.watch(localizationServiceProvider);

                return LocalizationScope(
                  service: l10nService,
                  locale: activeLocale,
                  child: MaterialApp(
                    home: Scaffold(
                      body: Builder(
                        builder: (ctx) {
                          return Column(
                            children: [
                              Text('Active: $activeLocale'),
                              Text('Locales: ${availableLocales.join(', ')}'),
                              Text(ctx.tr('common.connect')),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Initial state: only English
        expect(find.text('Active: en'), findsOneWidget);
        expect(find.text('Locales: en'), findsOneWidget);
        expect(find.text('Connect'), findsOneWidget);

        // Dynamically register Spanish
        container.read(activeLocaleProvider.notifier).registerLanguagePack(
          'es',
          {'common.connect': 'Conectar'},
        );
        await tester.pumpAndSettle();

        // Locales list updated to include 'es'
        expect(find.text('Locales: en, es'), findsOneWidget);

        // Change locale to 'es'
        await container.read(activeLocaleProvider.notifier).changeLocale('es');
        await tester.pumpAndSettle();

        expect(find.text('Active: es'), findsOneWidget);
        expect(find.text('Conectar'), findsOneWidget);

        // Unregister 'es' (simulating plugin deletion/disable)
        container
            .read(activeLocaleProvider.notifier)
            .unregisterLanguagePack('es');
        await tester.pumpAndSettle();

        // Available locales should remove 'es', active should fall back to 'en', and string should be English
        expect(find.text('Locales: en'), findsOneWidget);
        expect(find.text('Active: en'), findsOneWidget);
        expect(find.text('Connect'), findsOneWidget);
      },
    );
  });
}
