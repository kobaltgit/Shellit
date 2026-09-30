/// <reference path="../pb_data/types.d.ts" />
migrate((app) => {
  const collection = app.findCollectionByNameOrId("roadmap_items");
  if (!collection) return;

  const items = [
    {
      feature_id: "feat-shell-integration",
      status: "shipped",
      tag: "Terminal",
      order: 1,
      votes: 184,
      title_en: "OSC 133 Shell Integration & Command Blocks",
      title_ru: "Семантическая интеграция шелла OSC 133",
      desc_en: "Command block boundaries, success/error scrollbar markers, fast command hopping (Alt+Up/Down), and clean output extraction without prompt noise.",
      desc_ru: "Разметка блоков команд, маркеры успехов/ошибок на скроллбаре, прыжки по командам (Alt+Вверх/Вниз) и копирование чистого вывода без промпта."
    },
    {
      feature_id: "feat-tofu-randomart",
      status: "shipped",
      tag: "Security",
      order: 2,
      votes: 145,
      title_en: "SSH TOFU & Drunken Bishop Randomart",
      title_ru: "SSH TOFU & Визуальный Randomart",
      desc_en: "Strict Trust-On-First-Use verification, encrypted known_hosts storage, OpenSSH Drunken Bishop visual fingerprints, and instant MitM attack prevention.",
      desc_ru: "Строгая верификация первого подключения (TOFU), зашифрованная база known_hosts, ASCII Randomart (Drunken Bishop) и пресечение атак перехвата MitM."
    },
    {
      feature_id: "feat-matrix-splits",
      status: "shipped",
      tag: "Terminal",
      order: 3,
      votes: 128,
      title_en: "2x2 Matrix Splits & Broadcast",
      title_ru: "Матричный сплит 2x2 & Broadcast",
      desc_en: "Split window into 4 independent panes with concurrent command execution and drag-and-drop tab docking.",
      desc_ru: "Разделение окна на 4 независимые панели с одновременным вводом команд и Drag-and-Drop вкладок."
    },
    {
      feature_id: "feat-prod-guard",
      status: "shipped",
      tag: "Security",
      order: 4,
      votes: 95,
      title_en: "Prod Guard & Contextual Security",
      title_ru: "Prod Guard & Контекстная безопасность",
      desc_en: "Environment color coding and interception of destructive commands (rm -rf, DROP, mkfs, dd).",
      desc_ru: "Цветовая маркировка сред и перехват деструктивных команд (rm -rf, DROP, mkfs, dd)."
    },
    {
      feature_id: "feat-sftp-pro",
      status: "shipped",
      tag: "SFTP",
      order: 5,
      votes: 138,
      title_en: "Dual-Pane SFTP Pro Suite",
      title_ru: "Двухпанельный SFTP Pro Suite",
      desc_en: "Dual-pane file manager with recursive folder transfers, smart conflict resolution, batch selection (Ctrl/Shift), and built-in text editor.",
      desc_ru: "Двухпанельный менеджер с рекурсивным трансфером папок, разрешением конфликтов, мультивыбором (Ctrl/Shift) и встроенным редактором файлов."
    },
    {
      feature_id: "feat-keychain-pro",
      status: "shipped",
      tag: "Security",
      order: 6,
      votes: 119,
      title_en: "Keychain Pro & 1-Click ssh-copy-id",
      title_ru: "Keychain Pro & 1-Click ssh-copy-id",
      desc_en: "Built-in Ed25519/RSA key generator, automatic ~/.ssh discovery, and one-click public key deployment to remote servers.",
      desc_ru: "Встроенный генератор пар ключей Ed25519/RSA, автопоиск в ~/.ssh и деплой публичных ключей на сервер в 1 клик."
    },
    {
      feature_id: "feat-sync-server",
      status: "shipped",
      tag: "Sync",
      order: 7,
      votes: 142,
      title_en: "Self-Hosted E2EE Sync Server",
      title_ru: "Self-Hosted E2EE Sync Server",
      desc_en: "Autonomous sync server built with Dart/SQLite with <20 MB RAM footprint and zero-knowledge encryption.",
      desc_ru: "Автономный сервер синхронизации на Dart/SQLite с потреблением <20 МБ RAM и сквозным E2EE шифрованием."
    },
    {
      feature_id: "feat-zk-vault",
      status: "shipped",
      tag: "Security",
      order: 8,
      votes: 88,
      title_en: "Zero-Knowledge Vault (Argon2id)",
      title_ru: "Zero-Knowledge Vault (Argon2id)",
      desc_en: "Client-side SQLCipher database with Argon2id key derivation, in-memory zeroization, and auto-lock security.",
      desc_ru: "Локальная база SQLCipher с деривацией ключа Argon2id, занулением памяти (zeroize) и автоблокировкой сейфа."
    },
    {
      feature_id: "feat-mcp-server",
      status: "shipped",
      tag: "AI & MCP",
      order: 9,
      votes: 176,
      title_en: "Native Model Context Protocol (MCP)",
      title_ru: "Нативный Model Context Protocol (MCP)",
      desc_en: "Embedded tool server exposing safe SSH execution and telemetry for Claude Desktop, Cursor, and Antigravity.",
      desc_ru: "Встроенный сервер инструментов для Claude Desktop, Cursor и Antigravity с безопасным доступом к серверам."
    },
    {
      feature_id: "feat-gemini-byok",
      status: "shipped",
      tag: "AI & MCP",
      order: 10,
      votes: 110,
      title_en: "Gemini AI Snippets Chat (BYOK)",
      title_ru: "Gemini AI Snippets Chat (BYOK)",
      desc_en: "Shell command generator using Bring Your Own Key via Google AI Studio with structured JSON execution.",
      desc_ru: "Генератор shell-команд по модели Bring Your Own Key через Google AI Studio со структурированным запуском."
    },
    {
      feature_id: "feat-paste-defense",
      status: "shipped",
      tag: "Terminal",
      order: 11,
      votes: 98,
      title_en: "Multiline Paste Defense & Clickable Links",
      title_ru: "Защита от вставки скриптов и кликабельные ссылки",
      desc_en: "Interactive preview dialog for multiline clipboard pastes to prevent accidental execution, plus clickable URLs and file paths.",
      desc_ru: "Интерактивный диалог подтверждения многострочной вставки для предотвращения случайного запуска, плюс кликабельные URL и пути."
    },
    {
      feature_id: "feat-color-themes",
      status: "shipped",
      tag: "UI",
      order: 12,
      votes: 114,
      title_en: "Custom Themes (Obsidian, Dracula, Nord, OLED)",
      title_ru: "Палитра тем (Obsidian, Dracula, Nord, OLED)",
      desc_en: "Built-in rich color schemes with TrueColor terminal rendering and contrast optimization.",
      desc_ru: "Встроенные выверенные цветовые схемы с поддержкой TrueColor и высокой контрастностью."
    },
    {
      feature_id: "feat-in-app-feedback",
      status: "shipped",
      tag: "UX & Cloud",
      order: 13,
      votes: 72,
      title_en: "In-App Feedback & Bug Reporter",
      title_ru: "Встроенный репортер отзывов и багов",
      desc_en: "Direct feedback and bug report submission from the application into the shellit.top portal control plane.",
      desc_ru: "Отправка отзывов и сообщений об ошибках прямо из приложения в панель управления на портале shellit.top."
    },
    {
      feature_id: "feat-rtt-ping",
      status: "shipped",
      tag: "Terminal",
      order: 14,
      votes: 64,
      title_en: "Live Host RTT Ping",
      title_ru: "Живой RTT-пинг хостов",
      desc_en: "Continuous latency polling with real-time color dots (<50ms, <200ms, offline) on server cards.",
      desc_ru: "Непрерывный замер задержки серверов с цветовой индикацией (<50ms, <200ms, оффлайн) на карточках."
    },
    {
      feature_id: "feat-startup-snippets",
      status: "in-progress",
      tag: "Terminal",
      order: 15,
      votes: 135,
      title_en: "Startup Snippets (Auto-Run on Connect)",
      title_ru: "Startup-сниппеты (автовыполнение)",
      desc_en: "Automatic execution of selected commands (tmux attach, cd /var/www) immediately after SSH handshake.",
      desc_ru: "Автоматический запуск выбранного набора команд (tmux a, cd /var/www) сразу после подключения по SSH."
    },
    {
      feature_id: "feat-portable-mode",
      status: "in-progress",
      tag: "Core",
      order: 16,
      votes: 104,
      title_en: "Desktop Portable Mode",
      title_ru: "Портативный режим (Portable Mode)",
      desc_en: "Run directly from a USB stick: store encrypted SQLCipher DB and configs strictly adjacent to the executable without touching %APPDATA%.",
      desc_ru: "Запуск с флешки: хранение зашифрованной базы SQLCipher и конфигов строго рядом с .exe без следов в %APPDATA%."
    },
    {
      feature_id: "feat-winget-scoop",
      status: "in-progress",
      tag: "Deploy",
      order: 17,
      votes: 92,
      title_en: "Winget & Scoop Package Publishing",
      title_ru: "Публикация в Winget & Scoop",
      desc_en: "Official manifests for one-command installation in Windows terminals.",
      desc_ru: "Официальные манифесты для установки одной строчкой в консоли Windows."
    },
    {
      feature_id: "feat-history-sync",
      status: "in-progress",
      tag: "Sync",
      order: 18,
      votes: 78,
      title_en: "Terminal History Sync",
      title_ru: "Синхронизация истории терминала",
      desc_en: "Optional encrypted synchronization of executed command history across devices.",
      desc_ru: "Опциональная зашифрованная синхронизация истории введенных команд между ПК и ноутбуком."
    },
    {
      feature_id: "feat-quake-mode",
      status: "planned",
      tag: "UX & Desktop",
      order: 19,
      votes: 165,
      title_en: "Desktop Quake Drop-Down Mode",
      title_ru: "Quake Drop-Down режим",
      desc_en: "Drop-down terminal summoned by a global hotkey (Ctrl+~ / F12) smoothly sliding from the top over all OS windows.",
      desc_ru: "Выпадающий терминал по глобальной горячей клавише (Ctrl+~ / F12), плавно выезжающий сверху поверх всех окон ОС."
    },
    {
      feature_id: "feat-sftp-quick-open",
      status: "planned",
      tag: "SFTP & Terminal",
      order: 20,
      votes: 148,
      title_en: "Remote Paths (`file:line:col`) to SFTP",
      title_ru: "Переход из логов терминала в SFTP-редактор",
      desc_en: "Ctrl+Click on file paths in stacktraces and logs (/var/log/..., app.py:42) to instantly open the remote file in SFTP editor on that exact line.",
      desc_ru: "Ctrl+Click по путям файлов в стектрейсах и логах (/var/log/..., app.py:42) с мгновенным открытием удаленного файла в редакторе SFTP на нужной строке."
    },
    {
      feature_id: "feat-local-llm",
      status: "planned",
      tag: "AI",
      order: 21,
      votes: 156,
      title_en: "Local LLM Support (Ollama / LM Studio)",
      title_ru: "Поддержка локальных нейросетей (Ollama / LM Studio)",
      desc_en: "Offline AI snippet generation and error analysis via local OpenAI-compatible endpoints without external cloud requests.",
      desc_ru: "Офлайн-генерация команд и разбор ошибок через локальный OpenAI-совместимый API (Qwen, Llama 3, DeepSeek) без интернета."
    },
    {
      feature_id: "feat-jump-hosts",
      status: "planned",
      tag: "Network",
      order: 22,
      votes: 160,
      title_en: "Jump Hosts & ProxyJump Graph",
      title_ru: "Jump Hosts & ProxyJump граф",
      desc_en: "Visual bastion host chain builder with interactive node graph.",
      desc_ru: "Визуальный конструктор цепочек бастион-серверов с отображением узлов на интерактивной карте."
    },
    {
      feature_id: "feat-cloud-discovery",
      status: "planned",
      tag: "Cloud",
      order: 23,
      votes: 138,
      title_en: "Cloud Discovery & Auto-Sync",
      title_ru: "Облачное обнаружение и автосинхронизация",
      desc_en: "1-Click import and smart-folders for cloud servers via read-only APIs of Hetzner, Timeweb, Selectel, DigitalOcean, and AWS.",
      desc_ru: "1-Click импорт и смарт-папки серверов по Read-Only API облачных провайдеров (Hetzner, Timeweb, Selectel, DigitalOcean, AWS)."
    },
    {
      feature_id: "feat-db-explorer",
      status: "planned",
      tag: "Database",
      order: 24,
      votes: 129,
      title_en: "Zero-Config DB & Redis Explorer",
      title_ru: "Встроенный GUI для PostgreSQL, Redis и SQLite",
      desc_en: "Lightweight built-in browser for PostgreSQL, Redis, MySQL, and SQLite over automatic SSH tunnels without heavy external tools.",
      desc_ru: "Встроенный легковесный просмотрщик PostgreSQL, Redis, MySQL и SQLite через авто-туннели без сторонних DBeaver."
    },
    {
      feature_id: "feat-clipboard-clear",
      status: "planned",
      tag: "Security",
      order: 25,
      votes: 84,
      title_en: "Clipboard Auto-Clear",
      title_ru: "Автоочистка буфера обмена",
      desc_en: "Automatically erase copied passwords and private keys from the operating system clipboard after 30 seconds.",
      desc_ru: "Автоматическое стирание скопированных паролей и ключей из буфера обмена ОС через 30 секунд."
    },
    {
      feature_id: "feat-web-client",
      status: "planned",
      tag: "Web",
      order: 26,
      votes: 122,
      title_en: "Web Client (Self-Hosted)",
      title_ru: "Web-версия клиента (Self-Hosted)",
      desc_en: "Connect to your servers via a secure browser-based interface.",
      desc_ru: "Возможность подключиться к своим серверам через защищенный браузерный интерфейс."
    },
    {
      feature_id: "feat-prometheus",
      status: "planned",
      tag: "DevOps",
      order: 27,
      votes: 55,
      title_en: "Prometheus Metrics Exporter",
      title_ru: "Экспорт метрик в Prometheus",
      desc_en: "Background export of host uptime and RTT telemetry to monitoring systems.",
      desc_ru: "Фоновый экспорт статуса доступности и RTT ваших серверов в систему мониторинга."
    },
    {
      feature_id: "feat-mosh",
      status: "planned",
      tag: "Terminal",
      order: 28,
      votes: 89,
      title_en: "Mosh Protocol Support",
      title_ru: "Поддержка сессий Mosh",
      desc_en: "Drop-tolerant mobile connectivity for high-latency or unstable networks (post-1.0).",
      desc_ru: "Устойчивое к обрывам связи мобильное подключение для нестабильных сетей (после 1.0)."
    }
  ];

  for (const item of items) {
    let record = null;
    try {
      record = app.findFirstRecordByFilter("roadmap_items", "feature_id = '" + item.feature_id + "'");
    } catch (e) {}

    if (record) {
      record.set("status", item.status);
      record.set("order", item.order);
      record.set("tag", item.tag);
      record.set("title_en", item.title_en);
      record.set("title_ru", item.title_ru);
      record.set("desc_en", item.desc_en);
      record.set("desc_ru", item.desc_ru);
      const curVotes = record.getInt("votes");
      if (!curVotes || curVotes < item.votes) {
        record.set("votes", item.votes);
      }
      app.save(record);
    } else {
      const newRec = new Record(collection, item);
      app.save(newRec);
    }
  }
  console.log("Successfully synchronized roadmap_items with v0.9.1 roadmap data.");
}, (app) => {
  // Revert hook (no-op)
});
