import 'package:core_foundation/core_foundation.dart';
import '../../providers/session_manager_provider.dart';

/// Payload carried during Tab drag and drop operations.
class TabDragPayload {
  final String tabId;
  final HostEntity? host;
  final String title;
  final TabType type;

  const TabDragPayload({
    required this.tabId,
    this.host,
    required this.title,
    required this.type,
  });
}
