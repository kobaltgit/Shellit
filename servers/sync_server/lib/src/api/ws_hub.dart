import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Manages real-time WebSocket connections for active Shellit clients.
class WsHub {
  final Map<String, Set<WebSocketChannel>> _vaultChannels = {};

  /// Registers a new active channel for a [vaultId].
  void addChannel(String vaultId, WebSocketChannel channel) {
    _vaultChannels
        .putIfAbsent(vaultId, () => <WebSocketChannel>{})
        .add(channel);

    channel.stream.listen(
      (message) {
        // Can handle incoming client ping or keepalive
      },
      onDone: () {
        removeChannel(vaultId, channel);
      },
      onError: (e) {
        removeChannel(vaultId, channel);
      },
    );
  }

  /// Unregisters an active channel.
  void removeChannel(String vaultId, WebSocketChannel channel) {
    _vaultChannels[vaultId]?.remove(channel);
    if (_vaultChannels[vaultId]?.isEmpty ?? false) {
      _vaultChannels.remove(vaultId);
    }
  }

  /// Broadcasts a revision notification to all connected clients for a vault.
  void broadcastRevision(String vaultId, int revision) {
    final channels = _vaultChannels[vaultId];
    if (channels == null || channels.isEmpty) return;

    final message = jsonEncode({
      'type': 'new_revision',
      'vaultId': vaultId,
      'revision': revision,
      'timestamp': DateTime.now().toIso8601String(),
    });

    for (final ch in channels) {
      try {
        ch.sink.add(message);
      } catch (_) {}
    }
  }
}
