import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('SafeArchiveExtractor - Zip Slip & Path Traversal Security', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('shellit_zip_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('extracts legitimate archive safely', () {
      final archive = Archive();
      final content = utf8.encode('<h1>Hello Plugin</h1>');
      archive.addFile(ArchiveFile('index.html', content.length, content));
      archive.addFile(ArchiveFile(
          'assets/style.css', 15, utf8.encode('body { color: red }')));

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isSuccess, isTrue);

      final indexFile = File(p.join(tempDir.path, 'index.html'));
      expect(indexFile.existsSync(), isTrue);
      expect(indexFile.readAsStringSync(), '<h1>Hello Plugin</h1>');

      final cssFile = File(p.join(tempDir.path, 'assets', 'style.css'));
      expect(cssFile.existsSync(), isTrue);
    });

    test(
        'detects and blocks relative path traversal Zip Slip (Unix style: ../../evil.txt)',
        () {
      final archive = Archive();
      final evilContent = utf8.encode('PWNED');
      archive.addFile(
          ArchiveFile('../../evil_file.txt', evilContent.length, evilContent));

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.zipSlipAttempt);

      // Verify evil file was NOT created outside target dir
      final escapedFile = File(p.join(tempDir.parent.path, 'evil_file.txt'));
      expect(escapedFile.existsSync(), isFalse);
    });

    test('detects and blocks Windows backslash Zip Slip (..\\..\\evil.bat)',
        () {
      final archive = Archive();
      final evilContent = utf8.encode('MALICIOUS');
      archive.addFile(ArchiveFile(
          r'..\..\evil_windows.bat', evilContent.length, evilContent));

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.zipSlipAttempt);
    });

    test('blocks absolute path traversal (/etc/shadow)', () {
      final archive = Archive();
      final content = utf8.encode('ROOT_ESCAPE');
      archive.addFile(ArchiveFile('/etc/shadow', content.length, content));

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.zipSlipAttempt);
    });

    test(
        'blocks Windows drive letter path traversal (C:\\Windows\\System32\\evil.dll)',
        () {
      final archive = Archive();
      final content = utf8.encode('DLL_ESCAPE');
      archive.addFile(ArchiveFile(
          r'C:\Windows\System32\evil.dll', content.length, content));

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.zipSlipAttempt);
    });

    test('blocks null byte path injection', () {
      final archive = Archive();
      final content = utf8.encode('NULL_INJECTION');
      archive.addFile(ArchiveFile(
          'normal.txt\x00../../escaped.txt', content.length, content));

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.type, PluginFailureType.zipSlipAttempt);
    });

    test('blocks archive exceeding max allowed uncompressed size', () {
      final archive = Archive();
      // Exceed max size with fake declared size
      final hugeFile = ArchiveFile('huge.bin', 150 * 1024 * 1024, <int>[]);
      archive.addFile(hugeFile);

      final result = SafeArchiveExtractor.extractArchive(archive, tempDir.path);
      expect(result.isError, isTrue);
      expect(result.failureOrNull?.message,
          contains('exceeds maximum allowed limit'));
    });
  });
}
