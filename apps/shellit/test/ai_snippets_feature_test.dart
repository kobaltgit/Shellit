import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:shellit/src/localization/localization_providers.dart';
import 'package:shellit/src/localization/localization_service.dart';
import 'package:shellit/src/screens/settings/ai_settings_card.dart';
import 'package:shellit/src/screens/snippets/ai_snippet_chat_view.dart';
import 'package:shellit/src/screens/snippets/snippets_screen.dart';
import 'package:storage_vault/storage_vault.dart';

void main() {
  late VaultDatabase db;
  late VaultCryptoService crypto;
  late VaultSecurityContext security;
  late VaultRepository vaultRepo;
  late SnippetRepository snippetRepo;

  setUp(() async {
    db = VaultDatabaseConnection.inMemory();
    crypto = VaultCryptoService();
    security = VaultSecurityContext();

    vaultRepo = VaultRepository(
      db: db,
      cryptoService: crypto,
      securityContext: security,
    );
    snippetRepo = SnippetRepository(db: db, securityContext: security);

    await vaultRepo.initializeVault('Master123!');
  });

  tearDown(() async {
    vaultRepo.lock();
    await db.close();
  });

  Widget buildTestableWidget(Widget child, {List<Override> overrides = const []}) {
    final localizationService = AppLocalizationService();

    return ProviderScope(
      overrides: [
        appVaultRepositoryProvider.overrideWithValue(vaultRepo),
        appSnippetRepositoryProvider.overrideWithValue(snippetRepo),
        localizationServiceProvider.overrideWithValue(localizationService),
        ...overrides,
      ],
      child: LocalizationScope(
        service: localizationService,
        locale: 'en',
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(body: child),
        ),
      ),
    );
  }

  group('AiSettingsCard', () {
    testWidgets('renders all AI settings controls correctly', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const AiSettingsCard()));
      await tester.pumpAndSettle();

      expect(find.text('Enable AI Snippet Assistant'), findsOneWidget);
      expect(find.text('Gemini API Key'), findsOneWidget);
      expect(find.text('Get free API key at Google AI Studio ↗'), findsOneWidget);
      expect(find.text('AI Model'), findsOneWidget);
      expect(find.text('Test Connection'), findsOneWidget);
      expect(find.text('Save AI Settings'), findsOneWidget);
    });
  });

  group('AiSnippetChatView', () {
    testWidgets('shows warning when Gemini API key is not configured', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          AiSnippetChatView(onOpenSettings: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Gemini API Key Required'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
    });

    testWidgets('renders chat interface with quick prompts when key is set', (tester) async {
      // Configure API key
      await vaultRepo.updateSettings(
        const VaultSettingsEntity(
          geminiApiKey: 'AIzaSyTestValidKey123',
          geminiModelId: 'gemini-2.5-flash',
          isAiSnippetEnabled: true,
          idleLockTimeoutMinutes: 0,
        ),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          AiSnippetChatView(onOpenSettings: () {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Model: gemini-2.5-flash'), findsOneWidget);
      expect(find.text('Docker clean stopped containers'), findsOneWidget);
      expect(find.text('Find files >100MB'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  group('SnippetsScreen with AI tab', () {
    testWidgets('switches between Library and AI Assistant tabs', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const SnippetsScreen()));
      await tester.pumpAndSettle();

      // Starts in Library tab
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('AI Assistant'), findsOneWidget);
      expect(find.text('New Snippet'), findsOneWidget);

      // Tap on AI Assistant tab
      await tester.tap(find.text('AI Assistant'));
      await tester.pumpAndSettle();

      // Now in AI chat mode
      expect(find.text('Gemini API Key Required'), findsOneWidget);
    });
  });
}
