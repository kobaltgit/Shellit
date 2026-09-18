import 'dart:async';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter/material.dart';
import 'local_file_pane.dart';
import 'remote_file_pane.dart';
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
  final GlobalKey<LocalFilePaneState> _localPaneKey = GlobalKey();
  final GlobalKey<RemoteFilePaneState> _remotePaneKey = GlobalKey();

  FileSystemEntity? _selectedLocalEntity;
  String _currentLocalPath = Directory.current.path;

  SftpItem? _selectedRemoteItem;
  String _currentRemotePath = '/';

  final List<FileTransferItem> _transfers = [];

  void _handleUpload() {
    final localEntity = _selectedLocalEntity;
    if (localEntity == null ||
        FileSystemEntity.isDirectorySync(localEntity.path)) return;

    final fileName = localEntity.path.split(Platform.pathSeparator).last;
    final remoteDest = _currentRemotePath == '/'
        ? '/$fileName'
        : '$_currentRemotePath/$fileName';

    final transferId = 'transfer-${DateTime.now().millisecondsSinceEpoch}';
    final transferItem = FileTransferItem(
      id: transferId,
      fileName: fileName,
      sourcePath: localEntity.path,
      destinationPath: remoteDest,
      direction: TransferDirection.upload,
      status: TransferStatus.inProgress,
    );

    setState(() {
      _transfers.add(transferItem);
    });

    final stream = widget.sftpSession.uploadFile(
      localPath: localEntity.path,
      remotePath: remoteDest,
    );

    StreamSubscription<double>? sub;
    sub = stream.listen(
      (progress) {
        _updateTransfer(transferId, progress: progress);
      },
      onError: (err) {
        _updateTransfer(
          transferId,
          status: TransferStatus.failed,
          errorMessage: err.toString(),
        );
        sub?.cancel();
      },
      onDone: () {
        _updateTransfer(
          transferId,
          progress: 1.0,
          status: TransferStatus.completed,
        );
        _remotePaneKey.currentState?.reload();
        sub?.cancel();
      },
    );
  }

  void _handleDownload() {
    final remoteItem = _selectedRemoteItem;
    if (remoteItem == null || remoteItem.isDirectory) return;

    final localDest =
        '$_currentLocalPath${Platform.pathSeparator}${remoteItem.name}';
    final transferId = 'transfer-${DateTime.now().millisecondsSinceEpoch}';
    final transferItem = FileTransferItem(
      id: transferId,
      fileName: remoteItem.name,
      sourcePath: remoteItem.path,
      destinationPath: localDest,
      direction: TransferDirection.download,
      status: TransferStatus.inProgress,
    );

    setState(() {
      _transfers.add(transferItem);
    });

    final stream = widget.sftpSession.downloadFile(
      remotePath: remoteItem.path,
      localPath: localDest,
    );

    StreamSubscription<double>? sub;
    sub = stream.listen(
      (progress) {
        _updateTransfer(transferId, progress: progress);
      },
      onError: (err) {
        _updateTransfer(
          transferId,
          status: TransferStatus.failed,
          errorMessage: err.toString(),
        );
        sub?.cancel();
      },
      onDone: () {
        _updateTransfer(
          transferId,
          progress: 1.0,
          status: TransferStatus.completed,
        );
        _localPaneKey.currentState?.reload();
        sub?.cancel();
      },
    );
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
          t.status == TransferStatus.failed);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Two Panes (Split 50/50)
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: LocalFilePane(
                  key: _localPaneKey,
                  onSelectionChanged: (entity) {
                    setState(() => _selectedLocalEntity = entity);
                  },
                  onPathChanged: (path) => _currentLocalPath = path,
                  onUploadSelected: _handleUpload,
                ),
              ),
              Expanded(
                child: RemoteFilePane(
                  key: _remotePaneKey,
                  session: widget.sftpSession,
                  onSelectionChanged: (item) {
                    setState(() => _selectedRemoteItem = item);
                  },
                  onPathChanged: (path) => _currentRemotePath = path,
                  onDownloadSelected: _handleDownload,
                ),
              ),
            ],
          ),
        ),

        // Bottom Transfer Queue
        TransferQueueBar(
          transfers: _transfers,
          onClearCompleted: _clearCompletedTransfers,
        ),
      ],
    );
  }
}
