---
title: Развертывание в Docker Compose
description: Пошаговая инструкция по деплою сервера синхронизации Shellit.
---

## 1. Подготовка конфигурации

Создайте файл `docker-compose.yml`:

```yaml
version: '3.8'

services:
  shellit-sync:
    image: ghcr.io/shellit/sync-server:latest
    container_name: shellit-sync
    restart: unless-stopped
    ports:
      - "8080:8080"
    volumes:
      - ./data:/data
    environment:
      - PORT=8080
      - DATA_PATH=/data/shellit-sync.db
      - REGISTRATION_TOKEN=your-secret-token
```

## 2. Запуск контейнера

```bash
docker compose up -d
```

Проверьте логи:
```bash
docker compose logs -f
```

## 3. Настройка в приложении Shellit

1. Откройте Shellit на ПК или смартфоне.
2. Перейдите в **Настройки $\rightarrow$ Синхронизация**.
3. Введите адрес вашего сервера: `https://sync.example.com` (или `http://192.168.1.100:8080` для локальной сети).
4. Укажите `REGISTRATION_TOKEN`, если вы настроили защиту от чужих регистраций.
5. Нажмите **«Подключиться»** — синхронизация активирована!
