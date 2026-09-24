# Инструкция для Агента 5: Web Ecosystem & Documentation Team

## 1. Паспорт агента и миссия
* **Рабочая зона в репозитории:** `apps/website/` и `servers/portal_backend/`
* **Официальный домен:** `https://shellit.top`
* **Продакшен-сервер:** Senko (Ubuntu 24.04 LTS, Docker Compose стек в `/opt/shellit`)
* **Стек технологий:** 
  * **Фронтенд:** Astro 5 (Static Site Generation), Starlight (движок документации), TailwindCSS, TypeScript.
  * **Клиентский функционал:** Pagefind (клиентский полнотекстовый поиск), Chart.js (аналитика в админке).
  * **Бэкенд & База данных:** PocketBase (Go/SQLite), JS-хуки (`pb_hooks`), миграции схем (`pb_migrations`).
  * **Сетевая доставка:** Cloudflare Tunnel (`cloudflared`), Nginx Alpine (внутренний реверс-прокси и статический файловый сервер).
* **Главная миссия:** Развивать официальный веб-портал **Shellit**, обеспечивая единую экосистему между продуктом, документацией, базой знаний, открытым роадмапом, телеметрией и администрированием.

---

## 2. Фирменная айдентика и дизайн-система (Obsidian Lime)

Дизайн веб-портала является естественным продолжением интерфейса терминала Shellit. В основе лежит строгий темный минимализм с фирменным акцентным лаймом логотипа.

### 2.1. Строгая моно-тема (Dark Mode Only)
* **Запрет на светлую тему:** Портал и документация работают **исключительно в темной теме** (`Obsidian Dark`).
* Переключатели тем вырезаны из верстки и заголовков документации. Переменные CSS принудительно зафиксированы на темных значениях как для `:root`, так и для `:root[data-theme='light']`.

### 2.2. Цветовая палитра:
| Элемент | HEX / Значение | Назначение |
| :--- | :--- | :--- |
| **Shellit Logo Lime** | `#7BE113` | Главный акцентный цвет (заменяет устаревший циан), интерактивные ховеры, акцент логотипа. |
| **Lime Gradient Start** | `#5FB300` | Начальный цвет градиента главных CTA-кнопок («Скачать»). |
| **Lime Gradient End** | `#8AEB1A` | Конечный цвет градиента главных CTA-кнопок. |
| **Lime Glow** | `rgba(123, 225, 19, 0.38)` | Неоновое свечение активных карточек, логотипа и бейджей. |
| **Obsidian Background** | `#0D0F12` | Базовый глубокий черный фон страниц. |
| **Card / Panel Background** | `#15181E` | Фон карточек второго уровня, модальных окон, выпадающих меню. |
| **Surface Background** | `#1E232B` | Подложка инпутов, кнопок-табов, элементов интерфейса. |
| **Border Slate** | `#262B35` | Тонкие границы блоков, разделители, рамки карточек. |
| **Text Primary** | `#F1F5F9` | Основной белый текст (`slate-100`). |
| **Text Muted** | `#94A3B8` | Второстепенный текст, описания, подсказки (`slate-400`). |
| **Alert Red** | `#EF4444` | Бейдж PROD, деструктивные операции, ошибки. |
| **Stage Amber** | `#F59E0B` | Бейдж STAGE, предупреждения. |
| **Dev Blue** | `#3B82F6` | Бейдж DEV, информационные плашки. |

### 2.3. Типографика:
* **Основной интерфейс и заголовки:** `Inter` / `system-ui`.
* **Терминал, бейджи, сниппеты, команды и статистика:** `JetBrains Mono` (моноширинный шрифт).

### 2.4. Правила верстки кнопок и элементов управления:
* **Никаких рваных субпиксельных рамок:** Запрещено использовать хак `p-[1px]` с многослойными градиентами для мелких кнопок — на экранах с дробным DPI (`devicePixelRatio != 1`) это дает рваные артефакты.
* **Главная кнопка действия (CTA):** Должна иметь сплошной градиент `bg-gradient-to-r from-[#5FB300] to-[#8AEB1A]` с черным жирным текстом `text-black font-semibold`, скруглением `rounded-xl` и чистым выравниванием по вертикали (`items-center justify-center`).

