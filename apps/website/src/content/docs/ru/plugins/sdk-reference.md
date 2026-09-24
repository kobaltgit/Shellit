---
title: Desktop Plugin SDK API Reference
description: Справочник JavaScript API для разработки расширений Shellit.
---

Каждый плагин Shellit исполняется в изолированной среде WebView2 (Windows) или WebKit (Linux) и взаимодействует с хост-приложением через объект `window.shellit`.

:::note[Изоляция песочницы]
Плагины не имеют прямого доступа к файловой системе хоста или сырым сокетам. Все действия производятся строго через асинхронный мост сообщений с обязательной проверкой прав доступа, объявленных в `manifest.json`.
:::

## Интерфейс `window.shellit`

### Модуль `shellit.terminal`

Управление терминальными сессиями и чтение вывода.

#### `shellit.terminal.sendInput(sessionId: string, data: string): Promise<void>`
Отправляет строку данных (включая управляющие ANSI-последовательности) в активную PTY сессию.
* **Требуемое разрешение:** `terminal:write`
* **Параметры:**
  * `sessionId`: строковый идентификатор активной вкладки терминала.
  * `data`: текстовая строка или байты для ввода (например, `"htop\n"`).

#### `shellit.terminal.getBuffer(sessionId: string, linesCount: number): Promise<string[]>`
Считывает последние строки из буфера прокрутки терминала.
* **Требуемое разрешение:** `terminal:read`
* **Возвращает:** массив строк текста без ANSI escape-последовательностей.

#### `shellit.terminal.onData(sessionId: string, callback: (chunk: string) => void): () => void`
Подписывается на поток вывода терминала в реальном времени. Возвращает функцию отписки.

---

### Модуль `shellit.hosts`

Доступ к каталогу сохраненных серверов (в десенсибилизированном виде).

#### `shellit.hosts.list(): Promise<HostSummary[]>`
Возвращает список всех серверов в каталоге пользователя.
* **Требуемое разрешение:** `hosts:read`
* **Возвращаемый объект `HostSummary`:**
```typescript
interface HostSummary {
  id: string;
  label: string;
  hostname: string;
  port: number;
  username: string;
  environment: 'PROD' | 'STAGE' | 'DEV';
  tags: string[];
  latencyMs: number | null; // текущий RTT-пинг
}
```

#### `shellit.hosts.connect(hostId: string): Promise<string>`
Инициирует открытие новой вкладки SSH-сессии к указанному серверу.
* **Требуемое разрешение:** `ssh:connect`
* **Возвращает:** `sessionId` созданной сессии.

---

### Модуль `shellit.sftp`

Работа с удаленной файловой системой.

#### `shellit.sftp.listDirectory(sessionId: string, remotePath: string): Promise<RemoteFileInfo[]>`
Возвращает список файлов и директорий по указанному удаленному пути.
* **Требуемое разрешение:** `sftp:read`

#### `shellit.sftp.readFile(sessionId: string, remotePath: string): Promise<Uint8Array>`
Загружает содержимое удаленного файла в виде байтового массива.
* **Требуемое разрешение:** `sftp:read`

#### `shellit.sftp.writeFile(sessionId: string, remotePath: string, data: Uint8Array): Promise<void>`
Записывает данные в удаленный файл.
* **Требуемое разрешение:** `sftp:write`

---

### Модуль `shellit.ui`

Взаимодействие с пользовательским интерфейсом приложения.

#### `shellit.ui.showToast(message: string, type?: 'info' | 'success' | 'warning' | 'error'): void`
Отображает всплывающее уведомление в стиле киберпанк в углу экрана.

#### `shellit.ui.openModal(title: string, htmlContent: string): Promise<boolean>`
Открывает модальное диалоговое окно Shellit с кастомным контентом.
