---
title: Нативный Model Context Protocol (MCP) Server
description: Подключение Claude Desktop, Cursor и Antigravity к Shellit по открытому протоколу.
---

Shellit поддерживает спецификацию **Model Context Protocol (MCP)** от Anthropic. Это позволяет превратить Shellit в интеллектуальный шлюз между вашей инфраструктурой и современными автономными ИИ-агентами.

## Доступные инструменты (Tools)

* `shellit_list_servers`: возвращает список доступных хостов из зашифрованного хранилища;
* `shellit_list_active_sessions`: список текущих открытых терминалов и их идентификаторов;
* `shellit_exec_command`: безопасное выполнение команды в активной сессии;
* `shellit_get_terminal_buffer`: чтение последних строк вывода терминала для анализа ошибок;
* `shellit_read_remote_file`: чтение удаленного файла через встроенный SFTP.

## Интерфейс управления MCP-сервером

В панели управления MCP вы можете включать и отключать сервер, следить за активными подключениями клиентов (Claude Desktop, Antigravity, Cursor), настраивать политики безопасности для сред PROD и копировать конфигурационные файлы в один клик:

![Панель управления MCP-сервером в Shellit](/screenshots/09_mcp_server_gateway.png)

## Подключение в Claude Desktop

Добавьте конфигурацию в `claude_desktop_config.json`:

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

Все команды перед выполнением проходят проверку политик **Prod Guard**.
