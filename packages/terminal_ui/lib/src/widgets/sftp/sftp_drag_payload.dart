/// Drag-and-drop payload models for SFTP panes.
library;

/// Payload for files/directories dragged from the local file pane.
class SftpLocalDragPayload {
  final List<String> paths;
  const SftpLocalDragPayload(this.paths);
}

/// Payload for items dragged from the remote file pane.
class SftpRemoteDragPayload {
  final List<String> paths;
  const SftpRemoteDragPayload(this.paths);
}
