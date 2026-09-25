---
title: "Акт V: Мост в будущее — MCP-сервер, Gemini и ConPTY"
description: "Shellit учится говорить с AI: интеграция Model Context Protocol (MCP) для Cursor и Claude, генератор сниппетов на Google Gemini и локальный ConPTY-терминал."
actNumber: 5
period: "19 сентября 2026, 12:00 — 15:00"
pubDate: 2026-09-19
readingTime: "8 мин"
stage: "v0.7.3 — v0.8.0 AI & Terminal"
relatedBugs: ["BUG-024", "BUG-026"]
tags: ["mcp", "gemini", "conpty", "cursor", "claude-desktop"]
lang: "ru"
---

<div class="p-4 rounded-xl bg-obsidian-bg/80 border border-cyber-lime/30 text-slate-300 text-sm leading-relaxed mb-8 not-prose">
  <strong class="text-white font-mono">Контекст акта:</strong> Терминал нового поколения обязан понимать искусственный интеллект. В этом акте Shellit превращается в шлюз Model Context Protocol (MCP), позволяя агентам в Cursor и Claude безопасно исполнять команды и инспектировать логи через Prod Guard, подключает умный генератор bash-сниппетов на Google Gemini и осваивает нативный локальный Windows ConPTY.
</div>

## Запись 29. Мост в будущее: Model Context Protocol (MCP) для Cursor и Claude

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Время: 19 сентября 2026, 12:00 — 13:00 (~60 минут)
</span>

Разработчики всё чаще делегируют рутину внешним ИИ-агентам (Claude Desktop, Cursor IDE). Но как дать ИИ доступ к удаленным серверам, не сливая приватные SSH-ключи в облако?

Мы реализовали нативный сервер **Model Context Protocol (MCP)**, встроенный прямо в Shellit:
- Внешний агент подключается к Shellit через стандартный JSON-RPC поток `stdio`.
- ИИ получает набор безопасных инструментов: `shellit_list_servers`, `shellit_exec_command`, `shellit_get_terminal_buffer`, `shellit_read_remote_file`.
- **Защита Prod Guard в деле:** Если агент пытается выполнить разрушительную команду на сервере с тегом `PROD`, Shellit блокирует выполнение и запрашивает осознанное подтверждение у человека за клавиатурой. Ключи доступа никогда не покидают зашифрованный Vault приложения.

---

## Запись 31. AI-генератор сниппетов на Google Gemini (BYOK)

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Время: 19 сентября 2026, 13:30 — 14:00 (~30 минут)
</span>

Сколько раз вам приходилось гуглить сложные цепочки `awk`, `sed`, парсинг логов `journalctl` или поиск утечек памяти через `lsof`?

В библиотеку сниппетов встроен умный ИИ-помощник:
- **Принцип BYOK (Bring Your Own Key):** Пользователь указывает собственный API-ключ Gemini, хранящийся в локальном Keychain. Никаких платных подписок или скрытых наценок.
- Возможность выбора моделей на лету: быстрый `gemini-1.5-flash` для мгновенных однострочников или глубокий `gemini-1.5-pro` для развернутых bash-скриптов.
- Генератор не просто выдает команду, но и автоматически заполняет категорию, теги и подробное описание того, что делает каждый флаг утилиты. Кнопка **1-Click Run** тут же отправляет команду в активный терминал.

---

## Запись 33. Локальный терминал ConPTY: удобство в стиле Tabby

<span class="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-mono font-semibold bg-cyber-lime/15 text-cyber-lime border border-cyber-lime/30 my-2">
  ⏱️ Время: 19 сентября 2026, 14:15 — 14:45 (~30 минут)
</span>

Многие SSH-клиенты (включая Termius) не имеют нормального встроенного локального шелла: чтобы выполнить пару команд на своей машине, приходится сворачивать приложение и открывать PowerShell или WSL в отдельном окне.

Мы интегрировали полноценную поддержку нативного **Windows ConPTY**:
- Мгновенное открытие локальной вкладки: PowerShell, CMD или дистрибутивы WSL (Ubuntu, Debian).
- Полная аппаратная поддержка псевдотерминала Windows 10/11 с поддержкой цветов 24-bit TrueColor и мыши в консольных утилитах (`htop`, `mc`, `fzf`).
- Единые горячие клавиши, матричные сплиты 2x2 и темная тема Obsidian Dark — теперь и для локальной рабочей станции.
