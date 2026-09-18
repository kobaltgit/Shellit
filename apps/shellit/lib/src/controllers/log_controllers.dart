import 'dart:async';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/logging/file_log_sink.dart';
import '../services/logging/session_storage_service.dart';

/// Single global instance of FileLogSink
final fileLogSinkProvider = Provider<FileLogSink>((ref) {
  final sink = FileLogSink();
  sink.init();
  ref.onDispose(() => sink.dispose());
  return sink;
});

/// Single global instance of SessionStorageService
final sessionStorageServiceProvider = Provider<SessionStorageService>((ref) {
  final service = SessionStorageService();
  service.init();
  return service;
});

// ==========================================
// System Logs State & Controller
// ==========================================

class SystemLogsState {
  final List<LogEntry> allEntries;
  final LogLevel? filterLevel;
  final String searchQuery;
  final String? selectedTag;
  final bool isPaused;
  final bool autoScroll;

  const SystemLogsState({
    this.allEntries = const [],
    this.filterLevel,
    this.searchQuery = '',
    this.selectedTag,
    this.isPaused = false,
    this.autoScroll = true,
  });

  List<String> get availableTags {
    final tags = <String>{};
    for (final e in allEntries) {
      if (e.tag.isNotEmpty) tags.add(e.tag);
    }
    return tags.toList()..sort();
  }

