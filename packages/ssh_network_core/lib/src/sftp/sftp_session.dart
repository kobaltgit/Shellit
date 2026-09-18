import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';

/// Implementation of [ISftpSession] using dartssh2 [SftpClient].
class SftpSession implements ISftpSession {
  @override
  final String id;

  @override
  final String hostId;

  final SSHClient _client;
  final SftpClient _sftp;
  bool _isClosed = false;

  SftpSession({
    required this.id,
    required this.hostId,
    required SSHClient client,
    required SftpClient sftp,
  })  : _client = client,
        _sftp = sftp;

  @override
  dynamic get underlyingClient => _client;

  @override
  Future<Result<List<SftpItem>, SftpFailure>> listDirectory(
      String remotePath) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure(
          'SFTP сессия закрыта.',
          type: SftpFailureType.unknown,
        ),
      );
    }

    try {
      final names = await _sftp.listdir(remotePath);
      final items = <SftpItem>[];

      for (final item in names) {
        // Exclude self and parent directory pointers
        if (item.filename == '.' || item.filename == '..') {
          continue;
        }

        final fullPath = _joinPath(remotePath, item.filename);
        final isDir = item.attr.isDirectory;
        final size = item.attr.size ?? 0;
        final permissions = item.attr.mode?.value ?? 0;
        final mtime = item.attr.modifyTime;
        final modifiedAt = mtime != null
            ? DateTime.fromMillisecondsSinceEpoch(mtime * 1000)
            : DateTime.now();

        items.add(
          SftpItem(
            path: fullPath,
            name: item.filename,
            isDirectory: isDir,
            sizeBytes: size,
            permissions: permissions,
            modifiedAt: modifiedAt,
          ),
        );
      }

      // Sort: directories first, then alphabetical
      items.sort((a, b) {
        if (a.isDirectory && !b.isDirectory) return -1;
        if (!a.isDirectory && b.isDirectory) return 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });

      return Result.success(items);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, remotePath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка получения списка файлов: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void, SftpFailure>> createDirectory(String remotePath) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure('SFTP сессия закрыта.', type: SftpFailureType.unknown),
      );
    }

    try {
      await _sftp.mkdir(remotePath);
      AppLogger.d('Created remote directory: $remotePath', tag: 'SftpSession');
      return const Result.success(null);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, remotePath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка создания директории: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void, SftpFailure>> deleteFile(String remotePath) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure('SFTP сессия закрыта.', type: SftpFailureType.unknown),
      );
    }

    try {
      await _sftp.remove(remotePath);
      AppLogger.d('Deleted remote file: $remotePath', tag: 'SftpSession');
      return const Result.success(null);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, remotePath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка удаления файла: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void, SftpFailure>> deleteDirectory(
    String remotePath, {
    bool recursive = false,
  }) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure('SFTP сессия закрыта.', type: SftpFailureType.unknown),
      );
    }

    try {
      if (recursive) {
        final listResult = await listDirectory(remotePath);
        if (listResult.isSuccess) {
          final items = listResult.getOrThrow();
          for (final item in items) {
            if (item.isDirectory) {
              final subRes = await deleteDirectory(item.path, recursive: true);
              if (subRes.isError) return subRes;
            } else {
              final delRes = await deleteFile(item.path);
              if (delRes.isError) return delRes;
            }
          }
        }
      }

      await _sftp.rmdir(remotePath);
      AppLogger.d('Deleted remote directory: $remotePath', tag: 'SftpSession');
      return const Result.success(null);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, remotePath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка удаления директории: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void, SftpFailure>> rename(
      String oldPath, String newPath) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure('SFTP сессия закрыта.', type: SftpFailureType.unknown),
      );
    }

    try {
      await _sftp.rename(oldPath, newPath);
      AppLogger.d('Renamed $oldPath -> $newPath', tag: 'SftpSession');
      return const Result.success(null);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, oldPath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка переименования: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void, SftpFailure>> setPermissions(
      String remotePath, int permissions) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure('SFTP сессия закрыта.', type: SftpFailureType.unknown),
      );
    }

    try {
      await _sftp.setStat(
          remotePath, SftpFileAttrs(mode: SftpFileMode.value(permissions)));
      AppLogger.d(
          'Changed permissions for $remotePath -> ${permissions.toRadixString(8)}',
          tag: 'SftpSession');
      return const Result.success(null);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, remotePath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка изменения прав доступа: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Future<Result<void, SftpFailure>> createFile(String remotePath) async {
    if (_isClosed) {
      return const Result.error(
        SftpFailure('SFTP сессия закрыта.', type: SftpFailureType.unknown),
      );
    }

    try {
      final file = await _sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );
      await file.close();
      AppLogger.d('Created remote file: $remotePath', tag: 'SftpSession');
      return const Result.success(null);
    } on SftpStatusError catch (e, stack) {
      return Result.error(_mapSftpStatusError(e, remotePath, stack));
    } catch (e, stack) {
      return Result.error(
        SftpFailure(
          'Ошибка создания файла: $e',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        ),
      );
    }
  }

  @override
  Stream<double> downloadFile({
    required String remotePath,
    required String localPath,
  }) async* {
    if (_isClosed) {
      throw const SftpFailure('SFTP сессия закрыта.',
          type: SftpFailureType.unknown);
    }

    yield 0.0;
    SftpFile? remoteFile;
    IOSink? localSink;

    try {
      final stat = await _sftp.stat(remotePath);
      final totalBytes = stat.size ?? 0;

      final localFile = File(localPath);
      await localFile.parent.create(recursive: true);
      localSink = localFile.openWrite();

      if (totalBytes == 0) {
        await localSink.close();
        yield 1.0;
        return;
      }

      remoteFile = await _sftp.open(remotePath, mode: SftpFileOpenMode.read);
      var bytesDownloaded = 0;

      await for (final chunk in remoteFile.read()) {
        localSink.add(chunk);
        bytesDownloaded += chunk.length;
        final progress = (bytesDownloaded / totalBytes).clamp(0.0, 1.0);
        yield progress;
      }

      await localSink.flush();
      yield 1.0;
    } on SftpStatusError catch (e, stack) {
      throw _mapSftpStatusError(e, remotePath, stack);
    } catch (e) {
      throw SftpFailure.transferAborted(remotePath, e);
    } finally {
      try {
        await localSink?.close();
      } catch (_) {}
      try {
        await remoteFile?.close();
      } catch (_) {}
    }
  }

  @override
  Stream<double> uploadFile({
    required String localPath,
    required String remotePath,
  }) async* {
    if (_isClosed) {
      throw const SftpFailure('SFTP сессия закрыта.',
          type: SftpFailureType.unknown);
    }

    yield 0.0;
    SftpFile? remoteFile;

    try {
      final localFile = File(localPath);
      if (!await localFile.exists()) {
        throw SftpFailure.fileNotFound(localPath);
      }

      final totalBytes = await localFile.length();
      remoteFile = await _sftp.open(
        remotePath,
        mode: SftpFileOpenMode.create |
            SftpFileOpenMode.truncate |
            SftpFileOpenMode.write,
      );

      if (totalBytes == 0) {
        await remoteFile.close();
        yield 1.0;
        return;
      }

      var bytesUploaded = 0;
      await for (final chunk in localFile.openRead()) {
        final chunkBytes = Uint8List.fromList(chunk);
        await remoteFile.writeBytes(chunkBytes, offset: bytesUploaded);
        bytesUploaded += chunkBytes.length;
        final progress = (bytesUploaded / totalBytes).clamp(0.0, 1.0);
        yield progress;
      }

      yield 1.0;
    } on SftpStatusError catch (e, stack) {
      throw _mapSftpStatusError(e, remotePath, stack);
    } catch (e) {
      throw SftpFailure.transferAborted(remotePath, e);
    } finally {
      try {
        await remoteFile?.close();
      } catch (_) {}
    }
  }

  @override
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    try {
      _sftp.close();
    } catch (_) {}

    try {
      _client.close();
    } catch (_) {}

    AppLogger.i('SFTP session $id closed', tag: 'SftpSession');
  }

  String _joinPath(String parent, String child) {
    if (parent.endsWith('/')) {
      return '$parent$child';
    }
    return '$parent/$child';
  }

  SftpFailure _mapSftpStatusError(
    SftpStatusError e,
    String path,
    StackTrace stack,
  ) {
    switch (e.code) {
      case 2: // SSH_FX_NO_SUCH_FILE
        return SftpFailure.fileNotFound(path);
      case 3: // SSH_FX_PERMISSION_DENIED
        return SftpFailure.permissionDenied(path);
      default:
        return SftpFailure(
          'SFTP error (${e.code}): ${e.message}',
          type: SftpFailureType.unknown,
          cause: e,
          stackTrace: stack,
        );
    }
  }
}
