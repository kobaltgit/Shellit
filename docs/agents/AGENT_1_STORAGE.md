# Инструкция для Агента 1: Storage, Security & Vault Team

## 1. Роль и зона ответственности
* **Пакет:** `packages/storage_vault/`
* **Миссия:** Построение абсолютно защищенного, надежного и быстрого хранилища учетных записей, хостов, ключей и настроек с защитой мастер-паролем (AES-256 / SQLCipher).

---

## 2. Ключевые технологические решения
* **База данных:** `drift` + `sqlcipher` (реактивный доступ к данным через Streams, типобезопасные запросы).
* **Деривация мастер-ключа (KDF):** `Argon2id` (с солью и настраиваемой сложностью памяти) для генерации рабочего ключа шифрования БД из пользовательского мастер-пароля.
* **Быстрый доступ и биометрия:** 
  * Интеграция с биометрией ОС (`local_auth` / `flutter_secure_storage`): Windows Hello, Touch ID / Face ID на macOS/iOS, биометрия Android.
  * Опциональный короткий 4-6 значный PIN-код для быстрой разблокировки между сессиями.
* **Политика автоблокировки:**
  * Настраиваемый таймер неактивности (по умолчанию 15 минут).
  * Автоблокировка при сворачивании окна приложения или уходе системы в сон.
  * Мгновенная блокировка по шорткату `Ctrl+L` / `Cmd+L`.
* **Работа с оперативной памятью:** Чувствительные данные (пароли, приватные ключи) после дешифрования и передачи в сетевой слой должны стираться из буфера (zeroize). При блокировке хранилища рабочий ключ шифрования стирается из памяти.

---

## 3. Сущности предметной области (Data Models)
Агент 1 реализует и маппит сущности из `core_foundation`:
1. `HostEntity`:
   * `id`: UUID
   * `label`: String (пользовательское имя сервера, например "Prod Web 01")
   * `hostname`: String (IP или домен)
   * `port`: int (по умолчанию 22)
   * `username`: String
   * `authType`: HostAuthType (password, privateKey, agent, none)
   * `credentialRefId`: String? (ссылка на запись в Keychain / KeyEntity)
   * `folderId`: String? (для иерархической группировки)
   * `tags`: List<String>
   * `environment`: HostEnvironment (production, staging, development, default)
   * `osType`: OsType (ubuntu, debian, centos, alpine, arch, genericServer, router, etc.)
   * `createdAt`, `updatedAt`, `lastConnectedAt`: DateTime?
2. `KeyEntity`:
   * `id`: UUID
   * `label`: String
   * `keyType`: KeyType (ed25519, rsa, ecdsa)
   * `encryptedPrivateKey`: Uint8List (зашифрованный приватный ключ)
   * `publicKey`: String
   * `passphraseEncrypted`: Uint8List?
3. `FolderEntity`:
   * `id`: UUID, `parentId`: String?, `name`: String, `color`: String?
4. `SnippetEntity`:
   * `id`: UUID, `title`: String, `command`: String, `tags`: List<String>
5. `VaultSettingsEntity`:
   * Настройки автоблокировки по таймеру (idle lock timeout), биометрия, цветовая палитра.

---

## 4. Контракты для взаимодействия
Агент 1 реализует следующие интерфейсы из `core_foundation`:
* `IVaultRepository` — статус хранилища (locked/unlocked), инициализация, смена мастер-пароля, блокировка.
* `IHostRepository` — CRUD для хостов, получение стрима `watchAllHosts()`, фильтрация по папкам и тегам.
* `IKeyManager` — безопасное извлечение и расшифровка ключей по ID для передачи Агенту 2.

---

## 5. Чек-лист проверки качества
- [ ] База данных создается и шифруется с использованием SQLCipher.
- [ ] Попытка открыть БД с неверным паролем возвращает строго типизированную ошибку `VaultAuthFailure`.
- [ ] При блокировке хранилища все кэшированные ключи шифрования в памяти обнуляются.
- [ ] Миграции схемы данных протестированы юнит-тестами.
- [ ] 0 предупреждений анализатора Dart.
