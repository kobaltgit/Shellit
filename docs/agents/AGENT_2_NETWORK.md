# Инструкция для Агента 2: Network, SSH & SFTP Team

## 1. Роль и зона ответственности
* **Пакет:** `packages/ssh_network_core/`
* **Миссия:** Построение высокопроизводительного, отказоустойчивого сетевого ядра для SSH-сессий, двунаправленных PTY-потоков, SFTP-файлового менеджера и туннелирования портов.

---

## 2. Ключевые технологические решения
* **SSH-клиент:** `dartssh2` (чистый Dart, кроссплатформенный, поддерживает современные шифросьюты).
* **Поддерживаемая аутентификация:**
  * Пароль (Password authentication).
  * Приватные ключи: Ed25519 (приоритетно), RSA (PKCS#1, PKCS#8), ECDSA с поддержкой passphrase.
  * Интерактивная клавиатурная аутентификация (Keyboard-Interactive / 2FA / OTP).
* **Сетевые потоки (PTY):**
  * Запрос псевдотерминала (`xterm-256color` по умолчанию).
  * Корректный двусторонний пайплайн: `stdin` (Sink) и объединенный/раздельный `stdout` + `stderr` (Streams).
  * Динамическое изменение геометрии терминала через вызов `session.resizeTerminal(cols, rows)`.
* **Keep-Alive и реконнект:** Фоновый пинг SSH-канала для предотвращения обрывов по таймауту NAT-шлюзов.

---

## 3. Функциональные модули
1. **`SshSessionManager`:**
   * Управление жизненным циклом сессий (Connect, Authenticate, Disconnect, Reconnect).
   * Поддержка состояния сессии: `connecting`, `authenticating`, `ready`, `disconnected`, `error`.
   * Измерение RTT (Ping / Latency) до целевого сервера в миллисекундах.
2. **`SftpClientService`:**
   * Навигация по удаленной файловой системе (`listDirectory`, `stat`).
   * Потоковая загрузка (Download) и выгрузка (Upload) файлов с отчетностью о прогрессе (bytes transferred / total bytes).
   * Базовые операции: удаление, переименование, создание директорий, изменение прав доступа (chmod).
3. **`PortForwardingService`:**
   * **Local Port Forwarding:** Проброс локального порта машины на удаленный сервис через SSH-туннель (`127.0.0.1:localPort -> remoteHost:remotePort`).
   * **Remote Port Forwarding:** Обратный проброс (Reverse tunnel).

---

## 4. Контракты интерфейсов (реализация из `core_foundation`)
* `ISshClientService`:
  ```dart
  abstract class ISshClientService {
    Future<Result<ITerminalSession, NetworkFailure>> createSession({
      required HostConnectionConfig config,
      required TerminalDimensions initialDimensions,
    });
    Future<Result<ISftpSession, NetworkFailure>> openSftp(String sessionId);
  }
  ```
* `ITerminalSession`:
  * `Stream<Uint8List> get outputStream;`
  * `Sink<Uint8List> get inputStream;`
  * `void resize(int cols, int rows);`
  * `Future<void> terminate();`
  * `Stream<SessionState> get stateStream;`

---

## 5. Чек-лист проверки качества
- [ ] Успешное подключение и авторизация по Ed25519 и RSA ключам.
- [ ] Безошибочная передача бинарных управляющих последовательностей ANSI и UTF-8.
- [ ] Корректная обработка внезапного обрыва соединения (socket closed / reset by peer) без падения приложения.
- [ ] Тесты SFTP на потоковую передачу файлов с прогресс-баром.
- [ ] 0 предупреждений анализатора Dart.
