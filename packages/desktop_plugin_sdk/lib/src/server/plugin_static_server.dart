import 'dart:io';
import 'package:path/path.dart' as p;

/// Lightweight localhost HTTP server to serve plugin static web assets (index.html, JS, CSS)
/// into a desktop WebView sandbox without CORS or file:// protocol security restrictions.
class PluginStaticServer {
  /// Strict CSP header restricting resource loading within plugin sandbox.
  static const String contentSecurityPolicyHeader =
      "default-src 'self'; script-src 'self' 'unsafe-inline'; style-src 'self' 'unsafe-inline'; img-src 'self' data:; connect-src 'none'; frame-ancestors 'none';";

  /// Disables MIME sniffing.
  static const String xContentTypeOptionsHeader = 'nosniff';

  /// Prevents framing / clickjacking.
  static const String xFrameOptionsHeader = 'DENY';

  HttpServer? _server;

  int? get port => _server?.port;
  String? get baseUrl =>
      _server != null ? 'http://127.0.0.1:${_server!.port}' : null;

  /// Starts the HTTP server serving files from [pluginDirectory].
  Future<int> start(String pluginDirectory) async {
    await stop();
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.listen((HttpRequest request) async {
      try {
        _applySecurityHeaders(request.response);
        var reqPath = request.uri.path;
        if (reqPath == '/' || reqPath.isEmpty) {
          reqPath = '/index.html';
        }
        if (reqPath.startsWith('/')) {
          reqPath = reqPath.substring(1);
        }

        // Prevent path traversal outside plugin directory
        final safePath = p.normalize(reqPath);
        if (safePath.startsWith('..')) {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write('Forbidden');
          await request.response.close();
          return;
        }

        final file = File(p.normalize(p.join(pluginDirectory, safePath)));
        if (!p.isWithin(pluginDirectory, file.path) &&
            file.path != p.normalize(p.join(pluginDirectory, 'index.html'))) {
          request.response.statusCode = HttpStatus.forbidden;
          request.response.write('Forbidden');
          await request.response.close();
          return;
        }

        if (await file.exists()) {
          final ext = p.extension(file.path).toLowerCase();
          final mime = _mimeFor(ext);
          request.response.headers.set(HttpHeaders.contentTypeHeader, mime);
          await request.response.addStream(file.openRead());
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('404 Not Found: $reqPath');
        }
      } catch (e) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.write('500 Internal Error: $e');
      } finally {
        await request.response.close();
      }
    });

    return _server!.port;
  }

  /// Applies strict Content Security Policy (CSP) and hardening headers to [response].
  static void _applySecurityHeaders(HttpResponse response) {
    response.headers.set(
      'Content-Security-Policy',
      contentSecurityPolicyHeader,
    );
    response.headers.set(
      'X-Content-Type-Options',
      xContentTypeOptionsHeader,
    );
    response.headers.set(
      'X-Frame-Options',
      xFrameOptionsHeader,
    );
    response.headers.set('Access-Control-Allow-Origin', '*');
  }

  /// Stops and closes the server.
  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
  }

  static String _mimeFor(String ext) {
    switch (ext) {
      case '.html':
      case '.htm':
        return 'text/html; charset=utf-8';
      case '.js':
      case '.mjs':
        return 'application/javascript; charset=utf-8';
      case '.css':
        return 'text/css; charset=utf-8';
      case '.json':
        return 'application/json; charset=utf-8';
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.gif':
        return 'image/gif';
      case '.svg':
        return 'image/svg+xml';
      case '.ico':
        return 'image/x-icon';
      case '.woff':
        return 'font/woff';
      case '.woff2':
        return 'font/woff2';
      case '.ttf':
        return 'font/ttf';
      default:
        return 'application/octet-stream';
    }
  }
}
