import 'package:flutter/material.dart';
import '../../localization/localization_scope.dart';
import '../../theme/shellit_theme.dart';

enum TransferDirection { upload, download }

enum TransferStatus { queued, inProgress, completed, failed, cancelled }

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
  final ValueChanged<String>? onCancelTransfer;
  final VoidCallback? onCancelAll;

  const TransferQueueBar({
    super.key,
    required this.transfers,
    this.onClearCompleted,
    this.onCancelTransfer,
    this.onCancelAll,
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
      height: 44,
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
            context.tr(
              'sftp.transfers_summary',
              defaultText: 'Transfers ({active} active, {total} total)',
              namedArgs: {
                'active': activeTransfers.length.toString(),
                'total': transfers.length.toString(),
              },
            ),
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
                final isActive = item.status == TransferStatus.inProgress ||
                    item.status == TransferStatus.queued;

                Color statusColor;
                String statusLabel;
                if (item.status == TransferStatus.completed) {
                  statusColor = ShellitColors.statusGreen;
                  statusLabel = '100%';
                } else if (item.status == TransferStatus.failed) {
                  statusColor = ShellitColors.statusRed;
                  statusLabel = 'ERR';
                } else if (item.status == TransferStatus.cancelled) {
                  statusColor = ShellitColors.statusYellow;
                  statusLabel = 'CANCEL';
                } else {
                  statusColor = ShellitColors.accentBlue;
                  statusLabel = '$pct%';
                }

                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ShellitColors.obsidianCard,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: item.status == TransferStatus.failed
                          ? ShellitColors.statusRed
                          : (item.status == TransferStatus.cancelled
                              ? ShellitColors.statusYellow
                                  .withValues(alpha: 0.5)
                              : ShellitColors.border),
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
                        width: 46,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: item.status == TransferStatus.completed
                                ? 1.0
                                : item.progress,
                            minHeight: 4,
                            backgroundColor: ShellitColors.border,
                            valueColor: AlwaysStoppedAnimation(statusColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontFamily: 'JetBrains Mono',
                          color: statusColor,
                        ),
                      ),
                      if (isActive && onCancelTransfer != null) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () => onCancelTransfer!(item.id),
                          borderRadius: BorderRadius.circular(10),
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close,
                                size: 12, color: ShellitColors.textMuted),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          if (onCancelAll != null && activeTransfers.isNotEmpty) ...[
            const SizedBox(width: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.stop_circle_outlined,
                  size: 14, color: ShellitColors.statusRed),
              label: Text(
                context.tr('sftp.cancel_all', defaultText: 'Cancel All'),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: ShellitColors.statusRed),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: ShellitColors.statusRed),
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: onCancelAll,
            ),
          ],

          if (onClearCompleted != null)
            TextButton(
              onPressed: onClearCompleted,
              child: Text(context.tr('common.clear', defaultText: 'Clear'),
                  style: const TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
