# Регламент локализации (i18n) и архитектуры языковых плагинов в Shellit

Настоящий документ устанавливает строгий стандарт разработки интерфейса без хардкода строк, правила именования ключей локализации, структуру языковых пакетов сообщества и процедуру экспорта шаблонов для переводчиков.

---

## 1. Базовый принцип: Zero Hardcoded UI Strings

Каждый агент и разработчик обязан соблюдать правило:
> **Ни одна видимая пользователю строка (заголовок, кнопка, тултип, плейсхолдер, текст ошибки, статус или пункт меню) не должна быть захардкожена напрямую в Dart-коде виджетов.**

### Запрещено:
```dart
// ❌ ГРУБОЕ НАРУШЕНИЕ:
Text('Settings & Security')
ElevatedButton(child: Text('Connect'), onPressed: () => ...)
TextField(decoration: InputDecoration(hintText: 'Search servers...'))
showSnackBar('Host connection failed');
```

### Обязательно:
```dart
// ✅ ПРАВИЛЬНО:
Text(context.tr('settings.title'))
ElevatedButton(child: Text(context.tr('hosts.action.connect')), onPressed: () => ...)
TextField(decoration: InputDecoration(hintText: context.tr('hosts.search_placeholder')))
showSnackBar(context.tr('errors.host_connection_failed'));
```

Если строка допускает инлайн-дефолт при разработке:
```dart
Text(context.tr('settings.title', defaultText: 'Settings & Security'))
```

---

## 2. Номенклатура ключей локализации (Key Naming Convention)

Все ключи строятся по строгой иерархической схеме из строчных латинских букв, разделённых точками:

```text
<модуль_или_экран>.<подраздел_или_компонент>.<роль_строки>
```

### Роли строк:
* `.title` / `.subtitle` — заголовки и подзаголовки карточек, экранов, секций.
* `.action.<verb>` или `.btn.<verb>` — интерактивные кнопки (`.action.connect`, `.action.save`, `.action.cancel`).
* `.label` — метки полей ввода (`.label.username`, `.label.port`).
* `.placeholder` / `.hint` — плейсхолдеры в текстовых полях.
* `.tooltip` — всплывающие подсказки при наведении.
* `.status.<state>` — текстовые статусы (`.status.connected`, `.status.offline`).
* `.msg.<name>` — информационные сообщения диалогов и баннеров.
* `.error.<name>` — человекочитаемые ошибки.

### Примеры:
```text
hosts.list.empty_title           -> "No servers configured"
hosts.action.quick_connect       -> "Quick Connect"
terminal.split.horizontal        -> "Split Horizontally"
keychain.dialog.generate_title   -> "Generate New SSH Key Pair"
settings.vault.autolock_label    -> "Auto-Lock Database"
```

---

## 3. Интерполяция параметров и динамические данные

**Категорически запрещается** конкатенировать строки через оператор `+` или строковую интерполяцию `$var`, если часть фразы переводится:

```dart
// ❌ ЗАПРЕЩЕНО (ломает грамматику других языков):
Text(context.tr('connecting_to') + ' ' + host.name + '...')
Text('Connected to ${host.name} on port ${host.port}')

// ✅ ПРАВИЛЬНО:
// Шаблон: "Connected to {host} on port {port}"
Text(context.tr('hosts.status.connected_to', params: {
  'host': host.name,
  'port': host.port.toString(),
}))
```

---

## 4. Архитектура языковых плагинов (Language Packs)

Shellit поддерживает подключение языковых пакетов сообщества через штатный механизм плагинов без необходимости пересборки приложения.

### Структура плагина:
```text
com.community.lang.ru.shellit (или .zip)
├── manifest.json
└── ru.json
```

### `manifest.json` языкового плагина:
```json
{
  "id": "com.community.lang.ru",
  "name": "Russian Language Pack",
  "version": "1.0.0",
  "author": "Community Translator",
  "description": "Полный перевод интерфейса Shellit на русский язык",
  "target": "localization",
  "locale": "ru_RU",
  "entryPoint": "ru.json",
  "minAppVersion": "1.0.0"
}
```

---

## 5. Гарантия стабильности и механизм Fallback

1. **Эталонный источник (Source of Truth):**  
   Встроенный английский словарь (`en_US`) в кодовой базе приложения всегда содержит 100% актуальных ключей.
2. **Graceful Fallback:**  
   Если сторонний языковой плагин отстаёт от релиза и в нём отсутствует какой-либо новый ключ (например, добавлена новая вкладка), приложение:
   * **Не падает.**
   * **Не оставляет пустое место.**
   * **Мгновенно отображает английскую строку по умолчанию.**

---

## 6. Экспорт эталонного шаблона для переводчиков

В приложении предусмотрены точки экспорта шаблона:
1. **Экран «Настройки → Язык»:** кнопка `[Экспортировать шаблон перевода (.json)]`.
2. **Экран «Плагины»:** кнопка `[Инструменты разработчика → Экспорт шаблона локализации]`.
3. **Omni-Bar (`Ctrl+K`):** команда `Developer: Export Localization Template`.

Функция экспорта генерирует отформатированный файл `shellit_strings_template.json`, готовый для перевода в любом редакторе или сервисе локализации.