  List<LogEntry> get filteredEntries {
    return allEntries.where((entry) {
      if (filterLevel != null && entry.level != filterLevel) {
        return false;
      }
      if (selectedTag != null &&
          selectedTag!.isNotEmpty &&
          entry.tag != selectedTag) {
        return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchesMessage = entry.message.toLowerCase().contains(q);
        final matchesTag = entry.tag.toLowerCase().contains(q);
        final matchesError =
            entry.error != null &&
            entry.error.toString().toLowerCase().contains(q);
        if (!matchesMessage && !matchesTag && !matchesError) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  SystemLogsState copyWith({
    List<LogEntry>? allEntries,
    LogLevel? filterLevel,
    bool clearFilterLevel = false,
    String? searchQuery,
    String? selectedTag,
    bool clearSelectedTag = false,
    bool? isPaused,
    bool? autoScroll,
  }) {
    return SystemLogsState(
      allEntries: allEntries ?? this.allEntries,
      filterLevel: clearFilterLevel ? null : (filterLevel ?? this.filterLevel),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedTag: clearSelectedTag ? null : (selectedTag ?? this.selectedTag),
      isPaused: isPaused ?? this.isPaused,
      autoScroll: autoScroll ?? this.autoScroll,
    );
  }
}

class SystemLogsController extends StateNotifier<SystemLogsState> {
  static const int maxBufferSize = 1500;
  StreamSubscription<LogEntry>? _streamSub;

  SystemLogsController() : super(const SystemLogsState()) {
    _streamSub = AppLogger.entryStream.listen(_onNewLogEntry);
  }

  void _onNewLogEntry(LogEntry entry) {
    if (state.isPaused) return;

    final updated = List<LogEntry>.from(state.allEntries)..add(entry);
    if (updated.length > maxBufferSize) {
      updated.removeRange(0, updated.length - maxBufferSize);
    }

    state = state.copyWith(allEntries: updated);
  }

  void setFilterLevel(LogLevel? level) {
    state = state.copyWith(filterLevel: level, clearFilterLevel: level == null);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void setSelectedTag(String? tag) {
    state = state.copyWith(
      selectedTag: tag,
      clearSelectedTag: tag == null || tag.isEmpty,
    );
  }

  void togglePause() {
    state = state.copyWith(isPaused: !state.isPaused);
  }

  void toggleAutoScroll() {
    state = state.copyWith(autoScroll: !state.autoScroll);
  }

  void clear() {
    state = state.copyWith(allEntries: const []);
  }

  String exportLogsText() {
    final buffer = StringBuffer();
    buffer.writeln('=== Shellit Exported System Logs ===');
    buffer.writeln('Exported at: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total Entries: ${state.filteredEntries.length}');
    buffer.writeln('====================================\n');
    for (final entry in state.filteredEntries) {
      buffer.writeln(entry.toString());
      if (entry.stackTrace != null) {
        buffer.writeln(entry.stackTrace.toString());
      }
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}

final systemLogsControllerProvider =
    StateNotifierProvider<SystemLogsController, SystemLogsState>((ref) {
      return SystemLogsController();
    });

// ==========================================
// Session Recordings State & Controller
// ==========================================

class SessionRecordingsState {
  final bool isLoading;
  final List<SessionRecordingEntity> recordings;
  final SessionRecordingEntity? selectedRecording;
  final String? activePreviewText;
  final String searchQuery;

  const SessionRecordingsState({
    this.isLoading = false,
    this.recordings = const [],
    this.selectedRecording,
    this.activePreviewText,
    this.searchQuery = '',
  });

  List<SessionRecordingEntity> get filteredRecordings {
    if (searchQuery.isEmpty) return recordings;
    final q = searchQuery.toLowerCase();
    return recordings.where((r) {
      return r.hostLabel.toLowerCase().contains(q) ||
          r.username.toLowerCase().contains(q) ||
          r.environment.name.toLowerCase().contains(q);
    }).toList();
  }

  SessionRecordingsState copyWith({
    bool? isLoading,
    List<SessionRecordingEntity>? recordings,
    SessionRecordingEntity? selectedRecording,
    bool clearSelectedRecording = false,
    String? activePreviewText,
    bool clearActivePreviewText = false,
    String? searchQuery,
  }) {
    return SessionRecordingsState(
      isLoading: isLoading ?? this.isLoading,
      recordings: recordings ?? this.recordings,
      selectedRecording: clearSelectedRecording
          ? null
          : (selectedRecording ?? this.selectedRecording),
      activePreviewText: clearActivePreviewText
          ? null
          : (activePreviewText ?? this.activePreviewText),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class SessionRecordingsController
    extends StateNotifier<SessionRecordingsState> {
  final SessionStorageService _storageService;

  SessionRecordingsController(this._storageService)
    : super(const SessionRecordingsState()) {
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    final list = await _storageService.loadRecordings();
    state = state.copyWith(isLoading: false, recordings: list);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> selectRecording(SessionRecordingEntity? recording) async {
    if (recording == null) {
      state = state.copyWith(
        clearSelectedRecording: true,
        clearActivePreviewText: true,
      );
      return;
    }

    state = state.copyWith(selectedRecording: recording, isLoading: true);

    final text = await _storageService.readTextLog(recording.logFilePath);
    state = state.copyWith(isLoading: false, activePreviewText: text);
  }

  Future<void> deleteRecording(String id) async {
    await _storageService.deleteRecording(id);
    if (state.selectedRecording?.id == id) {
      state = state.copyWith(
        clearSelectedRecording: true,
        clearActivePreviewText: true,
      );
    }
    await refresh();
  }
}

final sessionRecordingsControllerProvider =
    StateNotifierProvider<SessionRecordingsController, SessionRecordingsState>((
      ref,
    ) {
      final storage = ref.watch(sessionStorageServiceProvider);
      return SessionRecordingsController(storage);
    });

// ==========================================
// Log Settings State & Controller
// ==========================================

class LogSettingsState {
  final bool isFileLoggingEnabled;
  final LogLevel minFileLogLevel;
  final String logsDirectory;

  const LogSettingsState({
    required this.isFileLoggingEnabled,
    required this.minFileLogLevel,
    required this.logsDirectory,
  });

  LogSettingsState copyWith({
    bool? isFileLoggingEnabled,
    LogLevel? minFileLogLevel,
    String? logsDirectory,
  }) {
    return LogSettingsState(
      isFileLoggingEnabled: isFileLoggingEnabled ?? this.isFileLoggingEnabled,
      minFileLogLevel: minFileLogLevel ?? this.minFileLogLevel,
      logsDirectory: logsDirectory ?? this.logsDirectory,
    );
  }
}

class LogSettingsController extends StateNotifier<LogSettingsState> {
  final FileLogSink _sink;

  LogSettingsController(this._sink)
    : super(
        LogSettingsState(
          isFileLoggingEnabled: _sink.isEnabled,
          minFileLogLevel: _sink.minLevel,
          logsDirectory: _sink.logDirectoryPath,
        ),
      );

  void setFileLoggingEnabled(bool enabled) {
    _sink.isEnabled = enabled;
    state = state.copyWith(isFileLoggingEnabled: enabled);
  }

  void setMinFileLogLevel(LogLevel level) {
    _sink.minLevel = level;
    state = state.copyWith(minFileLogLevel: level);
  }

  Future<void> clearDiskLogs() async {
    await _sink.clearLogs();
  }

  Future<void> openLogsFolder() async {
    final dir = _sink.logDirectoryPath;
    if (dir.isEmpty) return;

    if (Platform.isWindows) {
      await Process.run('explorer.exe', [dir]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [dir]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [dir]);
    }
  }
}

final logSettingsControllerProvider =
    StateNotifierProvider<LogSettingsController, LogSettingsState>((ref) {
      final sink = ref.watch(fileLogSinkProvider);
      return LogSettingsController(sink);
    });
