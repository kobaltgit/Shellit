import 'dart:async';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';
import 'local_file_pane.dart';
import 'pane_reload_controller.dart';
import 'remote_file_pane.dart';
import 'sftp_dialogs.dart';
import 'sftp_drag_payload.dart';
import 'transfer_queue_bar.dart';

class SftpTabView extends StatefulWidget {
  final HostEntity host;
  final ISftpSession sftpSession;

  const SftpTabView({
    super.key,
    required this.host,
    required this.sftpSession,
  });

  @override
  State<SftpTabView> createState() => _SftpTabViewState();
}

class _SftpTabViewState extends State<SftpTabView> {
  final PaneReloadController _localReloadController = PaneReloadController();
  final PaneReloadController _remoteReloadController = PaneReloadController();

  FileSystemEntity? _selectedLocalEntity;
  List<FileSystemEntity> _selectedLocalEntities = [];
  String _currentLocalPath = Directory.current.path;

  SftpItem? _selectedRemoteItem;
  List<SftpItem> _selectedRemoteItems = [];
  String _currentRemotePath = '/';

  final List<FileTransferItem> _transfers = [];

  // Cancellation and transfer control
  bool _cancelRequested = false;
  StreamSubscription<double>? _currentStreamSub;
  Completer<void>? _currentCompleter;
  String? _currentTransferId;