---

## 3. Архитектура веб-приложения (`apps/website/`)

```text
apps/website/
├── astro.config.mjs               # Конфиг Astro 5, Starlight, Tailwind, Pagefind, site: 'https://shellit.top'
├── package.json                   # Зависимости (@astrojs/starlight, @astrojs/tailwind, pocketbase)
├── tailwind.config.mjs            # Фирменная палитра (cyber.cyan -> #7BE113, glow-cyan -> lime glow)
├── public/                        # Статические ассеты (favicon.svg, og-image.png, icon.png, install.sh)
├── src/
│   ├── assets/                    # Векторная графика
│   ├── components/
│   │   ├── analytics/
│   │   │   └── Tracker.astro      # Неблокирующий клиентский сборщик визитов (same-origin POST)
│   │   ├── common/
│   │   │   ├── DownloadModal.astro # Модальное окно загрузки (Windows, Linux, Android, CLI)
│   │   │   ├── FeedbackModal.astro # Модалка баг-репортов и предложений (отправка в PocketBase)
│   │   │   └── ScrollToTop.astro  # Кнопка возврата наверх
│   │   ├── layout/
│   │   │   ├── Navbar.astro       # Главная шапка (Stripe-стиль "Продукт", звезды GitHub, CTA)
│   │   │   └── Footer.astro       # Подвал сайта со ссылками на сообщество и документацию
│   │   ├── promo/                 # Секции лендинга: Hero, Scrollytelling, Comparison, CTABanner
│   │   └── starlight/             # Кастомные оверрайды Starlight:
│   │       ├── SiteTitle.astro    # Логотип 32px с лайм-свечением + кнопка возврата на портал
│   │       ├── LanguageSelect.astro # Стилизованный переключатель EN | RU (без нативных <select>)
│   │       └── ThemeSelect.astro  # Пустой заглушечный компонент (вырезает смену тем)
│   ├── content/
│   │   └── docs/                  # Статьи документации (Markdown / MDX)
│   ├── i18n/
│   │   └── translations.ts        # Словари локализации сайта (RU и EN)
│   ├── layouts/
│   │   └── Layout.astro           # Главный макет страницы (SEO, Hreflang, скрипт безмерцающего i18n)
│   ├── lib/
│   │   ├── github-releases.ts     # Парсер релизов и живых звезд репозитория GitHub
│   │   ├── pocketbase.ts          # Клиент PocketBase SDK (поддержка Same-Origin и fallback к SSOT)
│   │   └── types.ts               # TypeScript интерфейсы
│   ├── pages/
│   │   ├── index.astro            # Главный лендинг (English)
│   │   ├── roadmap.astro          # Публичный интерактивный роадмап (English)
│   │   ├── admin/
│   │   │   └── index.astro        # Shellit Command Center (дашборд аналитики, фидбека и релизов)
│   │   └── ru/
│   │       ├── index.astro        # Главный лендинг (Русский)
│   │       └── roadmap.astro      # Публичный роадмап (Русский)
│   └── styles/
│       ├── global.css             # Глобальные стили Tailwind
│       └── starlight-custom.css   # Стилизация документации (лайм-акценты, скрытие селекторов тем)
```

---

## 4. Ключевые механизмы и компоненты

### 4.1. Двуязычность без мерцания (Zero-Flicker i18n)
* Портал поддерживает 2 языка: Английский (корневой `/`) и Русский (`/ru/`).
* В `<head>` макета `Layout.astro` до первого рендеринга страницы (`before paint`) выполняется ультра-легкий инлайн-скрипт:
  * Считывает сохраненный язык из `localStorage.getItem('shellit_lang')` или проверяет `navigator.language`.
  * Если пользователь предпочитает русский, а находится на `/`, происходит мгновенный редирект на `/ru/...` до отрисовки контента.
