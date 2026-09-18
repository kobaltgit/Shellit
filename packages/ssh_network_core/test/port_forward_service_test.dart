import 'package:core_foundation/core_foundation.dart';
import 'package:ssh_network_core/ssh_network_core.dart';
import 'package:test/test.dart';

void main() {
  group('PortForwardService Tunnel Lifecycle Tests', () {
    late PortForwardService service;

    setUp(() {
      service = PortForwardService();
    });

    test('activeTunnelIds is initially empty', () {
      expect(service.activeTunnelIds, isEmpty);
    });

    test('stopTunnel on nonexistent ID does not throw', () async {
      await expectLater(service.stopTunnel('unknown_id'), completes);
      expect(service.activeTunnelIds, isEmpty);
    });

    test('startLocalForward fails gracefully when host is unreachable',
        () async {
      final host = HostEntity(
        id: 'h_unreachable',
        label: 'Unreachable Host',
        hostname: '127.0.0.1',
        port: 65430,
        username: 'root',
        authType: HostAuthType.password,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final res = await service.startLocalForward(
        host: host,
        localPort: 12345,
        remoteHost: '10.0.0.1',
        remotePort: 80,
        password: 'pass',
      );

      expect(res.isError, isTrue);
      expect(service.activeTunnelIds, isEmpty);
    });

    test('startRemoteForward fails gracefully when host is unreachable',
        () async {
      final host = HostEntity(
        id: 'h_unreachable_2',
        label: 'Unreachable Host',
        hostname: '127.0.0.1',
        port: 65429,
        username: 'root',
        authType: HostAuthType.password,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final res = await service.startRemoteForward(
        host: host,
        remotePort: 9090,
        targetHost: '127.0.0.1',
        targetPort: 8080,
        password: 'pass',
      );

      expect(res.isError, isTrue);
      expect(service.activeTunnelIds, isEmpty);
    });
  });
}
