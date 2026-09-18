import 'dart:async';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Manages rotating log files on disk (e.g. shellit.log and shellit.1.log)
/// with a 5 MB maximum size per file and sanitization protection.
class FileLogSink {
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5 MB

  String? _logsDirectory;
  bool isEnabled = true;
  LogLevel minLevel = LogLevel.debug;

  StreamSubscription<LogEntry>? _sub;
  IOSink? _currentSink;
  File? _currentFile;
  int _currentFileSize = 0;
  final Completer<void> _initCompleter = Completer<void>();

  String get logDirectoryPath => _logsDirectory ?? '';

  Future<void> init({String? customLogsDir}) async {
    if (_logsDirectory != null) return;

    if (customLogsDir != null) {
      _logsDirectory = customLogsDir;
    } else {
      try {
        final appDir = await getApplicationSupportDirectory();
        _logsDirectory = p.join(appDir.path, 'logs');
      } catch (e) {
        _logsDirectory = p.join(Directory.current.path, '.shellit_logs');
      }
    }

    final dir = Directory(_logsDirectory!);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await _rotateIfNeeded();
    _openSink();

    // Listen to sanitized stream
    _sub = AppLogger.entryStream.listen(_handleLogEntry);

    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
  }

  void _openSink() {
    if (_logsDirectory == null) return;
    final filePath = p.join(_logsDirectory!, 'shellit.log');
    _currentFile = File(filePath);

    if (!_currentFile!.existsSync()) {
      _currentFile!.createSync(recursive: true);
    }
    _currentFileSize = _currentFile!.lengthSync();

    _currentSink = _currentFile!.openWrite(mode: FileMode.append);
  }

  Future<void> _rotateIfNeeded() async {
    if (_logsDirectory == null) return;
    final mainPath = p.join(_logsDirectory!, 'shellit.log');
    final backupPath = p.join(_logsDirectory!, 'shellit.1.log');

    final mainFile = File(mainPath);
    if (await mainFile.exists()) {
      final size = await mainFile.length();
      if (size >= maxFileSizeBytes) {
        if (_currentSink != null) {
          await _currentSink!.flush();
          await _currentSink!.close();
          _currentSink = null;
        }

        final backupFile = File(backupPath);
        if (await backupFile.exists()) {
          await backupFile.delete();
        }

        await mainFile.rename(backupPath);
        _currentFileSize = 0;
      }
    }
  }

  Future<void> _handleLogEntry(LogEntry entry) async {
    if (!isEnabled || entry.level.index < minLevel.index) return;
    if (_currentSink == null) {
      _openSink();
    }

    final line = '${entry.toString()}\n';
    _currentSink?.write(line);
    _currentFileSize += line.length;

    if (_currentFileSize >= maxFileSizeBytes) {
      await _rotateIfNeeded();
      _openSink();
    }
  }

  Future<void> clearLogs() async {
    await _initCompleter.future;
    if (_currentSink != null) {
      await _currentSink!.flush();
      await _currentSink!.close();
      _currentSink = null;
    }

    if (_logsDirectory != null) {
      final dir = Directory(_logsDirectory!);
      if (await dir.exists()) {
        final entities = dir.listSync();
        for (final entity in entities) {
          if (entity is File) {
            try {
              entity.deleteSync();
            } catch (_) {}
          }
        }
      }
    }
    _currentFileSize = 0;
    _openSink();
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    _sub = null;
    if (_currentSink != null) {
      await _currentSink!.flush();
      await _currentSink!.close();
      _currentSink = null;
    }
  }
}