* При переключении тумблера языка в шапке выбор запоминается в `localStorage`.

### 4.2. Шапка в стиле Stripe/Supabase (`Navbar.astro`)
* **Выпадающее меню «Продукт»:** Карточки ключевых возможностей с иконками, заголовками и краткими описаниями в одну строку без переносов.
* **Живой счетчик звезд GitHub:** Функция `getRepoStars()` кеширует и отображает реальное число звезд с бейджем звезды.
* **Автоматическое определение платформы для скачивания:** По `navigator.userAgent` определяется ОС посетителя (Windows, Linux, macOS, Android), и на главной кнопке сразу пишется, например, *«Скачать для Windows»*.
* **Универсальное модальное окно (`DownloadModal.astro`):**
  * Вкладки GUI: Windows (`.exe` инсталлятор, `.zip` portable), Linux (`.tar.gz`), Android (`.apk`).
  * Вкладки CLI: пакетные менеджеры `winget install Shellit`, `scoop install shellit`, `curl` one-liner.
  * Карточка текущей ОС подсвечивается зеленым бейджем `Ваша система`.

### 4.3. Документация на базе Astro Starlight
* Статьи хранятся в `src/content/docs/` и группируются по директориям:
  * `getting-started/` (Установка, быстрый старт)
  * `security/` (Шифрование Vault, PROD Guard)
  * `sync/` (Синхронизация через Self-Hosted PocketBase, развертывание в Docker)
  * `ai/` (AI-сниппеты Gemini, запуск и интеграция локального MCP-сервера)
  * `plugins/` (SDK для создания плагинов `.shellit`)
* Русскоязычные версии статей лежат в зеркальной директории `src/content/docs/ru/`.
* При сборке автоматически генерируется локальный поисковый индекс **Pagefind** (`dist/pagefind/`), обеспечивающий мгновенный поиск без внешних сервисов.

### 4.4. Интерактивный роадмап и голосование (`roadmap.astro`)
* Интерактивная доска планов разработки со статусами: *Запланировано*, *В разработке*, *Выпущено*.
* **Двухуровневый источник правды (SSOT):**
  * По умолчанию данные запрашиваются из PocketBase (коллекция `roadmap_items`).
  * Если бэкенд временно недоступен — роадмап мгновенно и бесшовно загружает данные из локального файла монорепозитория `docs/roadmap.data.json`.
* **Атомарное голосование:** Посетители могут голосовать за фичи. Чтобы избежать накруток, на бэкенде работает JS-хук `vote.pb.js`, а в браузере сохраняется уникальный токен избирателя.

### 4.5. Панель управления Shellit Command Center (`/admin/`)
* Закрытый дашборд администратора с аутентификацией суперпользователя PocketBase (`_superusers`).
* Графики на Chart.js: динамика визитов по дням, распределение по ОС и браузерам, популярные страницы, рефереры.
* Управление баг-репортами и отзывами (смена статусов, удаление, просмотр полного текста).
* Синхронизация статистики релизов GitHub.
* Прямая ссылка на стандартную админку PocketBase (`/_/`).

---

## 5. Архитектура бэкенда и сетевая топология (Same-Origin)

### 5.1. Принцип Same-Origin (Единый домен)
* Для исключения проблем с CORS, предварительными запросами `OPTIONS` и настройкой лишних поддоменов вся система работает через **единый домен `https://shellit.top`**:
  * `https://shellit.top/` — статический сайт и документация.
  * `https://shellit.top/api/` — REST API PocketBase.
  * `https://shellit.top/_/` — панель управления базой данных PocketBase.
  * `https://shellit.top/admin/` — аналитический дашборд Shellit Command Center.

