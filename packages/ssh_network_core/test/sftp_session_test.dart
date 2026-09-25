import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:core_foundation/core_foundation.dart';
import 'package:dartssh2/dartssh2.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

// POSIX mode constants: 0x4000 for directory, 0x8000 for regular file
const _kDirMode = SftpFileMode.value(0x4000 | 0x1ED);
const _kFileMode = SftpFileMode.value(0x8000 | 0x1A4);

class FakeSftpFile implements SftpFile {
  final Uint8List data;
  final List<Uint8List> writtenChunks = [];
  @override
  bool isClosed = false;

  FakeSftpFile({required this.data});

  @override
  Future<SftpFileAttrs> stat() async {
    return SftpFileAttrs(size: data.length, mode: _kFileMode);
  }

  @override
  Stream<Uint8List> read({
    int? length,
    int offset = 0,
    void Function(int bytesRead)? onProgress,
    int chunkSize = 1024,
    int maxPendingRequests = 4,
  }) async* {
    var sent = 0;
    while (sent < data.length) {
      final chunkEnd =
          (sent + chunkSize < data.length) ? sent + chunkSize : data.length;
      final chunk = Uint8List.sublistView(data, sent, chunkEnd);
      sent += chunk.length;
      onProgress?.call(sent);
      yield chunk;
    }
  }

  @override
  Future<Uint8List> readBytes({int? length, int offset = 0}) async {
    return data;
  }

