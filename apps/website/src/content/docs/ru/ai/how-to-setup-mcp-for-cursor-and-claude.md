---
title: Настройка Model Context Protocol (MCP) для Cursor и Claude Desktop
description: Пошаговое руководство по подключению Claude Desktop, Cursor IDE и автономных ИИ-ассистентов к Shellit через нативный сервер Model Context Protocol.
sidebar:
  order: 3
---

**Model Context Protocol (MCP)** — это открытый стандарт от компании Anthropic, который позволяет современным языковым моделям безопасно взаимодействовать с локальными инструментами, файловыми системами и внешними сервисами.

Shellit оснащен **встроенным нативным MCP-сервером**. Благодаря этому ваши любимые среды разработки (Cursor IDE) и десктопные ИИ-ассистенты (Claude Desktop, Antigravity) могут напрямую опрашивать статус серверов, анализировать вывод упавших команд и читать логи — без копирования секретов и под контролем политик Prod Guard.

---

## Что умеет Shellit MCP Gateway

Подключив Shellit к Claude Desktop или Cursor, нейросеть получает доступ к набору инструментов (Tools):

* `shellit_list_servers` — получение списка настроенных хостов (без паролей и ключей!) с тегами окружений (`PROD`, `STAGE`, `DEV`).
* `shellit_list_active_sessions` — получение списка открытых в данный момент терминальных сессий.
* `shellit_get_terminal_buffer` — чтение последних N строк вывода активного терминала (идеально для дебага ошибок сборки, логов Nginx или Docker).
* `shellit_exec_command` — выполнение команды в терминале с обязательной предварительной проверкой фильтрами **Prod Guard**.
* `shellit_read_remote_file` — чтение удаленного конфигурационного файла через защищенный SFTP канал.

---

## Шаг 1. Включение MCP-сервера в Shellit

1. Откройте Shellit и перейдите в раздел **AI & MCP** (значок молнии на боковой панели).
2. Переведите переключатель **MCP Server Gateway** в положение **Включено**.
3. По умолчанию сервер слушает локальный интерфейс `127.0.0.1:4422`.
4. В блоке «Безопасность» убедитесь, что включена опция **«Требовать подтверждение для сред PROD»**.

![Панель управления MCP-сервером в Shellit](/screenshots/09_mcp_server_gateway.png)

---

## Шаг 2. Подключение в Claude Desktop

Чтобы добавить инструменты Shellit в десктопный клиент Claude:

1. Откройте файл конфигурации Claude Desktop:
   * **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
   * **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
   * **Linux:** `~/.config/Claude/claude_desktop_config.json`
2. Добавьте секцию `shellit`:

```json
{
  "mcpServers": {
    "shellit": {
      "command": "node",
      "args": ["-e", "require('http').request('http://127.0.0.1:4422/message')"]
    }
  }
}
```

3. Перезапустите приложение Claude Desktop.
4. В окне чата в правом нижнем углу появится значок молоточка с инструментами Shellit.

---

## Шаг 3. Подключение в Cursor IDE

В Cursor IDE поддержка протокола MCP встроена прямо в интерфейс редактора:

1. Откройте **Settings** в Cursor (`Ctrl+,` или `Cmd+,`).
2. В боковом меню перейдите в раздел **Features → MCP Servers**.
3. Нажмите **Add New MCP Server**.
4. Заполните поля:
   * **Name:** `shellit`
   * **Type:** `sse` или `command`
   * **URL / Endpoint:** `http://127.0.0.1:4422/sse`
5. Нажмите **Save**. Статус сервера сменится на зеленый индикатор *Active*.

---

## Примеры практических запросов (Промптов)

Теперь вы можете общаться с Claude или Cursor Agent на естественном языке, делегируя анализ инфраструктуры:

### 1. Анализ аварийного лога
> *"Посмотри буфер активного терминала сервера api-node-1 и объясни, почему упал процесс Node.js."*

Claude вызовет инструмент `shellit_get_terminal_buffer`, найдет stack trace исключения и сразу предложит исправление.

### 2. Проверка статуса сервисов
> *"Подключись к серверу stage-cluster и проверь свободное место на дисках и статус контейнеров."*

### 3. Защита Prod Guard в действии
Если Claude или Cursor попытается выполнить разрушительную команду вроде `rm -rf /data` на боевом сервере:
1. Shellit MCP сервер обнаружит опасный паттерн.
2. Команда будет немедленно заблокирована.
3. В чате появится предупреждение: *«Execution blocked: Prod Guard security policy prohibits this command on host tagged as PROD»*.
