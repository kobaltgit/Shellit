# Мастер-чеклист разработки Shellit (Interactive Checklist)

Используется для сквозного отслеживания прогресса всеми агентами и ведущим разработчиком. По мере готовности пунктов флаги меняются с `[ ]` на `[x]`.

---

## Фаза 0: Инфраструктура и Контракты
- [x] Разработка генеральной инструкции для агентов (`docs/AGENTS_MASTER_GUIDE.md`).
- [x] Создание инструкций для всех ролей (`docs/agents/`).
- [x] Формирование дорожной карты (`docs/ROADMAP.md`).
- [x] Развертывание оперативного трекера багов (`docs/BUGS_AND_ISSUES.md`).
- [x] Создание банка идей и предложений (`docs/IDEAS_AND_BACKLOG.md`).
- [x] Запуск летописи проекта (`docs/CHRONICLE.md`).
- [x] Регистрация всех 4 специализированных субагентов + Летописца в Antigravity.
- [x] Создание базового пакета `packages/core_foundation`:
  - [x] Базовые Result/Failure типы (`Result<T, Failure>`, иерархия `Failure`).
  - [x] Доменные сущности (`HostEntity`, `KeyEntity`, `FolderEntity`, `SnippetEntity`, `VaultSettingsEntity`).
  - [x] Перечисления (`HostEnvironment`, `HostAuthType`, `OsType`, `KeyType`, `SessionState`, `PluginTarget`).
  - [x] Абстрактные интерфейсы (`IVaultRepository`, `IHostRepository`, `IKeyManager`, `ISshClientService`, `ITerminalSession`, `ISftpSession`, `IPortForwardService`, `IPluginLoader`, `IPluginBridge`).
  - [x] Безопасный логгер `AppLogger` с санитизацией секретов и ключей.
  - [x] 100% прохождение тестов и `dart analyze` (0 warnings, 0 errors).

---

## Фаза 1: Параллельная разработка ядра

### Модуль `storage_vault` (Агент 1)
- [x] Подключение Drift + SQLCipher.
- [x] Реализация KDF (Argon2id) для деривации ключа БД из мастер-пароля.
- [x] Реализация таблиц хостов, ключей, папок, сниппетов, настроек и метаданных.
- [x] Репозиторий `HostRepository` (CRUD, реактивные стримы `watchAll()`).
- [x] Репозиторий `KeyManager` с безопасной дешифрацией приватных ключей.
- [x] Безопасная очистка памяти (Zeroize) после отдачи секретов.
- [x] Юнит-тесты: открытие базы с верным/неверным паролем, проверка целостности (27/27 тестов успешно).

### Модуль `ssh_network_core` (Агент 2)
- [x] Интеграция `dartssh2`.
- [x] Парсер и загрузчик ключей (Ed25519, RSA, ECDSA, с passphrase и без).
- [x] `SshSessionManager`: авторизация по паролю и ключам, обработка таймаутов и обрывов.
- [x] Поддержка PTY: запрос псевдотерминала (`xterm-256color`), передача размеров (cols/rows), стримы `stdin`/`outputStream`.
- [x] Реализация `SftpSession` (листинг папок, потоковая загрузка/выгрузка файлов, рекурсивные операции).
- [x] Реализация `PortForwardService` (Local/Remote туннелирование).
- [x] Юнит-тесты сетевых обработчиков, PTY-сессий, SFTP и парсеров ключей (35/35 тестов успешно).

### Модуль `desktop_plugin_sdk` (Агент 4)
- [x] Определение схемы и валидатора `manifest.json`.
- [x] Реализация `PluginPackageExtractor` (безопасная распаковка `.shell-plugin` с защитой от Zip Slip и Zip Bomb).
- [x] Спецификация JSON-RPC сообщений и песочница с разграничением прав (`IPluginBridge`).
- [x] Изолированные заглушки для мобильных платформ (No-Op loader).
- [x] Юнит-тесты валидации, распаковки и IPC (33/33 теста успешно).

---

## Фаза 2: Терминальный UI и интеграция

