import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:shellit/src/screens/settings/terminal_settings_card.dart';
import 'package:terminal_ui/terminal_ui.dart';

class _FakeVaultRepository implements IVaultRepository {
  VaultSettingsEntity settings = const VaultSettingsEntity(
    multilinePasteDefense: true,
    enableClickableLinks: true,
  );

  @override
  Future<VaultSettingsEntity> getSettings() async => settings;

  @override
  Future<Result<void, VaultFailure>> updateSettings(
    VaultSettingsEntity newSettings,
  ) async {
    settings = newSettings;
    return const Result.success(null);
  }

  @override
  bool get isVaultUnlocked => true;

  @override
  Stream<bool> watchUnlockStatus() => Stream.value(true);

  @override
  Future<bool> isVaultInitialized() async => true;

  @override
  Future<Result<void, VaultFailure>> initializeVault(
    String masterPassword,
  ) async => const Result.success(null);

  @override
  Future<Result<void, VaultFailure>> unlockWithPassword(
    String masterPassword,
  ) async => const Result.success(null);

  @override
  Future<Result<void, VaultFailure>> unlockWithBiometrics() async =>
      const Result.success(null);

  @override
  Future<Result<void, VaultFailure>> unlockWithPin(String pin) async =>
      const Result.success(null);

  @override
  void lock() {}

  @override
  Future<Result<void, VaultFailure>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async => const Result.success(null);

  @override
  Future<Result<void, VaultFailure>> disableMasterPassword({
    required String currentPassword,
  }) async => const Result.success(null);

  @override
  Future<void> ensureOpenSession() async {}

  @override
  Future<String?> getMetadata(String key) async => null;

  @override
  Future<void> setMetadata(String key, String value) async {}

  @override
  Future<void> deleteMetadata(String key) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TerminalSettingsCard loads settings and toggles switches', (
    tester,
  ) async {
    final fakeRepo = _FakeVaultRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appVaultRepositoryProvider.overrideWithValue(fakeRepo)],
        child: MaterialApp(
          theme: ShellitTheme.obsidianDarkTheme,
          home: const Scaffold(body: TerminalSettingsCard()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify titles exist
    expect(find.text('Multiline Paste Defense'), findsOneWidget);
    expect(find.text('Clickable Links & File Paths'), findsOneWidget);

    // Verify switches are initially ON
    final switches = find.byType(Switch);
    expect(switches, findsNWidgets(2));

    final firstSwitch = tester.widget<Switch>(switches.at(0));
    expect(firstSwitch.value, isTrue);

    // Toggle Multiline Paste Defense switch
    await tester.tap(switches.at(0));
    await tester.pumpAndSettle();

    expect(fakeRepo.settings.multilinePasteDefense, isFalse);

    // Toggle Clickable Links switch
    await tester.tap(switches.at(1));
    await tester.pumpAndSettle();

    expect(fakeRepo.settings.enableClickableLinks, isFalse);
  });
}
