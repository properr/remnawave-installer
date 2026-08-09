<p align="center">
  <img src="./media/logo.jpg" alt="Remnawave Reverse Proxy" />
</p>

---

# Remnawave Reverse Proxy

**English · Русский · 简体中文**

Installer for the **Remnawave** panel and nodes — a ready-made solution for running your own VPN server. Everything is configured automatically: after installation the panel is already working, the inbound is created, keys are generated, and the subscription is ready.

Multilingual installer: English, Russian, Chinese (Simplified).

---

## Features

- **Panel + node** — on one server or on separate servers
- **Always up-to-date panel** — installed from the official remnawave docker images (tag `latest`); the installer checks and shows the current version from the official remnawave/panel repository
- **Everything out of the box** — a working config is created automatically: keys are generated, your domain is substituted, nothing needs to be configured manually
- **gRPC inbound preconfigured** — the node is created with a Reality gRPC inbound, no manual setup
- **nginx** — the only supported web server
- **Camouflage site** — the server masquerades as a regular website: your clients get VPN, strangers see a regular site
- **SSL certificates** — issued and renewed automatically
- **Panel protection** — access only via a secret address, without it the panel is invisible
- **Multilingual** — English, Russian, Chinese (Simplified)

---

## Requirements

- **OS:** Debian 11 / 12 / 13 or Ubuntu 22.04 / 24.04, fresh installation
- **Access:** root
- **Domains:** your own domain + subdomains (panel, subscription page, node/camouflage domain)

---

## Preparation

**⚡️ System update**

Before installing Remnawave, update the system:

```shell
apt update && apt full-upgrade -y
```

**✅ DNS check**

Make sure the DNS records already point to your VPS IP address before running the installer. This helps avoid errors when issuing SSL certificates and configuring the panel.

Check the records:

```shell
dig +short panel.your-domain.com
dig +short sub.your-domain.com
dig +short node.your-domain.com
```

All three commands must return the **IP address of your VPS**. If nothing is shown or a different address is returned, wait for DNS propagation and check again.

---

## Quick start

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/install_remnawave.sh)
```

The script does everything itself: installs, configures, generates keys and shows the panel login and password.

<p align="center">
  <img src="./media/remnawave-installer.png" alt="Installer interface" />
</p>

---

## Installation modes

| Mode | When to use |
|------|-------------|
| **Panel + node on one server** | Compact installation, moderate traffic |
| **Panel only** | Control center without a VPN node |
| **Node only** | A separate VPN server connected to the panel by key |

---

## DNS setup

**Single server (panel + node):**

| Type | Name | Value | Proxy |
|------|------|-------|-------|
| A | example.com | server IP | DNS only |
| CNAME | panel.example.com | example.com | DNS only |
| CNAME | sub.example.com | example.com | DNS only |
| CNAME | node.example.com | example.com | DNS only |

**Separate installation:** `node.example.com` → node server IP, everything else → panel IP.

---

## Update

The installer can update itself from this repository — menu item "Update".

---

## Repository structure

```
install_remnawave.sh   — main script (installation menu)
src/nginx/             — installation modules for nginx
src/modules/           — panel, node and template management
src/api/               — Remnawave panel API functions
src/lang/              — language files (en, ru, zh-CN)
```

---

> [!CAUTION]
> The tool is intended for administering your own servers. Use at your own risk.

---

---

# Remnawave Reverse Proxy

Установщик панели управления и нод **Remnawave** — готовое решение для раздачи VPN на своём сервере. Всё настраивается автоматически: после установки панель уже работает, инбаунд создан, ключи сгенерированы, подписка готова.

Установщик на трёх языках: английский, русский, китайский (упрощённый).

---

## Что умеет

- **Панель + нода** — на одном сервере или на разных
- **Всегда актуальная панель** — ставится с официальных docker-образов remnawave (тег `latest`); установщик сам проверяет и показывает актуальную версию из официального репозитория remnawave/panel
- **Всё из коробки** — при установке автоматически создаётся рабочий конфиг: ключи генерируются сами, ваш домен подставляется сам, ничего настраивать вручную не нужно
- **GRPC-инбаунд предустановлен** — нода создаётся сразу с Reality gRPC-инбаундом, без ручной настройки
- **nginx** — единственный поддерживаемый веб-сервер
- **Сайт-заглушка** — сервер маскируется под обычный сайт: свои клиенты получают VPN, посторонние видят обычный сайт
- **SSL-сертификаты** — выпускаются и обновляются автоматически
- **Защита панели** — вход только по секретному адресу, без него панель не видна
- **Многоязычность** — английский, русский, китайский (упрощённый)

---

## Требования

- **ОС:** Debian 11 / 12 / 13 или Ubuntu 22.04 / 24.04, свежая установка
- **Доступ:** root
- **Домены:** свой домен + поддомены (панель, страница подписок, домен для заглушки)

---

## Подготовка к установке

**⚡️ Обновление системы**

Перед установкой Remnawave рекомендуется обновить систему:

```shell
apt update && apt full-upgrade -y
```

**✅ Проверка DNS**

Перед запуском скрипта установки убедитесь, что DNS-записи уже указывают на IP-адрес вашего VPS. Это поможет избежать ошибок при выпуске SSL-сертификатов и настройке панели.

Проверьте записи:

```shell
dig +short panel.ваш-домен.ru
dig +short sub.ваш-домен.ru
dig +short node.ваш-домен.ru
```

Все три команды должны вернуть **IP-адрес вашего VPS**. Если вместо IP-адреса ничего не отображается или указан другой адрес — дождитесь обновления DNS-записей и повторите проверку.

---

## Быстрый старт

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/install_remnawave.sh)
```

