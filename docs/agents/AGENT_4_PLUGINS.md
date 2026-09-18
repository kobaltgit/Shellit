# Инструкция для Агента 4: Desktop Plugin Ecosystem Team

## 1. Роль и зона ответственности
* **Пакет:** `packages/desktop_plugin_sdk/`
* **Миссия:** Создание модульной, безопасной и расширяемой экосистемы плагинов исключительно для десктопных платформ (Windows, macOS, Linux) с изоляцией от мобильных сборок.

---

## 2. Архитектура пакета плагина (.shellit)
Плагин представляет собой ZIP-архив с расширением `.shellit`, содержащий:
```text
my-awesome-plugin.shellit
├── manifest.json         # Метаданные, права доступа, точки входа (Entry points)
├── icon.png              # Иконка плагина (64x64)
├── index.html            # UI песочницы (для плагинов с визуальным интерфейсом)
├── plugin.js             # Логика плагина
└── assets/               # Стили, картинки, локализация
```

### Спецификация `manifest.json`:
```json
{
  "id": "com.developer.docker-monitor",
  "name": "Docker Container Monitor",
  "version": "1.0.0",
  "author": "Dev Team",
  "description": "Отображает статус контейнеров на удаленном хосте в боковой панели",
  "entryPoint": "index.html",
  "target": "sidebar", // "sidebar" | "statusbar" | "modal" | "headless" | "localization"
  "locale": "ru_RU",  // Обязательно только для target: "localization"
  "permissions": [
    "terminal:execute",
    "vault:read_hosts",
    "notifications:show"
  ],
  "minAppVersion": "1.0.0"
}
```

---

## 3. Механизм исполнения и песочница (Sandboxing & IPC)
1. **Изоляция исполнения:**
   * Плагин загружается внутри изолированного WebView (WebView2 на Windows, WKWebView на macOS, WebKitGTK на Linux).
   * Код плагина не имеет прямого доступа к файловой системе хоста или нативным сокетам приложения.
2. **Двусторонний JSON-RPC мост:**
   * Связь между Dart-ядром и JS-песочницей плагина осуществляется через строго типизированные сообщения:
   ```json
   // Запрос от плагина к Shellit
   {
     "jsonrpc": "2.0",
     "id": "req-1",
     "method": "terminal.runCommand",
     "params": {
       "sessionId": "current",
       "command": "docker ps --format json\n"
     }
   }
   ```
   * Приложение валидирует права плагина по `manifest.json` перед выполнением каждого RPC-метода.

---

## 4. Менеджер плагинов в UI
* Сканирование директории плагинов (по умолчанию в пользовательской директории AppData / `~/.shellit/plugins`).
* Экран управления в настройках десктопной версии:
  * Список установленных плагинов (включение/отключение тумблером).
  * Установка нового плагина перетаскиванием файла (Drag & Drop) или через диалог выбора файла.
  * Удаление и проверка обновлений.

---

## 5. Поддержка языковых пакетов (target: "localization")
* **Без песочницы WebView:** Плагины локализации не требуют запуска браузерной песочницы. При сканировании их словарь (`entryPoint`: например, `ru.json`) загружается в память и передаётся менеджеру локализации (`LocalizationService`).
* **Экспорт эталонного шаблона:** Реализация экспорта текущего актуального набора ключей со встроенным английским текстом в файл `shellit_strings_template.json` по запросу пользователя из настроек плагинов, экрана языков и Omni-Bar (`Developer: Export Localization Template`).
* См. подробную спецификацию в [`docs/LOCALIZATION_AND_I18N_GUIDE.md`](file:///d:/Projects/active/Shellit/docs/LOCALIZATION_AND_I18N_GUIDE.md).

---

## 6. Изоляция от мобильных платформ (Critical!)
* На мобильных устройствах (iOS / Android) модуль должен экспортировать легковесную заглушку (No-Op implementation):
```dart
abstract class IPluginLoader {
  Future<List<InstalledPlugin>> getInstalledPlugins();
  Future<void> installPlugin(String archivePath);
}

// На Desktop возвращается DesktopPluginLoaderService, на Mobile — NoOpPluginLoaderService
```
* Никаких прямых импортов десктопных WebView-библиотек в коде, попадающем в мобильный таргет.

---

## 7. Чек-лист проверки качества
- [ ] Безопасная распаковка архивов (защита от Zip Slip уязвимостей).
- [ ] Валидация манифеста перед установкой плагина (включая корректный код `locale` для `target: "localization"`).
- [ ] Корректное чтение JSON-словарей языковых плагинов без создания лишних WebView инстансов.
- [ ] Доступность экспорта шаблона перевода `template.json`.
- [ ] Проверка прав: плагин без разрешения `terminal:execute` получает отказ при вызове выполнения команды.
- [ ] Мобильные сборки (Android/iOS) компилируются без ссылок на десктопные библиотеки плагинов.
- [ ] 0 предупреждений анализатора Dart.
