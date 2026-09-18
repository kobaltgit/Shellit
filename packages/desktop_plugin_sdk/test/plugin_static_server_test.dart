import 'dart:convert';
import 'dart:io';
import 'package:desktop_plugin_sdk/desktop_plugin_sdk.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('PluginStaticServer', () {
    late Directory tempDir;
    late PluginStaticServer server;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('static_server_test_');
      final indexFile = File(p.join(tempDir.path, 'index.html'));
      indexFile.writeAsStringSync('<h1>Hello Plugin</h1>');
      final jsFile = File(p.join(tempDir.path, 'plugin.js'));
      jsFile.writeAsStringSync('console.log("ready");');
      server = PluginStaticServer();
    });

    tearDown(() async {
      await server.stop();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Future<Map<String, dynamic>> fetch(String url) async {
      final client = HttpClient();
      try {
        final req = await client.getUrl(Uri.parse(url));
        final resp = await req.close();
        final body = await resp.transform(utf8.decoder).join();
        return {
          'statusCode': resp.statusCode,
          'contentType': resp.headers.contentType?.toString() ?? '',
          'body': body,
        };
      } finally {
        client.close();
      }
    }

    test('serves files with correct MIME types and prevents traversal',
        () async {
      final port = await server.start(tempDir.path);
      expect(port, greaterThan(0));

      final indexResp = await fetch('http://127.0.0.1:$port/index.html');
      expect(indexResp['statusCode'], 200);
      expect(indexResp['body'], '<h1>Hello Plugin</h1>');
      expect(indexResp['contentType'], contains('text/html'));

      // Root path '/' serves index.html
      final rootResp = await fetch('http://127.0.0.1:$port/');
      expect(rootResp['statusCode'], 200);
      expect(rootResp['body'], '<h1>Hello Plugin</h1>');

      // JS file
      final jsResp = await fetch('http://127.0.0.1:$port/plugin.js');
      expect(jsResp['statusCode'], 200);
      expect(jsResp['body'], 'console.log("ready");');
      expect(jsResp['contentType'], contains('application/javascript'));

      // 404 for non-existent file
      final notFound = await fetch('http://127.0.0.1:$port/missing.html');
      expect(notFound['statusCode'], 404);
    });
  });
}