### Модуль `terminal_ui` (Агент 3)
- [x] Создание адаптивного App Shell:
  - [x] Левый сайдбар (Hosts, Keychain, Tunnels, Snippets, Logs, Settings) с автосворачиванием на экранах < 800px.
  - [x] Верхний Top Bar (Vault selector, строка быстрого коннекта, вкладки сессий).
  - [x] Полноценная система вкладок (Termius-like):
    - [x] Закрепленная вкладка «Hosts» и кнопка «+» для постоянного доступа к каталогу.
    - [x] Неограниченное количество вкладок хостов (Terminal, SFTP, Splits).
    - [x] Отдельные вкладки SFTP с выделенным оформлением (иконка, акцент, бейдж).
    - [x] Сохранение состояния сессий без потерь вывода/передач при переключении (`IndexedStack`).
    - [x] Быстрый вызов SFTP прямо из запущенного терминала.
    - [x] Расширенное управление вкладками, Drag & Drop в сплиты и адаптация переполнения:
      - [x] Перетаскивание (Drag & Drop) вкладок сессий прямо в пустые слоты сплит-панелей с автоматическим исчезновением из верхнего бара и кнопкой извлечения (Undock / `[↗]`) обратно во вкладку.
      - [x] Контекстное меню вкладок по правому клику / вторичному нажатию: Duplicate Session, Open SFTP, Reconnect, Split (H/V/2x2/Collapse), Rename Tab, Set Color Tag (палитра 6 оттенков), Pin/Unpin Tab, и гигиена закрытия (Close, Close Others, Close to the Right, Close Disconnected).
      - [x] Адаптация панели вкладок к большому числу открытых сессий: горизонтальная прокрутка колесом мыши без зажатия Shift, стрелки быстрой прокрутки `‹ / ›`, модальное меню переполнения `[ ⌄ N ]` с моментальным поиском/фильтрацией и переключение открытых вкладок через Omni-Bar (`Ctrl+K`).
- [x] Каталог хостов (Hosts Screen):
  - [x] Карточки хостов с бейджами ОС, индикатором пинга/задержки RTT и бейджами окружений (`PROD`, `DEV`, `STAGE`).
  - [x] Автоопределение ОС серверов через неблокирующий SSH exec-канал и отрисовка аутентичных векторных SVG-логотипов дистрибутивов (Termius-like: Ubuntu, Debian, Alpine, Arch, Fedora, CentOS, Rocky, Alma, Red Hat, FreeBSD, Raspberry Pi, macOS, Windows, Router).
  - [x] Переключение режимов: Grid View, Dense List, Folder Tree View.
- [x] Интеграция `xterm.dart`:
  - [x] Отрисовка ANSI-последовательностей, цветов TrueColor и цветовых схем (Obsidian Dark, Dracula, Nord, OLED True Black, Cyberpunk).
  - [x] Поддержка горячих клавиш копирования/вставки и масштабирования шрифта.
  - [x] Подключение стримов `ITerminalSession` к `TerminalView` с авторесайзом PTY.
  - [x] Защита PROD Guard (красная рамка и перехват опасных команд `rm -rf`, `reboot`, `shutdown`, `drop database`).
- [x] Omni-Bar / Command Palette (`Ctrl+K` / `Cmd+K`):
  - [x] Быстрый поиск и коннект к хосту, смена цветовой схемы и управление сплитами.
- [x] Двухпанельный SFTP-менеджер файлов (Termius-like):
  - [x] Локальная и удаленная панели с сортировкой и навигацией.
  - [x] Контекстное меню (по правому клику / долгому нажатию) для локальной и удаленной панелей: скачивание, выгрузка, переименование, удаление, chmod, копирование пути, создание файлов/папок.
  - [x] Интерактивный редактор прав chmod (матрица чекбоксов $3\times3$ и восьмеричная маска 0755/0644).
  - [x] Мгновенное автообновление панелей в реальном времени при завершении передачи или файловых операций (`reload()` по `onDone`).
  - [x] Исправление визуального стиля кнопки выгрузки (Upload) на левой панели (контрастный белый цвет вместо невидимого синего).
  - [x] Быстрые кнопки создания папок и файлов в тулбаре обеих панелей (`+ Directory`, `+ File`).
  - [x] Устранение наложения контекстных меню (`_itemRightClickHandled`) и 80px свободная область внизу списка.
  - [x] Расширение контракта `ISftpSession` методами `setPermissions` и `createFile` с реализацией через `dartssh2`.
  - [x] Нижняя панель очереди передач со стримингом прогресса.
- [x] Матричные сплиты и Broadcast:
  - [x] Режимы 1, 2 (вертикально/горизонтально), сетка 2x2 с фокусом по Alt+Arrows.
  - [x] Режим параллельного ввода (Broadcast Input) во все терминальные панели.
  - [x] Интерактивный Drag & Drop вкладок в пустые слоты сплита (`TabDragPayload`, `DragTarget`) с поглощением вкладки из верхнего бара.
  - [x] Инлайн-диалог выбора хоста (`HostSlotPickerDialog`) по кнопке «+» в пустом слоте сплита (мгновенный поиск, Quick Connect, прямое подключение в слот без переключения в каталог).
  - [x] Кнопка «Undock» (`[↗]`) для извлечения панели обратно в верхнюю вкладку с сохранением сплит-сетки и удержанием активного фокуса на текущем сплите.
  - [x] Реестр `TerminalSessionRegistry` для непрерывного сохранения буфера и истории терминала при перемещении в сплиты и переключении вкладок с мгновенным PTY resize на первом кадре.