  @override
  Future<void> writeBytes(Uint8List data, {int offset = 0}) async {
    writtenChunks.add(data);
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeSftpClient implements SftpClient {
  final Map<String, List<SftpName>> directories = {};
  final Map<String, Uint8List> files = {};
  final List<String> createdDirs = [];
  final List<String> deletedFiles = [];
  final List<String> deletedDirs = [];
  final Map<String, String> renamedPaths = {};
  final Map<String, SftpFileAttrs> fileStats = {};
  final Map<String, FakeSftpFile> openFiles = {};
  String homePath = '/home/testuser';
  bool isClosed = false;

  @override
  Future<String> absolute(String path) async {
    return homePath;
  }

  @override
  Future<void> setStat(String path, SftpFileAttrs attrs) async {
    fileStats[path] = attrs;
  }

  @override
  Future<List<SftpName>> listdir(String path) async {
    if (directories.containsKey(path)) {
      return directories[path]!;
    }
    throw SftpStatusError(2, 'File not found');
  }

  @override
  Future<SftpFileAttrs> stat(String path, {bool followLink = true}) async {
    if (files.containsKey(path)) {
      return SftpFileAttrs(size: files[path]!.length, mode: _kFileMode);
    }
    if (directories.containsKey(path)) {
      return SftpFileAttrs(mode: _kDirMode);
    }
    throw SftpStatusError(2, 'File not found');
  }

  @override
  Future<void> mkdir(String path, [SftpFileAttrs? attrs]) async {
    createdDirs.add(path);
  }

  @override
  Future<void> remove(String path) async {
    deletedFiles.add(path);
  }

  @override
  Future<void> rmdir(String path) async {
    deletedDirs.add(path);
  }

  @override
  Future<void> rename(String oldPath, String newPath) async {
    renamedPaths[oldPath] = newPath;
  }

  @override
  Future<SftpFile> open(
    String path, {
    SftpFileOpenMode mode = SftpFileOpenMode.read,
  }) async {
    final file = files.containsKey(path)
        ? FakeSftpFile(data: files[path]!)
        : FakeSftpFile(data: Uint8List(0));
    openFiles[path] = file;
    return file;
  }

  @override
  Future<void> close() async {
    isClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class DummySshClient implements SSHClient {
  @override
  bool isClosed = false;

  @override
  void close() {
    isClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('SftpSession Two-Pane & File Management Tests', () {
    late FakeSftpClient fakeSftp;
    late DummySshClient dummySsh;
    late SftpSession session;
    late Directory tempDir;

    setUp(() async {
      fakeSftp = FakeSftpClient();
      dummySsh = DummySshClient();
      session = SftpSession(
        id: 'sftp_123',
        hostId: 'host_456',
        client: dummySsh,
        sftp: fakeSftp,
      );
      tempDir = await Directory.systemTemp.createTemp('sftp_test_');
    });

    tearDown(() async {
      await session.close();
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('listDirectory parses items, filters . and .., and sorts dirs first',
        () async {
      fakeSftp.directories['/home/user'] = [
        SftpName(
          filename: '.',
          longname: 'drwxr-xr-x',
          attr: SftpFileAttrs(mode: _kDirMode),
        ),
        SftpName(
          filename: '..',
          longname: 'drwxr-xr-x',
          attr: SftpFileAttrs(mode: _kDirMode),
        ),
        SftpName(
          filename: 'zebra.txt',
          longname: '-rw-r--r--',
          attr: SftpFileAttrs(size: 200, mode: _kFileMode),
        ),
        SftpName(
          filename: 'docs',
          longname: 'drwxr-xr-x',
          attr: SftpFileAttrs(mode: _kDirMode),
        ),
        SftpName(
          filename: 'apple.txt',
          longname: '-rw-r--r--',
          attr: SftpFileAttrs(size: 100, mode: _kFileMode),
        ),
      ];

      final res = await session.listDirectory('/home/user');
      expect(res.isSuccess, isTrue);

      final items = res.getOrThrow();
      expect(items.length, equals(3));

      // Docs (directory) must come first
      expect(items[0].name, equals('docs'));
      expect(items[0].isDirectory, isTrue);
      expect(items[0].path, equals('/home/user/docs'));

      // Files sorted alphabetically next
      expect(items[1].name, equals('apple.txt'));
      expect(items[1].isDirectory, isFalse);
      expect(items[1].sizeBytes, equals(100));

      expect(items[2].name, equals('zebra.txt'));
      expect(items[2].isDirectory, isFalse);
      expect(items[2].sizeBytes, equals(200));
    });

    test('listDirectory maps status 2 to fileNotFound failure', () async {
      final res = await session.listDirectory('/nonexistent');
      expect(res.isError, isTrue);
      expect(res.failureOrNull?.type, equals(SftpFailureType.fileNotFound));
    });

    test('createDirectory, deleteFile, and rename execute successfully',
        () async {
      final mkdirRes = await session.createDirectory('/var/log/app');
      expect(mkdirRes.isSuccess, isTrue);
      expect(fakeSftp.createdDirs, contains('/var/log/app'));

      final delRes = await session.deleteFile('/var/log/app/old.log');
      expect(delRes.isSuccess, isTrue);
      expect(fakeSftp.deletedFiles, contains('/var/log/app/old.log'));

      final renameRes =
          await session.rename('/var/log/app/a.log', '/var/log/app/b.log');
      expect(renameRes.isSuccess, isTrue);
      expect(fakeSftp.renamedPaths['/var/log/app/a.log'],
          equals('/var/log/app/b.log'));
    });

    test('deleteDirectory without recursive removes only target dir', () async {
      final res = await session.deleteDirectory('/var/empty_dir');
      expect(res.isSuccess, isTrue);
      expect(fakeSftp.deletedDirs, contains('/var/empty_dir'));
    });

    test('deleteDirectory with recursive removes sub-items and dir', () async {
      fakeSftp.directories['/var/parent'] = [
        SftpName(
          filename: 'file1.txt',
          longname: '',
          attr: SftpFileAttrs(mode: _kFileMode),
        ),
      ];

      final res = await session.deleteDirectory('/var/parent', recursive: true);
      expect(res.isSuccess, isTrue);
      expect(fakeSftp.deletedFiles, contains('/var/parent/file1.txt'));
      expect(fakeSftp.deletedDirs, contains('/var/parent'));
    });

    test('downloadFile streams progress and writes to local disk', () async {
      final content = Uint8List.fromList(List.generate(2048, (i) => i % 256));
      fakeSftp.files['/remote/data.bin'] = content;

      final localTarget = '${tempDir.path}/downloaded.bin';
      final progressValues = <double>[];

      await for (final p in session.downloadFile(
        remotePath: '/remote/data.bin',
        localPath: localTarget,
      )) {
        progressValues.add(p);
      }

      expect(progressValues.first, equals(0.0));
      expect(progressValues.last, equals(1.0));

      final downloadedFile = File(localTarget);
      expect(await downloadedFile.exists(), isTrue);
      expect(await downloadedFile.length(), equals(2048));
    });

    test('uploadFile streams progress and writes to remote', () async {
      final localFile = File('${tempDir.path}/local_upload.bin');
      final content =
          Uint8List.fromList(List.generate(4096, (i) => (i * 3) % 256));
      await localFile.writeAsBytes(content);

      final progressValues = <double>[];
      await for (final p in session.uploadFile(
        localPath: localFile.path,
        remotePath: '/remote/upload.bin',
      )) {
        progressValues.add(p);
      }

      expect(progressValues.first, equals(0.0));
      expect(progressValues.last, equals(1.0));
    });

    test('uploadFile throws fileNotFound when local file does not exist',
        () async {
      expect(
        () async {
          await for (final _ in session.uploadFile(
            localPath: '/non/existent/local.file',
            remotePath: '/remote/target',
          )) {}
        },
        throwsA(isA<SftpFailure>()),
      );
    });

    test('setPermissions sets mode correctly on remote item', () async {
      final res =
          await session.setPermissions('/remote/script.sh', 0x1ED); // 0755
      expect(res.isSuccess, isTrue);
      expect(
          fakeSftp.fileStats['/remote/script.sh']?.mode?.value, equals(0x1ED));
    });

    test('createFile opens remote file with create mode and succeeds',
        () async {
      final res = await session.createFile('/remote/newfile.txt');
      expect(res.isSuccess, isTrue);
    });

    test('getDefaultPath returns resolved home directory', () async {
      final res = await session.getDefaultPath();
      expect(res.isSuccess, isTrue);
      expect(res.valueOrNull, equals('/home/testuser'));
    });

    test('readFile reads full remote file bytes into memory', () async {
      fakeSftp.files['/remote/app.conf'] =
          Uint8List.fromList('server_name test;'.codeUnits);
      final res = await session.readFile('/remote/app.conf');
      expect(res.isSuccess, isTrue);
      expect(
          String.fromCharCodes(res.valueOrNull!), equals('server_name test;'));
    });

    test('writeFile writes bytes to remote file via open and writeBytes',
        () async {
      final data = Uint8List.fromList('updated_content'.codeUnits);
      final res = await session.writeFile('/remote/output.log', data);
      expect(res.isSuccess, isTrue);
      final written = fakeSftp.openFiles['/remote/output.log']?.writtenChunks;
      expect(written, isNotNull);
      expect(written!.first, equals(data));
    });

    test('close closes SFTP and SSHClient and blocks subsequent requests',
        () async {
      await session.close();
      expect(fakeSftp.isClosed, isTrue);
      expect(dummySsh.isClosed, isTrue);

      final res = await session.listDirectory('/any');
      expect(res.isError, isTrue);
      expect(res.failureOrNull?.message, contains('closed'));
    });
  });
}
