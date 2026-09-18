import 'dart:async';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shellit/src/controllers/recording_settings_provider.dart';
import 'package:shellit/src/controllers/session_connect_controller.dart';
import 'package:shellit/src/di/app_providers.dart';
import 'package:terminal_ui/terminal_ui.dart';

class FakeTerminalSession implements ITerminalSession {
  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _inputController =
      StreamController<Uint8List>.broadcast();

  @override
  String get id => 'fake_term_1';

  @override
  String get hostId => 'host-101';

  @override
  SessionState get currentState => SessionState.ready;

  @override
  Stream<SessionState> get stateStream => Stream.value(SessionState.ready);

  @override
  Stream<Uint8List> get outputStream => _outputController.stream;

  @override
  Sink<Uint8List> get inputStream => _inputController.sink;

  @override
  void resize(TerminalDimensions dimensions) {}

  @override
  Future<void> terminate() async {
    await _outputController.close();
    await _inputController.close();
  }

  @override
  dynamic get underlyingClient => Object();

  @override
  ISessionRecorder? recorder;
}

class FakeSftpSession implements ISftpSession {
  @override
  String get id => 'fake_sftp_1';

  @override
  String get hostId => 'host-102';

  @override
  dynamic get underlyingClient => Object();

  @override
  Future<void> close() async {}

  @override
  Stream<double> downloadFile({
    required String remotePath,
    required String localPath,
  }) => const Stream.empty();

  @override
  Future<Result<List<SftpItem>, SftpFailure>> listDirectory(
    String remotePath,
  ) async => const Result.success([]);

