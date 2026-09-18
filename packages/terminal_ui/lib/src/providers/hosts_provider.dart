import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Filter state for hosts list.
class HostFilterState {
  final String searchQuery;
  final String? selectedFolderId;
  final String? selectedTag;
  final HostEnvironment? selectedEnv;

  const HostFilterState({
    this.searchQuery = '',
    this.selectedFolderId,
    this.selectedTag,
    this.selectedEnv,
  });

  HostFilterState copyWith({
    String? searchQuery,
    String? Function()? selectedFolderId,
    String? Function()? selectedTag,
    HostEnvironment? Function()? selectedEnv,
  }) {
    return HostFilterState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedFolderId:
          selectedFolderId != null ? selectedFolderId() : this.selectedFolderId,
      selectedTag: selectedTag != null ? selectedTag() : this.selectedTag,
      selectedEnv: selectedEnv != null ? selectedEnv() : this.selectedEnv,
    );
  }
}

/// Optional dependency injection for IHostRepository.
final hostRepositoryProvider = Provider<IHostRepository?>((ref) => null);

/// Optional dependency injection for IKeyManager.
final keyManagerProvider = Provider<IKeyManager?>((ref) => null);

/// Filter provider
final hostFilterProvider =
    StateProvider<HostFilterState>((ref) => const HostFilterState());

/// Hosts State Notifier managing host list and operations.
class HostsNotifier extends StateNotifier<List<HostEntity>> {
  final IHostRepository? _repository;

  HostsNotifier(this._repository) : super([]) {
    _loadHosts();
  }

  Future<void> _loadHosts() async {
    if (_repository != null) {
      final hosts = await _repository!.getAllHosts();
      state = hosts;
      _repository!.watchAllHosts().listen((updatedList) {
        state = updatedList;
      });
    } else {
      // Seed sample hosts for preview / test
      final now = DateTime.now();
      state = [
        HostEntity(
          id: 'host-1',
          label: 'Production Web 01',
          hostname: 'prod-web01.internal',
          port: 22,
          username: 'deploy',
          authType: HostAuthType.privateKey,
          environment: HostEnvironment.production,
          osType: OsType.ubuntu,
          tags: const ['web', 'frontend', 'k8s'],
          dangerousCommandProtection: true,
          lastPingLatencyMs: 32,
          createdAt: now,
          updatedAt: now,
        ),
        HostEntity(
          id: 'host-2',
          label: 'Staging DB Master',
          hostname: '10.0.4.12',
          port: 2222,
          username: 'postgres',
          authType: HostAuthType.password,
          environment: HostEnvironment.staging,
          osType: OsType.debian,
          tags: const ['db', 'postgres'],
          lastPingLatencyMs: 145,
          createdAt: now,
          updatedAt: now,
        ),
        HostEntity(
          id: 'host-3',
          label: 'Dev Sandbox',
          hostname: 'dev.sandbox.local',
          port: 22,
          username: 'root',
          authType: HostAuthType.privateKey,
          environment: HostEnvironment.development,
          osType: OsType.alpine,
          tags: const ['sandbox', 'docker'],
          lastPingLatencyMs: 18,
          createdAt: now,
          updatedAt: now,
        ),
        HostEntity(
          id: 'host-4',
          label: 'Backup Storage Gateway',
          hostname: '192.168.100.5',
          port: 22,
          username: 'admin',
          authType: HostAuthType.password,
          environment: HostEnvironment.defaultEnv,
          osType: OsType.genericServer,
          tags: const ['storage', 'nfs'],
          lastPingLatencyMs: null, // offline
          createdAt: now,
          updatedAt: now,
        ),
      ];
    }
  }

  Future<Result<void, VaultFailure>> addHost(HostEntity host) async {
    if (_repository != null) {
      final res = await _repository!.saveHost(host);
      if (res.isSuccess) {
        if (!state.any((h) => h.id == host.id)) {
          state = [...state, host];
        }
      }
      return res;
    } else {
      state = [...state, host];
      return const Result.success(null);
    }
  }

  Future<Result<void, VaultFailure>> updateHost(HostEntity host) async {
    if (_repository != null) {
      final res = await _repository!.saveHost(host);
      if (res.isSuccess) {
        state = [
          for (final h in state)
            if (h.id == host.id) host else h,
        ];
      }
      return res;
    } else {
      state = [
        for (final h in state)
          if (h.id == host.id) host else h,
      ];
      return const Result.success(null);
    }
  }

  Future<Result<void, VaultFailure>> deleteHost(String hostId) async {
    if (_repository != null) {
      final res = await _repository!.deleteHost(hostId);
      if (res.isSuccess) {
        state = state.where((h) => h.id != hostId).toList();
      }
      return res;
    } else {
      state = state.where((h) => h.id != hostId).toList();
      return const Result.success(null);
    }
  }

  void updateHostLatency(String hostId, int? latencyMs) {
    state = [
      for (final h in state)
        if (h.id == hostId) h.copyWith(lastPingLatencyMs: latencyMs) else h,
    ];
    if (_repository != null && latencyMs != null) {
      _repository!.updateHostLatency(hostId, latencyMs);
    }
  }
}

final hostsProvider =
    StateNotifierProvider<HostsNotifier, List<HostEntity>>((ref) {
  final repo = ref.watch(hostRepositoryProvider);
  return HostsNotifier(repo);
});

/// Filtered hosts provider
final filteredHostsProvider = Provider<List<HostEntity>>((ref) {
  final hosts = ref.watch(hostsProvider);
  final filter = ref.watch(hostFilterProvider);

  return hosts.where((host) {
    if (filter.searchQuery.isNotEmpty) {
      final query = filter.searchQuery.toLowerCase();
      final matchesLabel = host.label.toLowerCase().contains(query);
      final matchesHost = host.hostname.toLowerCase().contains(query);
      final matchesUser = host.username.toLowerCase().contains(query);
      final matchesTags = host.tags.any((t) => t.toLowerCase().contains(query));
      if (!matchesLabel && !matchesHost && !matchesUser && !matchesTags) {
        return false;
      }
    }

    if (filter.selectedFolderId != null &&
        host.folderId != filter.selectedFolderId) {
      return false;
    }

    if (filter.selectedTag != null && !host.tags.contains(filter.selectedTag)) {
      return false;
    }

    if (filter.selectedEnv != null && host.environment != filter.selectedEnv) {
      return false;
    }

    return true;
  }).toList();
});
