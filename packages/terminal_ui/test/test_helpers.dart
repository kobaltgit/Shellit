import 'dart:async';
import 'dart:typed_data';
import 'package:core_foundation/core_foundation.dart';

class FakeTerminalSession implements ITerminalSession {
  @override
  final String id;
  @override
  final String hostId;

  final StreamController<Uint8List> _outputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<Uint8List> _inputController =
      StreamController<Uint8List>.broadcast();
  final StreamController<SessionState> _stateController =
      StreamController<SessionState>.broadcast();

  final List<Uint8List> receivedInputs = [];
  TerminalDimensions lastDimensions =
      const TerminalDimensions(cols: 80, rows: 24);
  SessionState _state = SessionState.ready;
  bool isTerminated = false;

  FakeTerminalSession({
    required this.id,
    required this.hostId,
  }) {
    _inputController.stream.listen((bytes) {
      receivedInputs.add(bytes);
    });
  }

  @override
  Stream<Uint8List> get outputStream => _outputController.stream;

  @override
  Sink<Uint8List> get inputStream => _inputController.sink;

  @override
  SessionState get currentState => _state;

  @override
  Stream<SessionState> get stateStream => _stateController.stream;

  void emitOutput(Uint8List bytes) {
    _outputController.add(bytes);
  }

  void emitState(SessionState newState) {
    _state = newState;
    _stateController.add(newState);
  }

  @override
  void resize(TerminalDimensions dimensions) {
    lastDimensions = dimensions;
  }

  @override
  Future<void> terminate() async {
    if (isTerminated) return;
    isTerminated = true;
    _state = SessionState.disconnected;
    if (!_stateController.isClosed) {
      _stateController.add(_state);
    }
    await _outputController.close();
    await _inputController.close();
    await _stateController.close();
  }

  @override
  dynamic get underlyingClient => null;

  @override
  ISessionRecorder? recorder;
}

class FakeVaultRepository implements IVaultRepository {
  bool _initialized = true;
  bool _unlocked = true;
  String currentMasterPassword = 'old-master-pwd';
  final StreamController<bool> _lockController =
      StreamController<bool>.broadcast();

  @override
  bool get isVaultUnlocked => _unlocked;

  @override
  Stream<bool> watchUnlockStatus() => _lockController.stream;

  @override
  Future<bool> isVaultInitialized() async => _initialized;

  @override
  Future<Result<void, VaultFailure>> initializeVault(
      String masterPassword) async {
    _initialized = true;
    _unlocked = true;
    currentMasterPassword = masterPassword;
    _lockController.add(true);
    return const Result.success(null);
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithPassword(
      String masterPassword) async {
    if (masterPassword == currentMasterPassword) {
      _unlocked = true;
      _lockController.add(true);
      return const Result.success(null);
    }
    return Result.error(VaultFailure.invalidMasterPassword());
  }

  @override
  Future<Result<void, VaultFailure>> unlockWithBiometrics() async =>
      const Result.success(null);

  @override
  Future<Result<void, VaultFailure>> unlockWithPin(String pin) async =>
      const Result.success(null);

  @override
  void lock() {
    _unlocked = false;
    _lockController.add(false);
  }

  @override
  Future<Result<void, VaultFailure>> changeMasterPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    if (currentPassword != currentMasterPassword) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }
    currentMasterPassword = newPassword;
    _unlocked = true;
    _lockController.add(true);
    return const Result.success(null);
  }

  @override
  Future<Result<void, VaultFailure>> disableMasterPassword({
    required String currentPassword,
  }) async {
    if (currentPassword != currentMasterPassword) {
      return Result.error(VaultFailure.invalidMasterPassword());
    }
    _initialized = false;
    _unlocked = true;
    _lockController.add(true);
    return const Result.success(null);
  }

  @override
  Future<void> ensureOpenSession() async {}

  @override
  Future<VaultSettingsEntity> getSettings() async =>
      const VaultSettingsEntity();

  @override
  Future<Result<void, VaultFailure>> updateSettings(
          VaultSettingsEntity settings) async =>
      const Result.success(null);
}

class FakeSftpSession implements ISftpSession {
  @override
  final String id;
  @override
  final String hostId;

  FakeSftpSession({
    this.id = 'fake-sftp-1',
    this.hostId = 'host-1',
  });

  @override
  dynamic get underlyingClient => null;

  @override
  Future<void> close() async {}

  @override
  Future<Result<void, SftpFailure>> createDirectory(String remotePath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> createFile(String remotePath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> deleteDirectory(String remotePath,
          {bool recursive = false}) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> deleteFile(String remotePath) async =>
      const Result.success(null);

  @override
  Stream<double> downloadFile(
          {required String remotePath, required String localPath}) =>
      const Stream.empty();

  @override
  Future<Result<List<SftpItem>, SftpFailure>> listDirectory(
          String remotePath) async =>
      const Result.success([]);

  @override
  Future<Result<void, SftpFailure>> rename(
          String oldPath, String newPath) async =>
      const Result.success(null);

  @override
  Future<Result<void, SftpFailure>> setPermissions(
          String remotePath, int permissions) async =>
      const Result.success(null);

  @override
  Stream<double> uploadFile(
          {required String localPath, required String remotePath}) =>
      const Stream.empty();
}
