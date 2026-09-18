# Shellit Self-Hosted Sync Server

Легковесный, автономный сервер синхронизации с нулевым разглашением (**Zero-Knowledge E2EE**) для кроссплатформенного SSH-клиента **Shellit**.

---

## ⚡ Особенности

* **Zero-Knowledge E2EE:** Сервер оперирует исключительно зашифрованными бинарными блобами (`nonce + tag + ciphertext`). Хосты, ключи, пароли и сниппеты расшифровываются исключительно на клиентах.
* **Минимальное потребление ресурсов:** Потребляет менее 15–20 МБ оперативной памяти.
* **Автономность:** Встроенная база данных SQLite (`/data/shellit-sync.db`), не требуются сторонние СУБД вроде PostgreSQL или Redis.
* **Любой транспорт:** Работает как по чистому `http://` (внутри WireGuard / Tailscale / LAN), так и по `https://` (за Nginx / Caddy / Traefik) или с самоподписанными сертификатами.
* **Реалтайм-нотификации:** Поддержка WebSocket для мгновенного оповещения подключенных клиентов о появлении новых ревизий.

---

## 🚀 Быстрый запуск (1 минута)

### Вариант 1: Docker Compose (Рекомендуемый)

1. Создайте файл `docker-compose.yml`:
```yaml
version: '3.8'

services:
  shellit-sync:
    image: ghcr.io/shellit/sync-server:latest # или build: .
    container_name: shellit-sync
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - PORT=8080
      - DATA_PATH=/data/shellit-sync.db
      - REGISTRATION_TOKEN=super-secret-invite-token # Опционально: защита от чужих регистраций
```

2. Запустите:
```bash
docker compose up -d
```

### Вариант 2: Запуск без Docker (через Dart SDK)

```bash
# Клонировать репозиторий и перейти в папку сервера
cd servers/sync_server

# Запуск
dart run bin/server.dart

# Или скомпилировать в один статический бинарник
dart compile exe bin/server.dart -o shellit-sync-server
./shellit-sync-server
```

---

## 🔒 Переменные окружения

| Переменная | По умолчанию | Описание |
|---|---|---|
| `PORT` | `8080` | Порт прослушивания |
| `HOST` | `0.0.0.0` | Сетевой интерфейс |
| `DATA_PATH` | `./data/shellit-sync.db` | Путь к файлу SQLite базы данных |
| `REGISTRATION_TOKEN` | *пусто* | Опциональный токен приглашения. Если задан, создание нового хранилища (vault) требует ввода этого токена |

---

## 📱 Подключение в приложении Shellit

1. Откройте **Settings → Synchronization**.
2. Введите:
   * **Server URL:** `http://your-vps-ip:8080` или `https://sync.your-domain.com`.
   * **Vault ID:** Уникальное имя вашего хранилища (например, `my-servers`).
   * **Sync Passphrase:** Парольная фраза для E2EE-шифрования (из нее на клиенте деривируется мастер-ключ синхронизации).
   * **Registration Token:** Токен (если задан в `REGISTRATION_TOKEN` на сервере).
   * Если сервер работает по HTTPS с самоподписанным сертификатом, включите **«Доверять самоподписанным сертификатам»**.
3. Нажмите **«Синхронизировать сейчас»**.