  @override
  Future<Result<void, SftpFailure>> createDirectory(String remotePath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> deleteDirectory(
    String remotePath, {
    bool recursive = false,
  }) async => const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> deleteFile(String remotePath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> rename(
    String oldPath,
    String newPath,
  ) async => const Result.success(null);

  @override
  Stream<double> uploadFile({
    required String localPath,
    required String remotePath,
  }) => const Stream.empty();

  @override
  Future<Result<void, SftpFailure>> setPermissions(
    String remotePath,
    int permissions,
  ) async => const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> createFile(String remotePath) async =>
      const Result.success(null);
}

class FakeHostRepository implements IHostRepository {
  final Map<String, HostEntity> _hosts = {};

  @override
  Future<Result<void, VaultFailure>> saveHost(HostEntity host) async {
    _hosts[host.id] = host;
    return const Result.success(null);
  }

  @override
  Future<List<HostEntity>> getAllHosts() async => _hosts.values.toList();

  @override
  Future<HostEntity?> getHostById(String id) async => _hosts[id];

  @override
  Future<Result<void, VaultFailure>> deleteHost(String id) async {
    _hosts.remove(id);
    return const Result.success(null);
  }

  @override
  Stream<List<HostEntity>> watchAllHosts() =>
      Stream.value(_hosts.values.toList());

  @override
  Future<void> updateHostLatency(String hostId, int latencyMs) async {
    final h = _hosts[hostId];
    if (h != null) _hosts[hostId] = h.copyWith(lastPingLatencyMs: latencyMs);
  }
}

class FakeOsDetector implements IOsDetector {
  final OsType detected;
  FakeOsDetector({this.detected = OsType.ubuntu});

  @override
  Future<OsType> detectOs(dynamic sshClient) async => detected;

  @override
  OsType parseOsRelease(String output) => detected;
}

class FakeSshClientService implements ISshClientService {
  final fakeTerminal = FakeTerminalSession();
  final fakeSftp = FakeSftpSession();
  ISessionRecorder? lastCreatedRecorder;

  @override
  Future<Result<ITerminalSession, NetworkFailure>> createTerminalSession({
    required HostEntity host,
    required TerminalDimensions initialDimensions,
    String? password,
    List<int>? privateKeyBytes,
    String? passphrase,
    ISessionRecorder? recorder,
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('Connecting...');
    lastCreatedRecorder = recorder;
    fakeTerminal.recorder = recorder;
    return Result.success(fakeTerminal);
  }

  @override
  Future<Result<ISftpSession, NetworkFailure>> openSftpSession({
    required HostEntity host,
    String? password,
    List<int>? privateKeyBytes,
    String? passphrase,
    void Function(String status)? onProgress,
  }) async {
    onProgress?.call('Opening SFTP...');
    return Result.success(fakeSftp);
  }

  @override
  Future<Result<int, NetworkFailure>> pingHost(
    String hostname,
    int port, {
    Duration timeout = const Duration(seconds: 4),
  }) async {
    return const Result.success(24);
  }
}

void main() {
  test(
    'SessionConnectController connects terminal and adds tab to sessionManagerProvider',
    () async {
      final fakeService = FakeSshClientService();

      final container = ProviderContainer(
        overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionConnectControllerProvider);
      final now = DateTime.now();
      final testHost = HostEntity(
        id: 'host-101',
        label: 'Staging Server',
        hostname: 'stage.shellit.dev',
        port: 22,
        username: 'root',
        authType: HostAuthType.password,
        environment: HostEnvironment.staging,
        createdAt: now,
        updatedAt: now,
      );

      final session = await controller.connectTerminal(testHost);
      expect(session, isNotNull);

      // Also manually verify openTerminalTab creates tab
      container
          .read(sessionManagerProvider.notifier)
          .openTerminalTab(host: testHost, session: session);

      final sessionTabs = container.read(sessionManagerProvider).tabs;
      expect(sessionTabs.length, 1);
      expect(sessionTabs.first.title, 'Staging Server');
      expect(sessionTabs.first.type, TabType.terminal);
    },
  );

  test('SessionConnectController connects SFTP and opens SFTP tab', () async {
    final fakeService = FakeSshClientService();

    final container = ProviderContainer(
      overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
    );
    addTearDown(container.dispose);

    final controller = container.read(sessionConnectControllerProvider);
    final now = DateTime.now();
    final testHost = HostEntity(
      id: 'host-102',
      label: 'Production DB',
      hostname: 'db.shellit.internal',
      port: 22,
      username: 'postgres',
      authType: HostAuthType.password,
      environment: HostEnvironment.production,
      createdAt: now,
      updatedAt: now,
    );

    final sftpSession = await controller.connectSftp(testHost);
    expect(sftpSession, isNotNull);

    container
        .read(sessionManagerProvider.notifier)
        .openSftpTab(host: testHost, session: sftpSession);

    final sessionTabs = container.read(sessionManagerProvider).tabs;
    expect(sessionTabs.length, 1);
    expect(sessionTabs.first.title, 'SFTP: Production DB');
    expect(sessionTabs.first.type, TabType.sftp);
    expect(sessionTabs.first.isProduction, true);
  });

  test(
    'SessionManager supports unlimited tabs across multiple hosts (Terminal + SFTP)',
    () async {
      final fakeService = FakeSshClientService();
      final container = ProviderContainer(
        overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final sessionNotifier = container.read(sessionManagerProvider.notifier);
      final now = DateTime.now();

      final host1 = HostEntity(
        id: 'h1',
        label: 'Web Server',
        hostname: 'web.example.com',
        port: 22,
        username: 'nginx',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );

      final host2 = HostEntity(
        id: 'h2',
        label: 'DB Server',
        hostname: 'db.example.com',
        port: 22,
        username: 'postgres',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );

      final host3 = HostEntity(
        id: 'h3',
        label: 'Redis Cache',
        hostname: 'cache.example.com',
        port: 22,
        username: 'redis',
        authType: HostAuthType.password,
        createdAt: now,
        updatedAt: now,
      );

      // Open 5 tabs: Terminal 1, SFTP 1, Terminal 2, SFTP 2, Terminal 3
      final tabId1 = sessionNotifier.openTerminalTab(
        host: host1,
        session: FakeTerminalSession(),
      );
      final tabId2 = sessionNotifier.openSftpTab(
        host: host1,
        session: FakeSftpSession(),
      );
      final tabId3 = sessionNotifier.openTerminalTab(
        host: host2,
        session: FakeTerminalSession(),
      );
      final tabId4 = sessionNotifier.openSftpTab(
        host: host2,
        session: FakeSftpSession(),
      );
      final tabId5 = sessionNotifier.openTerminalTab(
        host: host3,
        session: FakeTerminalSession(),
      );

      var state = container.read(sessionManagerProvider);
      expect(state.tabs.length, 5);
      expect(state.activeTabId, tabId5);
      expect(state.isCatalogActive, false);

      // Switch to Catalog (showCatalog)
      sessionNotifier.showCatalog();
      state = container.read(sessionManagerProvider);
      expect(state.tabs.length, 5); // All 5 tabs still alive
      expect(state.activeTabId, isNull);
      expect(state.isCatalogActive, true);

      // Switch to Tab 2 (SFTP)
      sessionNotifier.setActiveTab(tabId2);
      state = container.read(sessionManagerProvider);
      expect(state.activeTabId, tabId2);
      expect(state.activeTab?.type, TabType.sftp);
      expect(state.isCatalogActive, false);

      // Close Tab 2: remaining tabs should be 4, activeTab should shift
      sessionNotifier.closeTab(tabId2);
      state = container.read(sessionManagerProvider);
      expect(state.tabs.length, 4);
      expect(state.tabs.any((t) => t.id == tabId2), false);
      expect(state.activeTabId, tabId3);

      // Close all tabs -> activeTabId becomes null and catalog becomes active
      sessionNotifier.closeTab(tabId1);
      sessionNotifier.closeTab(tabId3);
      sessionNotifier.closeTab(tabId4);
      sessionNotifier.closeTab(tabId5);

      state = container.read(sessionManagerProvider);
      expect(state.tabs.isEmpty, true);
      expect(state.activeTabId, isNull);
      expect(state.isCatalogActive, true);
    },
  );

  test(
    'connectTerminal triggers background OS detection and updates host osType',
    () async {
      final now = DateTime.now();
      final host = HostEntity(
        id: 'h-autodetect',
        label: 'Ubuntu Server',
        hostname: '192.168.1.50',
        username: 'ubuntu',
        authType: HostAuthType.password,
        osType: OsType.genericServer,
        createdAt: now,
        updatedAt: now,
      );

      final fakeHostRepo = FakeHostRepository();
      await fakeHostRepo.saveHost(host);

      final container = ProviderContainer(
        overrides: [
          appSshClientServiceProvider.overrideWithValue(FakeSshClientService()),
          appHostRepositoryProvider.overrideWithValue(fakeHostRepo),
          hostRepositoryProvider.overrideWithValue(fakeHostRepo),
          appOsDetectorProvider.overrideWithValue(
            FakeOsDetector(detected: OsType.ubuntu),
          ),
        ],
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionConnectControllerProvider);
      final session = await controller.connectTerminal(host);
      expect(session, isNotNull);

      // Wait for async background unawaited probe to finish
      await Future.delayed(const Duration(milliseconds: 60));

      final updated = (await fakeHostRepo.getAllHosts()).firstWhere(
        (h) => h.id == 'h-autodetect',
      );
      expect(updated.osType, equals(OsType.ubuntu));
    },
  );

  test(
    'SessionConnectController automatically attaches recorder for PROD host when policy is prodOnly',
    () async {
      final fakeService = FakeSshClientService();
      final container = ProviderContainer(
        overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionConnectControllerProvider);
      final now = DateTime.now();
      final prodHost = HostEntity(
        id: 'h-prod-rec',
        label: 'Production Web Server',
        hostname: 'prod.shellit.internal',
        port: 22,
        username: 'root',
        authType: HostAuthType.password,
        environment: HostEnvironment.production,
        createdAt: now,
        updatedAt: now,
      );

      final session = await controller.connectTerminal(prodHost);
      expect(session, isNotNull);
      expect(fakeService.lastCreatedRecorder, isNotNull);
      expect(fakeService.lastCreatedRecorder!.isRecording, isTrue);
    },
  );

  test(
    'SessionConnectController does NOT auto-record STAGING host when policy is prodOnly',
    () async {
      final fakeService = FakeSshClientService();
      final container = ProviderContainer(
        overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionConnectControllerProvider);
      final now = DateTime.now();
      final stageHost = HostEntity(
        id: 'h-stage-norec',
        label: 'Staging App Server',
        hostname: 'stage.shellit.internal',
        port: 22,
        username: 'deploy',
        authType: HostAuthType.password,
        environment: HostEnvironment.staging,
        createdAt: now,
        updatedAt: now,
      );

      final session = await controller.connectTerminal(stageHost);
      expect(session, isNotNull);
      expect(fakeService.lastCreatedRecorder, isNull);
      expect(session.recorder, isNull);
    },
  );

  test(
    'SessionConnectController records all sessions when policy is set to all',
    () async {
      final fakeService = FakeSshClientService();
      final container = ProviderContainer(
        overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      container
          .read(sessionRecordingModeProvider.notifier)
          .setMode(SessionRecordingMode.all);

      final controller = container.read(sessionConnectControllerProvider);
      final now = DateTime.now();
      final devHost = HostEntity(
        id: 'h-dev-rec',
        label: 'Local Dev Server',
        hostname: 'localhost',
        port: 2222,
        username: 'vagrant',
        authType: HostAuthType.password,
        environment: HostEnvironment.development,
        createdAt: now,
        updatedAt: now,
      );

      final session = await controller.connectTerminal(devHost);
      expect(session, isNotNull);
      expect(fakeService.lastCreatedRecorder, isNotNull);
      expect(fakeService.lastCreatedRecorder!.isRecording, isTrue);
    },
  );

  test(
    'SessionConnectController.toggleRecording starts and stops recording dynamically',
    () async {
      final fakeService = FakeSshClientService();
      final container = ProviderContainer(
        overrides: [appSshClientServiceProvider.overrideWithValue(fakeService)],
      );
      addTearDown(container.dispose);

      final controller = container.read(sessionConnectControllerProvider);
      final now = DateTime.now();
      final devHost = HostEntity(
        id: 'h-manual-rec',
        label: 'Manual Host',
        hostname: 'manual.shellit.io',
        port: 22,
        username: 'admin',
        authType: HostAuthType.password,
        environment: HostEnvironment.development,
        createdAt: now,
        updatedAt: now,
      );

      final session = await controller.connectTerminal(devHost);
      expect(session.recorder, isNull);

      // 1. Toggle ON
      await controller.toggleRecording(session, devHost);
      expect(session.recorder, isNotNull);
      expect(session.recorder!.isRecording, isTrue);

      // 2. Toggle OFF
      await controller.toggleRecording(session, devHost);
      expect(session.recorder!.isRecording, isFalse);
    },
  );
}
