import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/local_shell_detector.dart';

/// State of detected and configured local shells.
class LocalShellsState {
  final List<LocalShellProfile> profiles;
  final bool isLoading;

  const LocalShellsState({
    this.profiles = const [],
    this.isLoading = false,
  });

  LocalShellProfile? get defaultProfile {
    try {
      return profiles.firstWhere((p) => p.isDefault);
    } catch (_) {
      return profiles.isNotEmpty ? profiles.first : null;
    }
  }

  LocalShellsState copyWith({
    List<LocalShellProfile>? profiles,
    bool? isLoading,
  }) {
    return LocalShellsState(
      profiles: profiles ?? this.profiles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Notifier managing discovery and default selection of local shells.
class LocalShellsNotifier extends StateNotifier<LocalShellsState> {
  final LocalShellDetector _detector;
  String? _preferredDefaultId;

  LocalShellsNotifier(
      {LocalShellDetector detector = const LocalShellDetector()})
      : _detector = detector,
        super(const LocalShellsState(isLoading: true)) {
    loadShells();
  }

  Future<void> loadShells() async {
    state = state.copyWith(isLoading: true);
    final detected = await _detector.detectAvailableShells(
      preferredDefaultId: _preferredDefaultId,
    );
    state = LocalShellsState(profiles: detected, isLoading: false);
  }

  void setDefaultShell(String profileId) {
    _preferredDefaultId = profileId;
    final updated = state.profiles.map((p) {
      return p.copyWith(isDefault: p.id == profileId);
    }).toList();
    state = state.copyWith(profiles: updated);
  }
}

/// Provider of local shell profiles.
final localShellsProvider =
    StateNotifierProvider<LocalShellsNotifier, LocalShellsState>((ref) {
  return LocalShellsNotifier();
});