Скрипт сам всё сделает: установит, настроит, сгенерирует ключи и покажет логин с паролем от панели.

<p align="center">
  <img src="./media/remnawave-installer.png" alt="Интерфейс установки" />
</p>

---

## Режимы установки

| Режим | Когда нужен |
|-------|-------------|
| **Панель + нода на одном сервере** | Компактная установка, умеренный трафик |
| **Только панель** | Центр управления без VPN-ноды |
| **Только нода** | Отдельный сервер с VPN, подключается к панели по ключу |

---

## Настройка DNS

**Один сервер (панель + нода):**

| Тип | Имя | Значение | Прокси |
|-----|-----|----------|--------|
| A | example.com | IP сервера | DNS only |
| CNAME | panel.example.com | example.com | DNS only |
| CNAME | sub.example.com | example.com | DNS only |
| CNAME | node.example.com | example.com | DNS only |

**Раздельная установка:** `node.example.com` → IP сервера ноды, остальное → IP панели.

---

## Обновление

Установщик умеет обновлять сам себя из этого репозитория — пункт меню «Обновление».

---

## Структура репозитория

```
install_remnawave.sh   — основной скрипт (меню установки)
src/nginx/             — модули установки для nginx
src/modules/           — управление панелью, нодами, шаблонами
src/api/               — работа с API панели
src/lang/              — языковые файлы (en, ru, zh-CN)
```

---

> [!CAUTION]
> Инструмент предназначен для администрирования собственных серверов. Используйте на свой риск.

---

---

# Remnawave Reverse Proxy

**Remnawave** 面板和节点安装程序——在您自己的服务器上搭建 VPN 的一站式解决方案。所有内容自动配置：安装后面板即可使用，入站已创建，密钥已生成，订阅已就绪。

支持三种语言：英语、俄语、简体中文。

---

## 功能特性

- **面板 + 节点** — 可在同一台服务器或不同服务器上
- **面板始终最新** — 从官方 remnawave docker 镜像（`latest` 标签）安装；安装程序自动检查并显示来自官方 remnawave/panel 仓库的最新版本
- **开箱即用** — 自动创建工作配置：密钥自动生成，域名自动替换，无需手动配置
- **预配置 gRPC 入站** — 节点直接创建 Reality gRPC 入站，无需手动设置
- **nginx** — 唯一支持的 Web 服务器
- **伪装网站** — 服务器伪装成普通网站：您的客户端获得 VPN，陌生人看到普通网站
- **SSL 证书** — 自动签发和续期
- **面板保护** — 只能通过秘密地址访问，否则面板不可见
- **多语言** — 英语、俄语、简体中文

---

## 系统要求

- **操作系统：** Debian 11 / 12 / 13 或 Ubuntu 22.04 / 24.04，全新安装
- **权限：** root
- **域名：** 您自己的域名 + 子域名（面板、订阅页面、节点/伪装域名）

---

## 安装前准备

**⚡️ 更新系统**

安装 Remnawave 前，建议先更新系统：

```shell
apt update && apt full-upgrade -y
```

**✅ 检查 DNS**

运行安装脚本前，请确保 DNS 记录已指向您的 VPS IP 地址。这有助于避免签发 SSL 证书和配置面板时出错。

检查记录：

```shell
dig +short panel.您的域名.com
dig +short sub.您的域名.com
dig +short node.您的域名.com
```

三条命令都应返回**您的 VPS IP 地址**。如果没有显示或返回了其他地址，请等待 DNS 生效后重新检查。

---

## 快速开始

```bash
bash <(curl -Ls https://raw.githubusercontent.com/properr/remnawave-installer/refs/heads/main/install_remnawave.sh)
```

脚本会自动完成所有操作：安装、配置、生成密钥，并显示面板的登录名和密码。

<p align="center">
  <img src="./media/remnawave-installer.png" alt="安装程序界面" />
</p>

---

## 安装模式

| 模式 | 适用场景 |
|------|----------|
| **面板 + 节点在同一台服务器** | 紧凑安装，流量适中 |
| **仅面板** | 不带 VPN 节点的控制中心 |
| **仅节点** | 独立 VPN 服务器，通过密钥连接到面板 |

---

## DNS 设置

**单台服务器（面板 + 节点）：**

| 类型 | 名称 | 值 | 代理 |
|------|------|-----|------|
| A | example.com | 服务器 IP | DNS only |
| CNAME | panel.example.com | example.com | DNS only |
| CNAME | sub.example.com | example.com | DNS only |
| CNAME | node.example.com | example.com | DNS only |

**分开安装：** `node.example.com` → 节点服务器 IP，其余 → 面板 IP。

---

## 更新

安装程序可以从本仓库自行更新 — 菜单项“更新”。

---

## 仓库结构

```
install_remnawave.sh   — 主脚本（安装菜单）
src/nginx/             — nginx 安装模块
src/modules/           — 面板、节点和模板管理
src/api/               — Remnawave 面板 API 函数
src/lang/              — 语言文件（en, ru, zh-CN）
```

---

> [!CAUTION]
> 此工具用于管理您自己的服务器。请自行承担使用风险。

---

## ☁️ 支持项目

