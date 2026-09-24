import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:shellit/src/screens/settings/settings_screen.dart';
import 'package:terminal_ui/terminal_ui.dart';

class MockVaultRepository implements IVaultRepository {
  bool _initialized = true;
  bool _unlocked = true;
  String currentMasterPassword = 'CurrentPass123';
  final StreamController<bool> _lockController =
      StreamController<bool>.broadcast();

  @override
  bool get isVaultUnlocked => _unlocked;

  @override
  Stream<bool> watchUnlockStatus() => _lockController.stream;

  @override
  Future<bool> isVaultInitialized() async => _initialized;

  @override
  Future<Result<void, VaultFailure>> initializeVault(
    String masterPassword,
  ) async {
    _initialized = true;
    _unlocked = true;
    currentMasterPassword = masterPassword;
    _lockController.add(true);
    return const Result.success(null);
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithPassword(
    String masterPassword,
  ) async {
    if (masterPassword == currentMasterPassword) {
      _unlocked = true;
      _lockController.add(true);
      return const Result.success(null);
    }
    return Result.error(VaultFailure.invalidMasterPassword());
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithBiometrics() async =>
      const Result.success(null);

  @override
  Future<Result<void, VaultFailure>> unlockWithPin(String pin) async =>
      const Result.success(null);

  @override
  void lock() {
    _unlocked = false;
    _lockController.add(false);
  }

  @override
  Future<Result<void, VaultFailure>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword != currentMasterPassword) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }
    currentMasterPassword = newPassword;
    _unlocked = true;
    _lockController.add(true);
    return const Result.success(null);
  }

  @override
  Future<Result<void, VaultFailure>> disableMasterPassword({
    required String currentPassword,
  }) async {
    if (currentPassword != currentMasterPassword) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }
    _initialized = false;
    _unlocked = true;
    _lockController.add(true);
    return const Result.success(null);
  }

  @override
  Future<void> ensureOpenSession() async {}

  final Map<String, String> _metadata = {};

  @override
  Future<String?> getMetadata(String key) async => _metadata[key];

  @override
  Future<void> setMetadata(String key, String value) async {
    _metadata[key] = value;
  }

  @override
  Future<void> deleteMetadata(String key) async {
    _metadata.remove(key);
  }

  @override
  Future<VaultSettingsEntity> getSettings() async =>
      const VaultSettingsEntity();

  @override
  Future<Result<void, VaultFailure>> updateSettings(
    VaultSettingsEntity settings,
  ) async => const Result.success(null);
}

void main() {
  group('SettingsScreen Master Password Tests', () {
    late MockVaultRepository mockVaultRepo;

    setUp(() {
      mockVaultRepo = MockVaultRepository();
    });

    Widget createSettingsScreen() {
      return ProviderScope(
        overrides: [
          vaultRepositoryProvider.overrideWithValue(mockVaultRepo),
          appVaultRepositoryProvider.overrideWithValue(mockVaultRepo),
        ],
        child: const MaterialApp(home: SettingsScreen()),
      );
    }

    testWidgets('Renders Change Master Password tile and opens dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createSettingsScreen());
      await tester.pumpAndSettle();

      expect(find.text('Change Master Password'), findsOneWidget);
      await tester.tap(find.text('Change Master Password'));
      await tester.pumpAndSettle();

      expect(find.text('Current Master Password'), findsOneWidget);
      expect(find.text('New Master Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);
      expect(find.text('Update Password'), findsOneWidget);
    });

    testWidgets('Validates mismatched and empty passwords in dialog', (
      tester,
    ) async {
      await tester.pumpWidget(createSettingsScreen());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Change Master Password'));
      await tester.pumpAndSettle();

      // Tap update without filling
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please enter your current master password.'),
        findsOneWidget,
      );

      // Enter current password but leave new empty
      await tester.enterText(
        find.widgetWithText(TextField, 'Current Master Password'),
        'CurrentPass123',
      );
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Please enter the new master password.'),
        findsOneWidget,
      );

      // Enter short new password (< 6 chars)
      await tester.enterText(
        find.widgetWithText(TextField, 'New Master Password'),
        '123',
      );
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(
        find.text('Master password must be at least 6 characters.'),
        findsOneWidget,
      );

      // Enter matching new but leave confirm mismatched
      await tester.enterText(
        find.widgetWithText(TextField, 'New Master Password'),
        'NewStrongPass456',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Confirm New Password'),
        'DifferentPass789',
      );
      await tester.tap(find.text('Update Password'));
      await tester.pumpAndSettle();
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets(
      'Rejects wrong current password and updates master password when correct',
      (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pumpAndSettle();

        await tester.tap(find.text('Change Master Password'));
        await tester.pumpAndSettle();

        // Enter incorrect current password
        await tester.enterText(
          find.widgetWithText(TextField, 'Current Master Password'),
          'WrongOldPass',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'New Master Password'),
          'NewStrongPass456',
        );
        await tester.enterText(
          find.widgetWithText(TextField, 'Confirm New Password'),
          'NewStrongPass456',
        );

        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        // Should show error from repository
        expect(
          find.text(VaultFailure.invalidMasterPassword().message),
          findsOneWidget,
        );
        expect(mockVaultRepo.currentMasterPassword, 'CurrentPass123');

        // Now enter correct current password
        await tester.enterText(
          find.widgetWithText(TextField, 'Current Master Password'),
          'CurrentPass123',
        );
        await tester.tap(find.text('Update Password'));
        await tester.pumpAndSettle();

        // Dialog should close and SnackBar appear
        expect(find.text('Current Master Password'), findsNothing);
        expect(
          find.text('Master password updated and database re-keyed.'),
          findsOneWidget,
        );
        expect(mockVaultRepo.currentMasterPassword, 'NewStrongPass456');
      },
    );

    testWidgets(
      'Disabling master password prompts for confirmation and updates state',
      (tester) async {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Disable Master Password'), findsOneWidget);
        await tester.tap(find.text('Disable Master Password'));
        await tester.pumpAndSettle();

        expect(find.text('Disable Master Password?'), findsOneWidget);

        // Enter wrong password
        await tester.enterText(
          find.widgetWithText(TextField, 'Current Master Password'),
          'WrongPassword',
        );
        await tester.tap(find.text('Disable Password'));
        await tester.pumpAndSettle();

        expect(
          find.text(VaultFailure.invalidMasterPassword().message),
          findsOneWidget,
        );
        expect(await mockVaultRepo.isVaultInitialized(), true);

        // Enter correct password
        await tester.enterText(
          find.widgetWithText(TextField, 'Current Master Password'),
          'CurrentPass123',
        );
        await tester.tap(find.text('Disable Password'));
        await tester.pumpAndSettle();

        expect(find.text('Disable Master Password?'), findsNothing);
        expect(
          find.text(
            'Master password successfully disabled. Vault remains open.',
          ),
          findsOneWidget,
        );
        expect(await mockVaultRepo.isVaultInitialized(), false);
      },
    );

    testWidgets('Renders Workspace & Sessions settings card on desktop', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      try {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Restore Open Tabs on Startup'), findsOneWidget);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    testWidgets('Hides Workspace & Sessions settings card on mobile', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      try {
        await tester.pumpWidget(createSettingsScreen());
        await tester.pumpAndSettle();

        expect(find.text('Restore Open Tabs on Startup'), findsNothing);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  });
}