### 5.2. Docker Compose стек на сервере Senko (`/opt/shellit`):
```text
[Интернет / Браузер]
         │
         ▼ (HTTPS)
[Cloudflare Edge Network]
         │
         ▼ (Encrypted HTTP/2 Tunnel)
[shellit_cloudflared] (внутри docker-сети shellit_net)
         │
         ▼
[shellit_frontend] (Nginx:alpine на порту 80)
   ├── /_astro/, /*   ──> Отдает статические файлы Astro из /dist/
   ├── /api/*         ──> Проксирует на http://shellit_pocketbase:8090/api/
   └── /_/*           ──> Проксирует на http://shellit_pocketbase:8090/_/
```

### 5.3. Защита от конфликта портов:
* На сервере Senko уже развернут системный обратный прокси, занимающий внешние порты `80` и `443`, а также контейнер `vibestack_pocketbase` на порту `8090`.
* Контейнеры Shellit **не занимают внешние порты 80, 443 и 8090**:
  * Входной трафик забирается контейнером `shellit_cloudflared` через защищенный исходящий туннель Cloudflare.
  * Сервис `shellit_pocketbase` публикуется на хосте только на безопасном локальном адресе `127.0.0.1:8095` (или изолирован внутри Docker-сети).

---

## 6. Регламент сборки, тестирования и деплоя

### 6.1. Локальная разработка:
```bash
# Перейти в каталог сайта
cd apps/website

# Запуск в режиме разработки
npm run dev

# Продакшен-сборка (Astro SSG + Starlight + Pagefind)
npm run build

# Локальный предпросмотр продакшен-сборки
npm run preview
```

### 6.2. Процедура деплоя на продакшен-сервер (Senko):
1. **Сборка сайта:**
   ```powershell
   cmd.exe /c "start /low /b /wait npm.cmd run build"
   ```
2. **Упаковка архива статики:**
   ```powershell
   tar -czf site_deploy.tar.gz -C apps/website/dist .
   ```
3. **Отправка и распаковка на сервере:**
   ```powershell
   scp -o StrictHostKeyChecking=no site_deploy.tar.gz root@$SENKO_HOST:/opt/shellit/
   ssh -o StrictHostKeyChecking=no root@$SENKO_HOST "tar -xzf /opt/shellit/site_deploy.tar.gz -C /opt/shellit/frontend/dist && rm -f /opt/shellit/site_deploy.tar.gz"
   ```
4. **Обновление бэкенда (при изменении миграций или хуков):**
   ```powershell
   tar -czf backend_deploy.tar.gz -C servers/portal_backend pb_hooks pb_migrations
   scp -o StrictHostKeyChecking=no backend_deploy.tar.gz root@$SENKO_HOST:/opt/shellit/
   ssh -o StrictHostKeyChecking=no root@$SENKO_HOST "tar -xzf /opt/shellit/backend_deploy.tar.gz -C /opt/shellit/backend && rm -f /opt/shellit/backend_deploy.tar.gz && docker restart shellit_pocketbase"
   ```

---

## 7. Железные правила и табу для Агента 5

1. **Изоляция репозитория:** Работать только внутри `apps/website/` и `servers/portal_backend/`. Никогда не модифицировать код ядра Flutter (`packages/*`, `apps/shellit/*`), кроме явных указаний пользователя.
2. **Запрет хардкода адресов бэкенда:** Запрещено писать в JS/Astro коде `http://127.0.0.1:8090` или сторонние хосты. Всегда использовать `window.__PUBLIC_POCKETBASE_URL__ || window.location.origin` или относительные пути `/api/...`.
3. **Безопасность учетных данных (Zero Credentials Leakage):** Никаких паролей суперпользователей, токенов туннелей или секретов в открытом git-репозитории.
4. **Статическая стабильность:** Любой новый интерактивный компонент обязан иметь fallback на случай отключенного или заблокированного JavaScript (Graceful Degradation).
5. **Синхронизация контента:** Новые фичи в документации и лендинге обязаны строго соответствовать `docs/ROADMAP.md` и спецификациям ядра Shellit.