- [x] Полнофункциональная система вкладок и адаптация к большому количеству серверов:
  - [x] Контекстное меню вкладок (`TabContextMenu`) по правому клику: Duplicate (`Ctrl+D`), Open SFTP, Reconnect, Split (H/V/Grid), Rename Tab, Set Color Tag (6 цветов), Pin/Unpin, Close Tab (`Ctrl+W`), Close Others, Close to the Right, Close Disconnected.
  - [x] Естественный горизонтальный скролл полосы вкладок колесиком мыши (без необходимости зажимать Shift).
  - [x] Динамические стрелки прокрутки `‹` и `›` при переполнении видимой области.
  - [x] Кнопка меню переполнения `[ ⌄ N ]` со счетчиком открытых сессий и всплывающим окном быстрого поиска (`TabOverflowMenuDialog`).
  - [x] Раздел «Open Tabs» в поисковой палитре Omni-Bar (`Ctrl+K`) для мгновенного перехода к любой открытой консоли.
- [x] Мобильная адаптация:
  - [x] Панель быстрых спецклавиш (Esc, Tab, Ctrl, Alt, |, /, ~, стрелки) с тактильным откликом (HapticFeedback).
- [x] Юнит- и виджет-тесты дизайн-системы, провайдеров, карточек, сплитов, Drag & Drop, контекстного меню и PROD Guard (194/194 теста успешно, 0 ошибок анализатора).

---

## Фаза 3: Сборка и запуск приложения Shellit (apps/shellit)
- [x] Инициализация рабочего Flutter-приложения `apps/shellit` со всеми платформами (Windows, macOS, Linux, Android, iOS).
- [x] Внедрение протокола Safe Build: переключение на Сбалансированную схему питания, перенос временных файлов на диск D: (140 ГБ), предотвращение BSOD 0x50 и перезагрузок.
- [x] Dependency Injection (`app_providers.dart`): связывание `storage_vault`, `ssh_network_core`, `desktop_plugin_sdk` и `terminal_ui`.
- [x] Экраны Keychain, Tunnels, Plugins и Settings в едином окне приложения в стиле Obsidian Dark.
- [x] Контроллер сессий `SessionConnectController`: запуск интерактивного терминала и двухпанельного SFTP.
- [x] Полный сквозной прогон всех тестов по всему монорепозиторию (132/132 теста успешно, 0 ошибок анализатора).

---

## Фаза 4: Финализация и Релиз
- [x] Менеджер сниппетов (Command Palette & библиотека команд, 1-click execute в терминал).
- [x] Экспорт и импорт зашифрованного бэкапа хранилища (`VaultBackupService`, контейнер .shellit-vault, AES-256-GCM + Argon2id).
- [x] Полноценная система системных логов и записи сессий (Logs & Audit Center):
  - [x] Реактивный кольцевой буфер `LogEntry` и broadcast-стрим в `AppLogger` (`core_foundation`).
  - [x] Авторотация диагностических лог-файлов на диске (`FileLogSink`, 2×5 МБ) с защитой от утечки секретов (`AppLogger.sanitize`).
  - [x] Контракты и реализация `SessionRecorder` (`ssh_network_core`) для записи терминальных потоков в формате `asciinema` v2 (`.cast`) и текстовых логов (`.log`).
  - [x] Интеграция записи сессий в `TerminalSession` без задержек терминального PTY.
  - [x] Двухвкладочный экран `AuditLogsScreen` (System Logs + Session Recordings) с фильтрацией по уровням (All/Debug/Info/Warn/Error), поиском по тегам и сообщениям, автоскроллом, модальным окном деталей/стектрейсов и экспортом в буфер/файл.
  - [x] Автоматическая запись сессий по политике (PROD Only по умолчанию, All, Manual) в `SettingsScreen` и `SessionConnectController`.
  - [x] Интерактивный индикатор и кнопка `● REC [01:23]` в тулбаре терминала (`TerminalScreen`) с возможностью включения/остановки записи на лету.
  - [x] Автоматическая финализация и сохранение метаданных и файлов (`.cast`, `.log`) в `SessionStorageService` при отключении или ручной остановке.
  - [x] 100% покрытие юнит- и виджет-тестами (`session_connect_flow_test.dart`, `terminal_screen_test.dart`, 163/163 теста успешно, 0 ошибок анализатора).
