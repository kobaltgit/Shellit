import 'package:core_foundation/core_foundation.dart';
import 'package:storage_vault/storage_vault.dart';
import 'package:test/test.dart';

void main() {
  group('FolderRepository and SnippetRepository', () {
    late VaultDatabase db;
    late VaultSecurityContext securityContext;
    late VaultCryptoService cryptoService;
    late VaultRepository vaultRepository;
    late FolderRepository folderRepository;
    late SnippetRepository snippetRepository;

    setUp(() async {
      db = VaultDatabaseConnection.inMemory();
      securityContext = VaultSecurityContext();
      cryptoService = VaultCryptoService(
        argon2Memory: 1024,
        argon2Iterations: 2,
        argon2Parallelism: 1,
        argon2HashLength: 32,
      );

      vaultRepository = VaultRepository(
        db: db,
        cryptoService: cryptoService,
        securityContext: securityContext,
      );

      folderRepository = FolderRepository(
        db: db,
        securityContext: securityContext,
      );

      snippetRepository = SnippetRepository(
        db: db,
        securityContext: securityContext,
      );

      await vaultRepository.initializeVault('MasterPass');
    });

    tearDown(() async {
      await vaultRepository.dispose();
      await db.close();
    });

    test('FolderRepository CRUD and watchAllFolders', () async {
      const folder1 = FolderEntity(
        id: 'f-1',
        name: 'Databases',
        colorHex: '#FF5733',
        sortOrder: 1,
      );
      const folder2 = FolderEntity(
        id: 'f-2',
        name: 'Web Servers',
        parentId: 'f-1',
        sortOrder: 2,
      );

      final save1 = await folderRepository.saveFolder(folder1);
      final save2 = await folderRepository.saveFolder(folder2);
      expect(save1.isSuccess, isTrue);
      expect(save2.isSuccess, isTrue);

      final folders = await folderRepository.getAllFolders();
      expect(folders.length, equals(2));
      expect(folders.first.name, equals('Databases'));
      expect(folders.last.parentId, equals('f-1'));

      final del = await folderRepository.deleteFolder('f-2');
      expect(del.isSuccess, isTrue);

      final remaining = await folderRepository.getAllFolders();
      expect(remaining.length, equals(1));
    });

    test('SnippetRepository CRUD and watchAllSnippets', () async {
      final now = DateTime.now();
      final snippet1 = SnippetEntity(
        id: 's-1',
        title: 'Docker Logs Follow',
        command: 'docker logs -f --tail 100 app',
        tags: ['docker', 'logs'],
        createdAt: now,
        updatedAt: now,
      );

      final save = await snippetRepository.saveSnippet(snippet1);
      expect(save.isSuccess, isTrue);

      final list = await snippetRepository.getAllSnippets();
      expect(list.length, equals(1));
      expect(list.first.title, equals('Docker Logs Follow'));
      expect(list.first.tags, equals(['docker', 'logs']));

      final del = await snippetRepository.deleteSnippet('s-1');
      expect(del.isSuccess, isTrue);

      final emptyList = await snippetRepository.getAllSnippets();
      expect(emptyList.isEmpty, isTrue);
    });
  });
}
