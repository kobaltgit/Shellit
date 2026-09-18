import 'package:flutter_riverpod/flutter_riverpod.dart';

enum SessionRecordingMode {
  prodOnly, // Only record PROD hosts automatically
  all, // Record all hosts automatically
  manual, // Only when REC button is clicked manually
}

class RecordingSettingsNotifier extends StateNotifier<SessionRecordingMode> {
  RecordingSettingsNotifier() : super(SessionRecordingMode.prodOnly);

  void setMode(SessionRecordingMode mode) {
    state = mode;
  }
}

final sessionRecordingModeProvider =
    StateNotifierProvider<RecordingSettingsNotifier, SessionRecordingMode>((
      ref,
    ) {
      return RecordingSettingsNotifier();
    });