  @override
  void dispose() {
    _cancelRequested = true;
    _currentStreamSub?.cancel();
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete();
    }
    _localReloadController.dispose();
    _remoteReloadController.dispose();
    super.dispose();
  }

  String _joinRemote(String parent, String child) {
    if (parent == '/') return '/$child';
    if (parent.endsWith('/')) return '$parent$child';
    return '$parent/$child';
  }

  String _joinLocal(String parent, String child) {
    return '$parent${Platform.pathSeparator}$child';
  }

  // --- CANCELLATION HANDLERS ---

  void _cancelAllTransfers() {
    _cancelRequested = true;
    _currentStreamSub?.cancel();
    if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
      _currentCompleter!.complete();
    }

    if (mounted) {
      setState(() {
        for (int i = 0; i < _transfers.length; i++) {
          if (_transfers[i].status == TransferStatus.inProgress ||
              _transfers[i].status == TransferStatus.queued) {
            _transfers[i] = _transfers[i].copyWith(
              status: TransferStatus.cancelled,
              errorMessage: 'Cancelled by user',
            );
          }
        }
      });
      _localReloadController.reload();
      _remoteReloadController.reload();
    }
  }

  void _cancelSingleTransfer(String transferId) {
    if (_currentTransferId == transferId) {
      _currentStreamSub?.cancel();
      if (_currentCompleter != null && !_currentCompleter!.isCompleted) {
        _currentCompleter!.complete();
      }
    }

    if (mounted) {
      setState(() {
        final idx = _transfers.indexWhere((t) => t.id == transferId);
        if (idx != -1) {
          _transfers[idx] = _transfers[idx].copyWith(
            status: TransferStatus.cancelled,
            errorMessage: 'Cancelled by user',
          );
        }
      });
    }
  }

  // --- UPLOAD IMPLEMENTATION (Recursive + Conflict Resolution + Cancel) ---

  void _handleUpload() {
    final pathsToUpload = <String>[];
    if (_selectedLocalEntities.isNotEmpty) {
      pathsToUpload.addAll(_selectedLocalEntities.map((e) => e.path));
    } else if (_selectedLocalEntity != null) {
      pathsToUpload.add(_selectedLocalEntity!.path);
    }
    if (pathsToUpload.isEmpty) return;

    _uploadPaths(pathsToUpload, targetRemoteDir: _currentRemotePath);
  }

  Future<void> _uploadPaths(
    List<String> localPaths, {
    required String targetRemoteDir,
  }) async {
    _cancelRequested = false;
    SftpConflictDecision? batchDecision;
    final Map<String, List<SftpItem>> remoteDirCache = {};

    for (final localPath in localPaths) {
      if (_cancelRequested) break;

      final isDir = FileSystemEntity.isDirectorySync(localPath);
      if (isDir) {
        // Recursive folder upload
        await _uploadDirectoryRecursively(
          localDirPath: localPath,
          targetRemoteParentDir: targetRemoteDir,
          getBatchDecision: () => batchDecision,
          setBatchDecision: (d) => batchDecision = d,
          remoteDirCache: remoteDirCache,
        );
      } else {
        // Single file upload
        final fileName = localPath.split(Platform.pathSeparator).last;
        final targetRemotePath = _joinRemote(targetRemoteDir, fileName);
        await _uploadSingleFileWithConflict(
          localFilePath: localPath,
          targetRemotePath: targetRemotePath,
          getBatchDecision: () => batchDecision,
          setBatchDecision: (d) => batchDecision = d,
          remoteDirCache: remoteDirCache,
        );
      }
    }

    if (mounted) {
      _remoteReloadController.reload();
    }
  }

  Future<void> _uploadDirectoryRecursively({
    required String localDirPath,
    required String targetRemoteParentDir,
    required SftpConflictDecision? Function() getBatchDecision,
    required void Function(SftpConflictDecision) setBatchDecision,
    required Map<String, List<SftpItem>> remoteDirCache,
  }) async {
    if (_cancelRequested) return;

    final dir = Directory(localDirPath);
    if (!dir.existsSync()) return;

    final dirName =
        dir.path.split(Platform.pathSeparator).where((s) => s.isNotEmpty).last;
    final remoteBaseDir = _joinRemote(targetRemoteParentDir, dirName);

    // Create remote base directory
    await widget.sftpSession.createDirectory(remoteBaseDir);

    try {
      final entities = dir.listSync(recursive: true, followLinks: false);

      // First ensure all remote subdirectories are created
      for (final entity in entities) {
        if (_cancelRequested) return;
        if (entity is Directory) {
          final relPath =
              entity.path.substring(dir.path.length).replaceAll(r'\', '/');
          final subRemoteDir = '$remoteBaseDir$relPath';
          await widget.sftpSession.createDirectory(subRemoteDir);
        }
      }

      // Next upload all files
      for (final entity in entities) {
        if (_cancelRequested) return;
        if (entity is File) {
          final relPath =
              entity.path.substring(dir.path.length).replaceAll(r'\', '/');
          final targetRemotePath = '$remoteBaseDir$relPath';
          await _uploadSingleFileWithConflict(
            localFilePath: entity.path,
            targetRemotePath: targetRemotePath,
            getBatchDecision: getBatchDecision,
            setBatchDecision: setBatchDecision,
            remoteDirCache: remoteDirCache,
          );
        }
      }
    } catch (_) {
      // Ignore directory enumeration errors
    }
  }

  Future<void> _uploadSingleFileWithConflict({
    required String localFilePath,
    required String targetRemotePath,
    required SftpConflictDecision? Function() getBatchDecision,
    required void Function(SftpConflictDecision) setBatchDecision,
    required Map<String, List<SftpItem>> remoteDirCache,
  }) async {
    if (_cancelRequested) return;

    final localFile = File(localFilePath);
    if (!localFile.existsSync()) return;
    final localStat = localFile.statSync();

    // Check remote conflict
    final parentDir = targetRemotePath.contains('/')
        ? (targetRemotePath.lastIndexOf('/') == 0
            ? '/'
            : targetRemotePath.substring(0, targetRemotePath.lastIndexOf('/')))
        : '/';
    final fileName = targetRemotePath.split('/').last;

    List<SftpItem>? cachedItems = remoteDirCache[parentDir];
    if (cachedItems == null) {
      final listRes = await widget.sftpSession.listDirectory(parentDir);
      cachedItems = listRes.valueOrNull ?? [];
      remoteDirCache[parentDir] = cachedItems;
    }

    SftpItem? conflictingItem;
    try {
      conflictingItem = cachedItems.firstWhere((item) => item.name == fileName);
    } catch (_) {
      conflictingItem = null;
    }

    String effectiveRemoteDest = targetRemotePath;

    if (conflictingItem != null) {
      var decision = getBatchDecision();
      if (decision == null && mounted && !_cancelRequested) {
        final result = await showDialog<SftpConflictResult>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => SftpConflictDialog(
            fileName: fileName,
            sourceSizeBytes: localStat.size,
            sourceModified: localStat.modified,
            destSizeBytes: conflictingItem!.sizeBytes,
            destModified: conflictingItem.modifiedAt,
          ),
        );
        if (_cancelRequested || result == null) {
          return;
        }
        if (result.applyToAll) {
          setBatchDecision(result.decision);
        }
        decision = result.decision;
        if (result.decision == SftpConflictDecision.skip) {
          return;
        }
        if (result.decision == SftpConflictDecision.rename &&
            result.newName != null &&
            result.newName!.isNotEmpty) {
          effectiveRemoteDest = _joinRemote(parentDir, result.newName!);
        }
      } else if (decision == SftpConflictDecision.skip) {
        return;
      }
    }

    if (_cancelRequested) return;

    final transferId =
        'upload-${DateTime.now().microsecondsSinceEpoch}-${localFilePath.hashCode}';
    final transferItem = FileTransferItem(
      id: transferId,
      fileName: fileName,
      sourcePath: localFilePath,
      destinationPath: effectiveRemoteDest,
      direction: TransferDirection.upload,
      status: TransferStatus.inProgress,
    );

    if (mounted) {
      setState(() {
        _transfers.add(transferItem);
      });
    }

    _currentTransferId = transferId;
    _currentCompleter = Completer<void>();

    final stream = widget.sftpSession.uploadFile(
      localPath: localFilePath,
      remotePath: effectiveRemoteDest,
    );

    _currentStreamSub = stream.listen(
      (progress) {
        if (_cancelRequested) {
          _currentStreamSub?.cancel();
          if (!_currentCompleter!.isCompleted) _currentCompleter!.complete();
          return;
        }
        _updateTransfer(transferId, progress: progress);
      },
      onError: (err) {
        _updateTransfer(
          transferId,
          status: TransferStatus.failed,
          errorMessage: err.toString(),
        );
        _currentStreamSub?.cancel();
        if (!_currentCompleter!.isCompleted) _currentCompleter!.complete();
      },
      onDone: () {
        _updateTransfer(
          transferId,
          progress: 1.0,
          status: TransferStatus.completed,
        );
        _currentStreamSub?.cancel();
        if (!_currentCompleter!.isCompleted) _currentCompleter!.complete();
      },
    );

    await _currentCompleter!.future;
  }

  // --- DOWNLOAD IMPLEMENTATION (Recursive + Conflict Resolution + Cancel) ---

  void _handleDownload() {
    final pathsToDownload = <String>[];
    if (_selectedRemoteItems.isNotEmpty) {
      pathsToDownload.addAll(_selectedRemoteItems.map((i) => i.path));
    } else if (_selectedRemoteItem != null) {
      pathsToDownload.add(_selectedRemoteItem!.path);
    }
    if (pathsToDownload.isEmpty) return;

    _downloadPaths(pathsToDownload, targetLocalDir: _currentLocalPath);
  }

  Future<void> _downloadPaths(
    List<String> remotePaths, {
    required String targetLocalDir,
  }) async {
    _cancelRequested = false;
    SftpConflictDecision? batchDecision;

    for (final remotePath in remotePaths) {
      if (_cancelRequested) break;

      // Determine if directory or file
      final listRes = await widget.sftpSession.listDirectory(remotePath);
      if (listRes.isSuccess) {
        // Recursive folder download
        final dirName = remotePath.split('/').where((s) => s.isNotEmpty).last;
        final targetSubLocal = _joinLocal(targetLocalDir, dirName);
        final dir = Directory(targetSubLocal);
        if (!dir.existsSync()) {
          dir.createSync(recursive: true);
        }
        await _downloadRemoteDirectoryRecursively(
          remoteDirPath: remotePath,
          localDirPath: targetSubLocal,
          getBatchDecision: () => batchDecision,
          setBatchDecision: (d) => batchDecision = d,
        );
      } else {
        // Single file download
        final fileName = remotePath.split('/').last;
        final targetLocalPath = _joinLocal(targetLocalDir, fileName);
        await _downloadSingleFileWithConflict(
          remotePath: remotePath,
          fileName: fileName,
          targetLocalPath: targetLocalPath,
          getBatchDecision: () => batchDecision,
          setBatchDecision: (d) => batchDecision = d,
        );
      }
    }

    if (mounted) {
      _localReloadController.reload();
    }
  }

  Future<void> _downloadRemoteDirectoryRecursively({
    required String remoteDirPath,
    required String localDirPath,
    required SftpConflictDecision? Function() getBatchDecision,
    required void Function(SftpConflictDecision) setBatchDecision,
  }) async {
    if (_cancelRequested) return;

    final listRes = await widget.sftpSession.listDirectory(remoteDirPath);
    if (!listRes.isSuccess) return;

    for (final item in listRes.valueOrNull ?? <SftpItem>[]) {
      if (_cancelRequested) return;
      if (item.name == '.' || item.name == '..') continue;
      final itemLocalPath = _joinLocal(localDirPath, item.name);
      if (item.isDirectory) {
        final subDir = Directory(itemLocalPath);
        if (!subDir.existsSync()) {
          subDir.createSync(recursive: true);
        }
        await _downloadRemoteDirectoryRecursively(
          remoteDirPath: item.path,
          localDirPath: itemLocalPath,
          getBatchDecision: getBatchDecision,
          setBatchDecision: setBatchDecision,
        );
      } else {
        await _downloadSingleFileWithConflict(
          remotePath: item.path,
          fileName: item.name,
          remoteItem: item,
          targetLocalPath: itemLocalPath,
          getBatchDecision: getBatchDecision,
          setBatchDecision: setBatchDecision,
        );
      }
    }
  }

  Future<void> _downloadSingleFileWithConflict({
    required String remotePath,
    required String fileName,
    SftpItem? remoteItem,
    required String targetLocalPath,
    required SftpConflictDecision? Function() getBatchDecision,
    required void Function(SftpConflictDecision) setBatchDecision,
  }) async {
    if (_cancelRequested) return;

    final localFile = File(targetLocalPath);
    String effectiveLocalDest = targetLocalPath;

    if (localFile.existsSync()) {
      final localStat = localFile.statSync();
      var decision = getBatchDecision();
      if (decision == null && mounted && !_cancelRequested) {
        final result = await showDialog<SftpConflictResult>(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => SftpConflictDialog(
            fileName: fileName,
            sourceSizeBytes: remoteItem?.sizeBytes,
            sourceModified: remoteItem?.modifiedAt,
            destSizeBytes: localStat.size,
            destModified: localStat.modified,
          ),
        );
        if (_cancelRequested || result == null) {
          return;
        }
        if (result.applyToAll) {
          setBatchDecision(result.decision);
        }
        decision = result.decision;
        if (result.decision == SftpConflictDecision.skip) {
          return;
        }
        if (result.decision == SftpConflictDecision.rename &&
            result.newName != null &&
            result.newName!.isNotEmpty) {
          effectiveLocalDest =
              _joinLocal(localFile.parent.path, result.newName!);
        }
      } else if (decision == SftpConflictDecision.skip) {
        return;
      }
    }

    if (_cancelRequested) return;

    final transferId =
        'download-${DateTime.now().microsecondsSinceEpoch}-${remotePath.hashCode}';
    final transferItem = FileTransferItem(
      id: transferId,
      fileName: fileName,
      sourcePath: remotePath,
      destinationPath: effectiveLocalDest,
      direction: TransferDirection.download,
      status: TransferStatus.inProgress,
    );

    if (mounted) {
      setState(() {
        _transfers.add(transferItem);
      });
    }

    _currentTransferId = transferId;
    _currentCompleter = Completer<void>();

    final stream = widget.sftpSession.downloadFile(
      remotePath: remotePath,
      localPath: effectiveLocalDest,
    );

    _currentStreamSub = stream.listen(
      (progress) {
        if (_cancelRequested) {
          _currentStreamSub?.cancel();
          if (!_currentCompleter!.isCompleted) _currentCompleter!.complete();
          return;
        }
        _updateTransfer(transferId, progress: progress);
      },
      onError: (err) {
        _updateTransfer(
          transferId,
          status: TransferStatus.failed,
          errorMessage: err.toString(),
        );
        _currentStreamSub?.cancel();
        if (!_currentCompleter!.isCompleted) _currentCompleter!.complete();
      },
      onDone: () {
        _updateTransfer(
          transferId,
          progress: 1.0,
          status: TransferStatus.completed,
        );
        _currentStreamSub?.cancel();
        if (!_currentCompleter!.isCompleted) _currentCompleter!.complete();
      },
    );

    await _currentCompleter!.future;
  }

  void _updateTransfer(
    String id, {
    double? progress,
    TransferStatus? status,
    String? errorMessage,
  }) {
    if (!mounted) return;
    setState(() {
      final index = _transfers.indexWhere((t) => t.id == id);
      if (index != -1) {
        _transfers[index] = _transfers[index].copyWith(
          progress: progress,
          status: status,
          errorMessage: errorMessage,
        );
      }
    });
  }

  void _clearCompletedTransfers() {
    setState(() {
      _transfers.removeWhere((t) =>
          t.status == TransferStatus.completed ||
          t.status == TransferStatus.failed ||
          t.status == TransferStatus.cancelled);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Two Panes (Split 50/50 with Drag & Drop between panes)
        Expanded(
          child: Row(
            children: [
              // Local File Pane (Accepts remote drops for download)
              Expanded(
                child: DragTarget<SftpRemoteDragPayload>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.paths.isNotEmpty,
                  onAcceptWithDetails: (details) {
                    _downloadPaths(
                      details.data.paths,
                      targetLocalDir: _currentLocalPath,
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      decoration: isHovering
                          ? BoxDecoration(
                              border: Border.all(
                                color: ShellitColors.accentCyan,
                                width: 2,
                              ),
                            )
                          : null,
                      child: LocalFilePane(
                        reloadController: _localReloadController,
                        onSelectionChanged: (entity) {
                          setState(() => _selectedLocalEntity = entity);
                        },
                        onMultiSelectionChanged: (entities) {
                          setState(() => _selectedLocalEntities = entities);
                        },
                        onPathChanged: (path) => _currentLocalPath = path,
                        onUploadSelected: _handleUpload,
                      ),
                    );
                  },
                ),
              ),

              // Remote File Pane (Accepts local drops for upload)
              Expanded(
                child: DragTarget<SftpLocalDragPayload>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.paths.isNotEmpty,
                  onAcceptWithDetails: (details) {
                    _uploadPaths(
                      details.data.paths,
                      targetRemoteDir: _currentRemotePath,
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isHovering = candidateData.isNotEmpty;
                    return Container(
                      decoration: isHovering
                          ? BoxDecoration(
                              border: Border.all(
                                color: ShellitColors.accentBlue,
                                width: 2,
                              ),
                            )
                          : null,
                      child: RemoteFilePane(
                        reloadController: _remoteReloadController,
                        session: widget.sftpSession,
                        onSelectionChanged: (item) {
                          setState(() => _selectedRemoteItem = item);
                        },
                        onMultiSelectionChanged: (items) {
                          setState(() => _selectedRemoteItems = items);
                        },
                        onPathChanged: (path) => _currentRemotePath = path,
                        onDownloadSelected: _handleDownload,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // Bottom Transfer Queue with Cancel Support
        TransferQueueBar(
          transfers: _transfers,
          onClearCompleted: _clearCompletedTransfers,
          onCancelTransfer: _cancelSingleTransfer,
          onCancelAll: _cancelAllTransfers,
        ),
      ],
    );
  }
}
