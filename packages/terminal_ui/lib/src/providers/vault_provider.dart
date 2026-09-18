import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State of the Vault.
class VaultState {
  final bool isUnlocked;
  final bool isInitialized;
  final String activeVaultName;
  final int autoLockTimeoutMinutes;
  final String? errorMessage;

  const VaultState({
    this.isUnlocked = true,
    this.isInitialized = true,
    this.activeVaultName = 'Primary Vault',
    this.autoLockTimeoutMinutes = 15,
    this.errorMessage,
  });

  VaultState copyWith({
    bool? isUnlocked,
    bool? isInitialized,
    String? activeVaultName,
    int? autoLockTimeoutMinutes,
    String? errorMessage,
  }) {
    return VaultState(
      isUnlocked: isUnlocked ?? this.isUnlocked,
      isInitialized: isInitialized ?? this.isInitialized,
      activeVaultName: activeVaultName ?? this.activeVaultName,
      autoLockTimeoutMinutes:
          autoLockTimeoutMinutes ?? this.autoLockTimeoutMinutes,
      errorMessage: errorMessage,
    );
  }
}

/// Optional dependency injection for IVaultRepository.
final vaultRepositoryProvider = Provider<IVaultRepository?>((ref) => null);

/// Vault State Notifier managing lock status, switching vaults, and auto-lock.
class VaultNotifier extends StateNotifier<VaultState> {
  final IVaultRepository? _vaultRepository;
  Timer? _autoLockTimer;

  VaultNotifier(this._vaultRepository) : super(const VaultState()) {
    _init();
  }

  Future<void> _init() async {
    if (_vaultRepository != null) {
      await _vaultRepository!.ensureOpenSession();
      final isInitialized = await _vaultRepository!.isVaultInitialized();
      state = state.copyWith(
        isUnlocked: _vaultRepository!.isVaultUnlocked,
        isInitialized: isInitialized,
      );
      _vaultRepository!.watchUnlockStatus().listen((unlocked) {
        state = state.copyWith(isUnlocked: unlocked);
        if (unlocked) {
          _resetAutoLockTimer();
        } else {
          _autoLockTimer?.cancel();
        }
      });
    }
  }

  void _resetAutoLockTimer() {
    _autoLockTimer?.cancel();
    if (state.autoLockTimeoutMinutes > 0 && state.isUnlocked) {
      _autoLockTimer =
          Timer(Duration(minutes: state.autoLockTimeoutMinutes), () {
        lock();
      });
    }
  }

  void recordUserActivity() {
    if (state.isUnlocked) {
      _resetAutoLockTimer();
    }
  }

  Future<bool> unlockWithPassword(String password) async {
    if (_vaultRepository != null) {
      final res = await _vaultRepository!.unlockWithPassword(password);
      return res.when(
        success: (_) {
          state = state.copyWith(isUnlocked: true, errorMessage: null);
          _resetAutoLockTimer();
          return true;
        },
        error: (err) {
          state = state.copyWith(errorMessage: err.message);
          return false;
        },
      );
    } else {
      // In-memory mode
      state = state.copyWith(isUnlocked: true, errorMessage: null);
      _resetAutoLockTimer();
      return true;
    }
  }

  Future<bool> initializeVault(String password) async {
    if (_vaultRepository != null) {
      final res = await _vaultRepository!.initializeVault(password);
      return res.when(
        success: (_) {
          state = state.copyWith(
              isUnlocked: true, isInitialized: true, errorMessage: null);
          _resetAutoLockTimer();
          return true;
        },
        error: (err) {
          state = state.copyWith(errorMessage: err.message);
          return false;
        },
      );
    } else {
      state = state.copyWith(
          isUnlocked: true, isInitialized: true, errorMessage: null);
      _resetAutoLockTimer();
      return true;
    }
  }

  Future<Result<void, VaultFailure>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (_vaultRepository != null) {
      final res = await _vaultRepository!.changeMasterPassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return res.when(
        success: (_) {
          state = state.copyWith(
            isUnlocked: true,
            isInitialized: true,
            errorMessage: null,
          );
          _resetAutoLockTimer();
          return const Result.success(null);
        },
        error: (err) {
          state = state.copyWith(errorMessage: err.message);
          return Result.error(err);
        },
      );
    } else {
      state = state.copyWith(
        isUnlocked: true,
        isInitialized: true,
        errorMessage: null,
      );
      _resetAutoLockTimer();
      return const Result.success(null);
    }
  }

  Future<Result<void, VaultFailure>> disableMasterPassword({
    required String currentPassword,
  }) async {
    if (_vaultRepository != null) {
      final res = await _vaultRepository!.disableMasterPassword(
        currentPassword: currentPassword,
      );
      return res.when(
        success: (_) {
          _autoLockTimer?.cancel();
          _autoLockTimer = null;
          state = state.copyWith(
            isUnlocked: true,
            isInitialized: false,
            errorMessage: null,
            autoLockTimeoutMinutes: 0,
          );
          return const Result.success(null);
        },
        error: (err) {
          state = state.copyWith(errorMessage: err.message);
          return Result.error(err);
        },
      );
    } else {
      _autoLockTimer?.cancel();
      _autoLockTimer = null;
      state = state.copyWith(
        isUnlocked: true,
        isInitialized: false,
        errorMessage: null,
        autoLockTimeoutMinutes: 0,
      );
      return const Result.success(null);
    }
  }

  void lock() {
    _autoLockTimer?.cancel();
    _vaultRepository?.lock();
    state = state.copyWith(isUnlocked: false);
  }

  void selectVault(String vaultName) {
    state = state.copyWith(activeVaultName: vaultName);
  }

  void setAutoLockTimeout(int minutes) {
    state = state.copyWith(autoLockTimeoutMinutes: minutes);
    _resetAutoLockTimer();
  }

  @override
  void dispose() {
    _autoLockTimer?.cancel();
    super.dispose();
  }
}

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultState>((ref) {
  final repo = ref.watch(vaultRepositoryProvider);
  return VaultNotifier(repo);
});
