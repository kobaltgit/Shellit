import 'package:flutter/material.dart';
import '../../theme/shellit_theme.dart';

enum TransferDirection { upload, download }

enum TransferStatus { queued, inProgress, completed, failed }

class FileTransferItem {
  final String id;
  final String fileName;
  final String sourcePath;
  final String destinationPath;
  final TransferDirection direction;
  final double progress; // 0.0 to 1.0
  final TransferStatus status;
  final String? errorMessage;

  const FileTransferItem({
    required this.id,
    required this.fileName,
    required this.sourcePath,
    required this.destinationPath,
    required this.direction,
    this.progress = 0.0,
    this.status = TransferStatus.queued,
    this.errorMessage,
  });

  FileTransferItem copyWith({
    double? progress,
    TransferStatus? status,
    String? errorMessage,
  }) {
    return FileTransferItem(
      id: id,
      fileName: fileName,
      sourcePath: sourcePath,
      destinationPath: destinationPath,
      direction: direction,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class TransferQueueBar extends StatelessWidget {
  final List<FileTransferItem> transfers;
  final VoidCallback? onClearCompleted;

  const TransferQueueBar({
    super.key,
    required this.transfers,
    this.onClearCompleted,
  });

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const SizedBox.shrink();
    }

    final activeTransfers = transfers
        .where((t) =>
            t.status == TransferStatus.inProgress ||
            t.status == TransferStatus.queued)
        .toList();

    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: ShellitColors.obsidianHeader,
        border: Border(top: BorderSide(color: ShellitColors.border, width: 1)),
      ),
      child: Row(
        children: [
          const Icon(Icons.swap_vert,
              size: 18, color: ShellitColors.accentBlue),
          const SizedBox(width: 8),
          Text(
            'Transfers (${activeTransfers.length} active, ${transfers.length} total)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
          const SizedBox(width: 14),

          // Horizontal list of active transfers
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: transfers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final item = transfers[index];
                final isUpload = item.direction == TransferDirection.upload;
                final pct = (item.progress * 100).toInt();

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ShellitColors.obsidianCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.status == TransferStatus.failed
                          ? ShellitColors.statusRed
                          : ShellitColors.border,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isUpload ? Icons.upload : Icons.download,
                        size: 14,
                        color: isUpload
                            ? ShellitColors.accentCyan
                            : ShellitColors.accentBlue,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.fileName,
                        style: const TextStyle(
                            fontSize: 11, color: ShellitColors.textPrimary),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: item.status == TransferStatus.completed
                                ? 1.0
                                : item.progress,
                            minHeight: 4,
                            backgroundColor: ShellitColors.border,
                            valueColor: AlwaysStoppedAnimation(
                              item.status == TransferStatus.failed
                                  ? ShellitColors.statusRed
                                  : (item.status == TransferStatus.completed
                                      ? ShellitColors.statusGreen
                                      : ShellitColors.accentBlue),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        item.status == TransferStatus.completed
                            ? '100%'
                            : (item.status == TransferStatus.failed
                                ? 'ERR'
                                : '$pct%'),
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'JetBrains Mono',
                          color: item.status == TransferStatus.failed
                              ? ShellitColors.statusRed
                              : (item.status == TransferStatus.completed
                                  ? ShellitColors.statusGreen
                                  : ShellitColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          if (onClearCompleted != null)
            TextButton(
              onPressed: onClearCompleted,
              child: const Text('Clear', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
