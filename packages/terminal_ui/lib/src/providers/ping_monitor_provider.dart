import 'dart:async';
import 'dart:io';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'hosts_provider.dart';

/// Health status category based on RTT latency.
enum PingStatus {
  fast, // < 50ms - Green
  medium, // < 200ms - Yellow
  slow, // >= 200ms - Orange
  offline, // Unreachable / Timeout - Grey
}

extension PingLatencyX on int? {
  PingStatus get pingStatus {
    if (this == null || this! < 0) return PingStatus.offline;
    if (this! < 50) return PingStatus.fast;
    if (this! < 200) return PingStatus.medium;
    return PingStatus.slow;
  }
}

/// Optional client service injection for network ping.
final sshClientServiceProvider = Provider<ISshClientService?>((ref) => null);

/// State of ping monitor: map of hostId -> latencyMs.
class PingMonitorState {
  final Map<String, int?> latencies;
  final bool isMonitoring;

  const PingMonitorState({
    this.latencies = const {},
    this.isMonitoring = false,
  });

  PingStatus statusFor(String hostId) {
    return latencies[hostId].pingStatus;
  }

  int? latencyFor(String hostId) {
    return latencies[hostId];
  }

  PingMonitorState copyWith({
    Map<String, int?>? latencies,
    bool? isMonitoring,
  }) {
    return PingMonitorState(
      latencies: latencies ?? this.latencies,
      isMonitoring: isMonitoring ?? this.isMonitoring,
    );
  }
}

/// Notifier that periodically pings hosts.
class PingMonitorNotifier extends StateNotifier<PingMonitorState> {
  final Ref _ref;
  Timer? _timer;

  PingMonitorNotifier(this._ref, {bool autoStart = false})
      : super(const PingMonitorState()) {
    if (autoStart) {
      startMonitoring();
    }
  }

  void startMonitoring({Duration interval = const Duration(seconds: 15)}) {
    _timer?.cancel();
    state = state.copyWith(isMonitoring: true);
    // Initial ping
    pingAllHosts();
    _timer = Timer.periodic(interval, (_) => pingAllHosts());
  }

  void stopMonitoring() {
    _timer?.cancel();
    _timer = null;
    state = state.copyWith(isMonitoring: false);
  }

  Future<void> pingAllHosts() async {
    final hosts = _ref.read(hostsProvider);
    for (final host in hosts) {
      pingHost(host);
    }
  }

  Future<int?> pingHost(HostEntity host) async {
    final clientService = _ref.read(sshClientServiceProvider);
    int? latency;

    if (clientService != null) {
      final res = await clientService.pingHost(host.hostname, host.port);
      latency = res.when(
        success: (ms) => ms,
        error: (_) => null,
      );
    } else {
      // Direct TCP socket measurement fallback
      try {
        final stopwatch = Stopwatch()..start();
        final socket = await Socket.connect(
          host.hostname,
          host.port,
          timeout: const Duration(seconds: 3),
        );
        stopwatch.stop();
        socket.destroy();
        latency = stopwatch.elapsedMilliseconds;
      } catch (_) {
        // If not reachable or error, keep null
        latency = null;
      }
    }

    final updated = Map<String, int?>.from(state.latencies);
    updated[host.id] = latency;
    state = state.copyWith(latencies: updated);

    // Also update host entity in hostsProvider
    _ref.read(hostsProvider.notifier).updateHostLatency(host.id, latency);
    return latency;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final pingMonitorProvider =
    StateNotifierProvider<PingMonitorNotifier, PingMonitorState>((ref) {
  return PingMonitorNotifier(ref);
});
