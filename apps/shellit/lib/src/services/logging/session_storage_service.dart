import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Storage service for persisting and indexing session recordings (.cast and .log).
class SessionStorageService {
  String? _recordingsDirectory;
  final Completer<void> _initCompleter = Completer<void>();

  String get recordingsDirectoryPath => _recordingsDirectory ?? '';

  Future<void> init({String? customDir}) async {
    if (_recordingsDirectory != null) return;

    if (customDir != null) {
      _recordingsDirectory = customDir;
    } else {
      try {
        final appDir = await getApplicationSupportDirectory();
        _recordingsDirectory = p.join(appDir.path, 'recordings');
      } catch (_) {
        _recordingsDirectory = p.join(
          Directory.current.path,
          '.shellit_recordings',
        );
      }
    }

    final dir = Directory(_recordingsDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  File _getIndexFile() {
    return File(p.join(_recordingsDirectory!, 'index.json'));
  }

  Future<List<SessionRecordingEntity>> loadRecordings() async {
    await _initCompleter.future;
    final indexFile = _getIndexFile();
    if (!await indexFile.exists()) {
      return [];
    }

    try {
      final content = await indexFile.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      return list
          .map(
            (item) =>
                SessionRecordingEntity.fromJson(item as Map<String, dynamic>),
          )
          .toList()
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    } catch (e) {
      AppLogger.w(
        'Failed to read session recordings index: $e',
        tag: 'SessionStorageService',
      );
      return [];
    }
  }

  Future<void> saveRecording(SessionRecordingEntity entity) async {
    await _initCompleter.future;
    final current = await loadRecordings();
    final index = current.indexWhere((e) => e.id == entity.id);
    if (index >= 0) {
      current[index] = entity;
    } else {
      current.insert(0, entity);
    }

    final indexFile = _getIndexFile();
    final encoded = jsonEncode(current.map((e) => e.toJson()).toList());
    await indexFile.writeAsString(encoded, flush: true);
  }

  Future<void> deleteRecording(String id) async {
    await _initCompleter.future;
    final current = await loadRecordings();
    final match = current.where((e) => e.id == id).toList();
    if (match.isEmpty) return;

    final target = match.first;

    // Remove physical files
    if (target.castFilePath.isNotEmpty) {
      final castFile = File(target.castFilePath);
      if (await castFile.exists()) {
        await castFile.delete();
      }
    }
    if (target.logFilePath.isNotEmpty) {
      final logFile = File(target.logFilePath);
      if (await logFile.exists()) {
        await logFile.delete();
      }
    }

    current.removeWhere((e) => e.id == id);
    final indexFile = _getIndexFile();
    await indexFile.writeAsString(
      jsonEncode(current.map((e) => e.toJson()).toList()),
      flush: true,
    );
  }

  Future<String> readTextLog(String logFilePath) async {
    final file = File(logFilePath);
    if (!await file.exists()) {
      return 'Log file not found: $logFilePath';
    }
    return file.readAsString();
  }

  Future<String> readCastFile(String castFilePath) async {
    final file = File(castFilePath);
    if (!await file.exists()) {
      return '';
    }
    return file.readAsString();
  }
}
