---
title: Создание плагина (.shellit)
description: Разработка пользовательских расширений для Shellit Desktop.
---

Shellit поддерживает пользовательские плагины в виде ZIP-архивов с расширением `.shellit`. Плагины исполняются внутри изолированной песочницы WebView2/WebKit с безопасным двусторонним IPC мостом к ядру приложения.

## Структура плагина

```text
my_plugin.shellit (ZIP)
├── manifest.json
├── index.html
├── dist/
│   └── bundle.js
└── assets/
    └── icon.svg
```

## Манифест `manifest.json`

```json
{
  "id": "dev.custom.my-monitor",
  "name": "My Server Monitor",
  "version": "1.0.0",
  "author": "Dev Community",
  "description": "Визуальный дашборд системных метрик",
  "entry": "index.html",
  "permissions": [
    "terminal:read",
    "terminal:write",
    "sftp:read"
  ]
}
```

## Загрузка плагина

Поместите файл `my_plugin.shellit` в директорию плагинов приложения:
* Windows: `%APPDATA%/Shellit/plugins/`
* Linux: `~/.config/shellit/plugins/`

## Менеджер расширений в Shellit

Управлять установленными расширениями, просматривать запрашиваемые права доступа (`ssh:exec`, `terminal:read`, `network:listen`) и устанавливать новые пакеты из файлов `.shellit` можно в графическом менеджере плагинов:

![Менеджер расширений Shellit](/screenshots/06_plugins_manager.png)
