# Remnawave 2.8.0 Installer (via eGamesAPI scheme)

Установщик Remnawave **2.8.0** (панель + нода) на основе схемы eGamesAPI/remnawave-reverse-proxy (3.0.7), адаптированный под версию 2.8.0.

## Отличия от eGamesAPI 3.0.7 (правки)

| Что | eGamesAPI (3.x) | Этот установщик (2.8.0) |
|---|---|---|
| Панель | `remnawave/backend:2` (= 3.2.3) | `remnawave/backend:2.8.0` |
| Нода | `remnawave/node:latest` (= 3.1.1) | `remnawave/node:2.8.0` |
| Postgres | 18.3 | **16** (совместим с 2.8.0) |
| Subscription Page | latest (8.x) | **7.2.6** (совместим с 2.8.0) |
| Ключ ноды | `SECRET_KEY` (3.x bundle) | `SECRET_KEY` = **pubKey панели** из `GET /api/keygen` → `.response.pubKey` |

## Установка

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/2.8.0/install_remnawave.sh)
```

Меню:
- **1 → 2** — только панель (Nginx)
- **1 → 4** — только нода (Nginx)
- **2** — переустановка (панель/нода)

## Важные нюансы 2.8.0

1. **Ключ ноды** — при установке ноды вставлять **публичный ключ панели** (не секрет 3.x!):
   ```bash
   curl -sk https://panel.example.com/api/keygen -H "Authorization: Bearer <API_TOKEN>" | jq -r '.response.pubKey'
   ```
   (pubKey = base64-бандл с nodeCertPem; env в docker-compose ноды называется `SECRET_KEY`, но значением идёт pubKey)

2. **API-токен** — панель 2.8.0 не пускает JWT админа на `/api/*` (403), нужен API-токен из админки (Settings → API Tokens) или тот, что установщик создаёт для Subscription Page (`REMNAWAVE_API_TOKEN` в docker-compose).

3. **Пользователь** — создаётся через UI/API:
   ```bash
   curl -sk -X POST https://panel.example.com/api/users -H "Authorization: Bearer <API_TOKEN>" -H "Content-Type: application/json" \
     -d '{"username":"Admin","status":"ACTIVE","expireAt":"2099-01-01T00:00:00.000Z"}'
   ```
   Подписка: `https://sub.example.com/<shortUuid>`

4. **Правило нод**: профиль ноды = TCP + gRPC + xHTTP (без Hysteria2). Для установки ноды с мульти-протоколом используется `setup.sh` (Rezzosoft, выбор **[4] Все три (1+2+3)**).

## Файлы

```
install_remnawave.sh      — главный установщик (меню, версии, обновление)
setup.sh                  — setup.sh от Rezzosoft KVN (remnanode-VLESS-Reality-Hysteria2 v3.3)
src/api/remnawave_api.sh  — API-функции панели
src/nginx/                — модули установки (панель/нода, Nginx)
src/caddy/                — модули установки (Caddy-схема)
src/modules/              — add_node, manage_panel, warp, ipv6, selfsteal_templates
src/lang/                 — ru.sh, en.sh
```

## Источники

- Базовый установщик: https://github.com/eGamesAPI/remnawave-reverse-proxy (v3.0.7)
- setup.sh: https://github.com/Rrezzak09VPN/remnanode-VLESS-Reality-Hysteria2
