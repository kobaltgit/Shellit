import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:shellit_sync_server/sync_server.dart';

void main(List<String> args) async {
  final port = int.tryParse(Platform.environment['PORT'] ?? '8080') ?? 8080;
  final host = Platform.environment['HOST'] ?? '0.0.0.0';
  final dataPath =
      Platform.environment['DATA_PATH'] ?? './data/shellit-sync.db';
  final registrationToken = Platform.environment['REGISTRATION_TOKEN'];

  stdout.writeln('====================================================');
  stdout.writeln('  Shellit Self-Hosted Sync Server (E2EE Zero-Knowledge)');
  stdout.writeln('====================================================');
  stdout.writeln('Listening on     : $host:$port');
  stdout.writeln('Database path    : $dataPath');
  stdout.writeln(
      'Token protection : ${registrationToken != null && registrationToken.isNotEmpty ? "ENABLED" : "OPEN"}');

  final db = SyncDatabase.openFile(dataPath);
  final wsHub = WsHub();
  final api = SyncApi(
    db: db,
    wsHub: wsHub,
    registrationToken: registrationToken,
  );

  final pipeline =
      const Pipeline().addMiddleware(logRequests()).addHandler(api.handler);

  final server = await io.serve(pipeline, host, port);
  stdout.writeln(
      'Server successfully running at http://${server.address.host}:${server.port}');

  // Graceful shutdown
  ProcessSignal.sigint.watch().listen((_) async {
    stdout.writeln('\nReceived SIGINT. Shutting down gracefully...');
    await server.close(force: true);
    db.close();
    exit(0);
  });

  if (!Platform.isWindows) {
    ProcessSignal.sigterm.watch().listen((_) async {
      stdout.writeln('\nReceived SIGTERM. Shutting down gracefully...');
      await server.close(force: true);
      db.close();
      exit(0);
    });
  }
}