- [x] Фирменный стиль и кроссплатформенная иконка приложения:
  - [x] Векторный брендовый логотип `S_` в дизайне Obsidian Dark (`icon-02.svg`, градиент `#5FB300`→`#8AEB1A`, подложка `#1C213D`).
  - [x] Встраиваемый Flutter-виджет `ShellitLogo` в `terminal_ui` (сайдбар, окно «О программе»).
  - [x] Мультиразрешенная иконка Windows (`app_icon.ico` со слоями 16, 24, 32, 48, 64, 128, 256 px).
  - [x] Набор иконок Android (`mipmap-mdpi/hdpi/xhdpi/xxhdpi/xxxhdpi` + `launcher_icon.png`).
  - [x] Полные матрицы иконок iOS и macOS (`Assets.xcassets/AppIcon.appiconset`, App Store compliance `remove_alpha_ios: true`).
  - [x] Web PWA иконки (`favicon.png`, `Icon-192`, `Icon-512`, maskable).
  - [x] Регистрация `assets/icon/` в `apps/shellit/pubspec.yaml` и автоматизация через `flutter_launcher_icons`.
- [ ] Сборка пакетов:
  - [x] Windows (Release EXE: `build\windows\x64\runner\Release\shellit.exe` — проверено со вшитой новой иконкой и Safe Build Protocol)
  - [ ] macOS (DMG)
  - [ ] Linux (AppImage / DEB)
  - [ ] Android (APK)
  - [x] Постоянное хранение хостов и настроек в SQLite (`%APPDATA%/com.example/shellit/data/shellit_vault.db`) с поддержкой открытого хранилища без обязательного пароля и плавной миграцией.
- [x] Релиз версии 1.0.0 (Windows Desktop Ready с фирменной иконкой).

---

## Фаза 5: Кроссплатформенная синхронизация (Self-Hosted E2EE Sync)
- [x] Сервер синхронизации `servers/sync_server` (Zero-Knowledge Relay):
  - [x] Легковесный бэкенд на Dart + SQLite (потребление RAM < 20 МБ, без тяжелых внешних СУБД).
  - [x] REST API (`/api/v1/vault/init`, `/api/v1/sync/changes`, `/api/v1/sync/push`, `/api/v1/health`).
  - [x] WebSocket-хаб (`/api/v1/sync/ws`) для мгновенного push-оповещения клиентов о новых ревизиях.
  - [x] Контейнеризация: многоэтапный `Dockerfile` (минимальный runtime-образ) и готовый `docker-compose.example.yml`.
  - [x] Документация и инструкция по развертыванию на VPS за 1 минуту (`servers/sync_server/README.md`).
- [x] Клиентский движок синхронизации (`packages/storage_vault`):
  - [x] Модуль `SyncCrypto`: деривация ключа из парольной фразы (Argon2id), слепой `authHash` и шифрование данных (AES-256-GCM).
  - [x] Механизм учета удалений: таблица `SyncTombstonesTable` в Drift для предотвращения «воскрешения» удаленных сущностей.
  - [x] Клиент `SyncClient`: поддержка как чистого `http://` (внутри WireGuard / Tailscale / LAN), так и `https://` с пропуском проверки для самоподписанных сертификатов (`allowInsecureCertificates`).
  - [x] Оркестратор `SyncManager`: бесконфликтное слияние данных по алгоритму Pull-Then-Push с LWW (Last-Write-Wins) по таймстемпам.
- [x] Сетевые разрешения для мобильных платформ:
  - [x] Android: включение `android.permission.INTERNET` и `android:usesCleartextTraffic="true"` в `AndroidManifest.xml`.
  - [x] iOS: добавление `NSAppTransportSecurity` (`NSAllowsArbitraryLoads`) в `Info.plist`.
- [x] Пользовательский интерфейс (`apps/shellit`):
  - [x] Виджет `SyncSettingsCard` в `SettingsScreen`: ввод Server URL, Vault ID, парольной фразы, invite-токена, тумблер Self-Signed SSL.
  - [x] Живой статус синхронизации (Online / Synced / Syncing / Error) и кнопки «Test Connection» и «Sync Now».
- [x] 100% тестирование:
  - [x] Юнит-тесты сервера (`server_test.dart`).
  - [x] Сквозной интеграционный тест (`sync_client_integration_test.dart`): создание на Laptop → переливание на Phone → редактирование/удаление на Phone → обновление на Laptop.
  - [x] Полный прогон `flutter test` и `flutter analyze` (0 ошибок, 0 предупреждений).

