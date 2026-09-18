import 'dart:async';
import 'package:core_foundation/core_foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Optional dependency injection for IFolderRepository.
final folderRepositoryProvider = Provider<IFolderRepository?>((ref) => null);

/// Folders State Notifier managing list of folders and CRUD operations.
class FoldersNotifier extends StateNotifier<List<FolderEntity>> {
  final IFolderRepository? _repository;
  StreamSubscription<List<FolderEntity>>? _subscription;

  FoldersNotifier(this._repository) : super([]) {
    _loadFolders();
  }

  Future<void> _loadFolders() async {
    final repo = _repository;
    if (repo != null) {
      final folders = await repo.getAllFolders();
      if (mounted) {
        state = folders;
      }
      _subscription = repo.watchAllFolders().listen((updatedList) {
        if (mounted) {
          state = updatedList;
        }
      });
    } else {
      // Default sample folders if repository is not injected
      state = [
        const FolderEntity(id: 'folder-prod', name: 'Production Servers'),
        const FolderEntity(id: 'folder-stage', name: 'Staging & QA'),
        const FolderEntity(id: 'folder-homelab', name: 'HomeLab & NAS'),
      ];
    }
  }

  Future<Result<FolderEntity, VaultFailure>> createFolder({
    required String name,
    String? parentId,
    String? colorHex,
    String? iconName,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final folder = FolderEntity(
      id: 'folder-$now',
      name: name.trim(),
      parentId: parentId,
      colorHex: colorHex,
      iconName: iconName,
      sortOrder: state.length,
    );

    final repo = _repository;
    if (repo != null) {
      final res = await repo.saveFolder(folder);
      if (res.isSuccess) {
        if (!state.any((f) => f.id == folder.id)) {
          state = [...state, folder];
        }
        return Result.success(folder);
      }
      return Result.error(res.failureOrNull ??
          const VaultFailure(
            'Failed to create folder',
            type: VaultFailureType.ioError,
          ));
    } else {
      state = [...state, folder];
      return Result.success(folder);
    }
  }

  Future<Result<void, VaultFailure>> deleteFolder(String folderId) async {
    final repo = _repository;
    if (repo != null) {
      final res = await repo.deleteFolder(folderId);
      if (res.isSuccess) {
        state = state.where((f) => f.id != folderId).toList();
      }
      return res;
    } else {
      state = state.where((f) => f.id != folderId).toList();
      return const Result.success(null);
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final foldersProvider =
    StateNotifierProvider<FoldersNotifier, List<FolderEntity>>((ref) {
  final repo = ref.watch(folderRepositoryProvider);
  return FoldersNotifier(repo);
});
