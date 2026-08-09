#!/bin/bash
# Модуль: установка только ноды

install_node_nginx() {
    # Подключаем модуль шаблонов SelfSteal
    load_selfsteal_templates_module

    mkdir -p /opt/remnanode && cd /opt/remnanode

    reading "${LANG[SELFSTEAL]}" SELFSTEAL_DOMAIN

    check_domain "$SELFSTEAL_DOMAIN" true false
    local domain_check_result=$?
    if [ $domain_check_result -eq 2 ]; then
        echo -e "${COLOR_RED}${LANG[ABORT_MESSAGE]}${COLOR_RESET}"
        exit 1
    fi

    while true; do
        reading "${LANG[PANEL_IP_PROMPT]}" PANEL_IP
        if echo "$PANEL_IP" | grep -E '^([0-9]{1,3}\.){3}[0-9]{1,3}$' >/dev/null && \
           [[ $(echo "$PANEL_IP" | tr '.' '\n' | wc -l) -eq 4 ]] && \
           [[ ! $(echo "$PANEL_IP" | tr '.' '\n' | grep -vE '^[0-9]{1,3}$') ]] && \
           [[ ! $(echo "$PANEL_IP" | tr '.' '\n' | grep -E '^(25[6-9]|2[6-9][0-9]|[3-9][0-9]{2})$') ]]; then
            break
        else
            echo -e "${COLOR_RED}${LANG[IP_ERROR]}${COLOR_RESET}"
        fi
    done

    # --- Секрет ноды ---
    # Remnawave 3.x: оставляем пустым (Enter) -> установщик сам создаст ноду в панели
    # и получит секрет через GET /api/keygen. Remnawave 2.x / ручной режим:
    # вставляем Secret Key из карточки редактирования ноды.
    echo -n "$(question "${LANG[NODE_SECRET_PROMPT]}")"
    CERTIFICATE=""
    while IFS= read -r line; do
        if [ -z "$line" ]; then
            if [ -n "$CERTIFICATE" ]; then
                break
            fi
        else
            CERTIFICATE="$CERTIFICATE$line\n"
        fi
    done

    if [ -n "$CERTIFICATE" ]; then
        # Ручной режим (обратная совместимость с панелью 2.x) — API панели не трогаем
        echo -e "${COLOR_YELLOW}${LANG[NODE_MANUAL_SECRET_USED]}${COLOR_RESET}"
        echo -e "${COLOR_YELLOW}${LANG[CERT_CONFIRM]}${COLOR_RESET}"
        read confirm
        echo

        if [[ "$confirm" != "y" && "$confirm" != "Y" && "$confirm" != "у" && "$confirm" != "У" ]]; then
            echo -e "${COLOR_RED}${LANG[ABORT_MESSAGE]}${COLOR_RESET}"
            exit 1
        fi
        NODE_API_MODE="manual"
    else
        # Автоматический режим (Remnawave 3.x) — нужны данные панели для API:
        # либо API-токен (Bearer), либо логин/пароль суперадмина для автологина.
        NODE_API_MODE="auto"
        reading "${LANG[NODE_API_TOKEN_PROMPT]}" PANEL_API_TOKEN
        if [ -z "$PANEL_API_TOKEN" ]; then
            reading "${LANG[NODE_PANEL_LOGIN_PROMPT]}" PANEL_ADMIN_LOGIN
            reading "${LANG[NODE_PANEL_PASSWORD_PROMPT]}" PANEL_ADMIN_PASSWORD
        fi
    fi

SELFSTEAL_BASE_DOMAIN=$(extract_domain "$SELFSTEAL_DOMAIN")

unique_domains["$SELFSTEAL_BASE_DOMAIN"]=1

cat > docker-compose.yml <<EOL
x-common: &common
  ulimits:
    nofile:
      soft: 1048576
      hard: 1048576
  restart: always

x-logging: &logging
  logging:
    driver: json-file
    options:
      max-size: 100m
      max-file: 5

services:
  remnawave-nginx:
    image: nginx:1.28
    container_name: remnawave-nginx
    hostname: remnawave-nginx
    <<: [*common, *logging]
    network_mode: host
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
EOL
}

installation_node() {
    echo -e "${COLOR_YELLOW}${LANG[INSTALLING_NODE]}${COLOR_RESET}"
    sleep 1

    declare -A unique_domains
    install_node_nginx

    declare -A domains_to_check
    domains_to_check["$SELFSTEAL_DOMAIN"]=1

    handle_certificates domains_to_check "$CERT_METHOD" "$LETSENCRYPT_EMAIL" "/opt/remnanode"

    if [ -z "$CERT_METHOD" ]; then
        local base_domain=$(extract_domain "$SELFSTEAL_DOMAIN")
        if [ -d "/etc/letsencrypt/live/$base_domain" ] && is_wildcard_cert "$base_domain"; then
            CERT_METHOD="1"
        else
            CERT_METHOD="2"
        fi
    fi

    if [ "$CERT_METHOD" == "1" ]; then
        local base_domain=$(extract_domain "$SELFSTEAL_DOMAIN")
        NODE_CERT_DOMAIN="$base_domain"
    else
        NODE_CERT_DOMAIN="$SELFSTEAL_DOMAIN"
    fi

    cat >> /opt/remnanode/docker-compose.yml <<EOL
      - /dev/shm:/dev/shm:rw
      - /var/www/html:/var/www/html:ro
    command: sh -c 'rm -f /dev/shm/nginx.sock && exec nginx -g "daemon off;"'

  remnanode:
    image: remnawave/node:latest
    container_name: remnanode
    hostname: remnanode
    <<: [*common, *logging]
    network_mode: host
    cap_add:
      - NET_ADMIN
    environment:
      - NODE_PORT=2222
      - SECRET_KEY=$(echo -e "$CERTIFICATE")
    volumes:
      - /dev/shm:/dev/shm:rw
EOL

cat > /opt/remnanode/nginx.conf <<EOL
server_names_hash_bucket_size 64;

map \$http_upgrade \$connection_upgrade {
    default upgrade;
    ""      close;
}

ssl_protocols TLSv1.2 TLSv1.3;
ssl_ecdh_curve X25519:prime256v1:secp384r1;
ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:DHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-CHACHA20-POLY1305;
ssl_prefer_server_ciphers on;
ssl_session_timeout 1d;
ssl_session_cache shared:MozSSL:10m;
ssl_session_tickets off;

server {
    server_name $SELFSTEAL_DOMAIN;
    listen unix:/dev/shm/nginx.sock ssl proxy_protocol;
    http2 on;

    ssl_certificate "/etc/nginx/ssl/$NODE_CERT_DOMAIN/fullchain.pem";
    ssl_certificate_key "/etc/nginx/ssl/$NODE_CERT_DOMAIN/privkey.pem";
    ssl_trusted_certificate "/etc/nginx/ssl/$NODE_CERT_DOMAIN/fullchain.pem";

    root /var/www/html;
    index index.html;
    add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
}

server {
    listen unix:/dev/shm/nginx.sock ssl proxy_protocol default_server;
    server_name _;
    add_header X-Robots-Tag "noindex, nofollow, noarchive, nosnippet, noimageindex" always;
    ssl_reject_handshake on;
    return 444;
}
EOL

    # Remnawave 3.x: автосоздание ноды в панели, автополучение секрета, добавление хоста
    if [ "$NODE_API_MODE" = "auto" ]; then
        node_api_setup
    fi

    ufw allow 80/tcp > /dev/null 2>&1
    ufw allow 443/tcp > /dev/null 2>&1
    ufw allow 2222/tcp > /dev/null 2>&1
    ufw reload > /dev/null 2>&1
    ufw allow from $PANEL_IP to any port 2222 > /dev/null 2>&1
    ufw reload > /dev/null 2>&1

    echo -e "${COLOR_YELLOW}${LANG[STARTING_NODE]}${COLOR_RESET}"
    sleep 3
    cd /opt/remnanode
    docker compose up -d > /dev/null 2>&1 &

    spinner $! "${LANG[WAITING]}"

    randomhtml

    printf "${COLOR_YELLOW}${LANG[NODE_CHECK]}${COLOR_RESET}\n" "$SELFSTEAL_DOMAIN"
    local max_attempts=5
    local attempt=1
    local delay=15

    while [ $attempt -le $max_attempts ]; do
        printf "${COLOR_YELLOW}${LANG[NODE_ATTEMPT]}${COLOR_RESET}\n" "$attempt" "$max_attempts"
        if curl -s --fail --max-time 10 "https://$SELFSTEAL_DOMAIN" | grep -q "html"; then
            echo -e "${COLOR_GREEN}${LANG[NODE_LAUNCHED]}${COLOR_RESET}"
            break
        else
            printf "${COLOR_RED}${LANG[NODE_UNAVAILABLE]}${COLOR_RESET}\n" "$attempt"
            if [ $attempt -eq $max_attempts ]; then
                printf "${COLOR_RED}${LANG[NODE_NOT_CONNECTED]}${COLOR_RESET}\n" "$max_attempts"
                echo -e "${COLOR_YELLOW}${LANG[CHECK_CONFIG]}${COLOR_RESET}"
                exit 1
            fi
            sleep $delay
        fi
        ((attempt++))
    done
}

# Автоматическая регистрация ноды в панели Remnawave 3.x:
# 1) токен (введённый API-токен или автологин логином/паролем суперадмина);
# 2) создание ноды через POST /api/nodes (Default-Profile + инбаунд, имя «Steal»);
# 3) секрет ноды через GET /api/keygen -> подстановка SECRET_KEY в docker-compose;
# 4) добавление selfsteal-домена в hosts через create_host (для serverNames/SNI).
node_api_setup() {
    local domain_url="$PANEL_IP:3000"
    local api_base="http://$domain_url"

    echo -e "${COLOR_YELLOW}${LANG[NODE_API_STEPS]}${COLOR_RESET}"

    # Проверяем доступность API панели (порт 3000)
    if ! curl -s --max-time 10 -o /dev/null "$api_base/api/auth/status"; then
        echo -e "${COLOR_RED}$(printf "${LANG[NODE_PANEL_IP_REACH_FAIL]}" "$api_base")${COLOR_RESET}"
        exit 1
    fi

    # Получаем токен: введённый API-токен либо автологин суперадмином
    local token="$PANEL_API_TOKEN"
    if [ -z "$token" ]; then
        local login_response
        login_response=$(make_api_request "POST" "$api_base/api/auth/login" "" "{\"username\":\"$PANEL_ADMIN_LOGIN\",\"password\":\"$PANEL_ADMIN_PASSWORD\"}")
        token=$(echo "$login_response" | jq -r '.response.accessToken // .accessToken // ""' 2>/dev/null)
        if [ -z "$token" ] || [ "$token" = "null" ]; then
            echo -e "${COLOR_RED}${LANG[NODE_API_AUTH_FAIL]}: $login_response${COLOR_RESET}"
            exit 1
        fi
        echo -e "${COLOR_GREEN}${LANG[NODE_AUTH_LOGIN_SUCCESS]}${COLOR_RESET}"
    fi

    # Проверяем валидность токена и доступ к API
    local test_response
    test_response=$(make_api_request "GET" "$api_base/api/config-profiles" "$token")
    if [ -z "$test_response" ] || ! echo "$test_response" | jq -e '.response.configProfiles' > /dev/null 2>&1; then
        echo -e "${COLOR_RED}${LANG[NODE_API_TOKEN_INVALID]}: $test_response${COLOR_RESET}"
        exit 1
    fi

    # Локальный IP сервера — адрес, по которому панель будет подключаться к ноде
    local node_address
    node_address=$(hostname -I 2>/dev/null | awk '{print $1}')
    if [ -z "$node_address" ]; then
        reading "${LANG[NODE_ADDRESS_PROMPT]}" node_address
    fi
    echo -e "${COLOR_YELLOW}$(printf "${LANG[NODE_ADDRESS_INFO]}" "$node_address")${COLOR_RESET}"

    # Берём Default-Profile панели и его инбаунды
    local config_profile_uuid
    config_profile_uuid=$(get_config_profiles "$domain_url" "$token")
    # get_config_profiles может выводить предупреждения в stdout — оставляем только UUID
    config_profile_uuid=$(echo "$config_profile_uuid" | grep -oE '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' | head -1)

    local inbound_uuid=""
    if [ -n "$config_profile_uuid" ]; then
        inbound_uuid=$(get_profile_inbounds "$domain_url" "$token" "$config_profile_uuid")
    fi

    if [ -n "$config_profile_uuid" ] && [ -n "$inbound_uuid" ]; then
        # Полноценная нода: профиль + инбаунд + хост
        echo -e "${COLOR_YELLOW}${LANG[CREATING_NODE]}${COLOR_RESET}"
        create_node "$domain_url" "$token" "$config_profile_uuid" "$inbound_uuid" "$node_address" "Steal"

        echo -e "${COLOR_YELLOW}${LANG[CREATE_HOST]}${COLOR_RESET}"
        create_host "$domain_url" "$token" "$inbound_uuid" "$SELFSTEAL_DOMAIN" "$config_profile_uuid"
    else
        # Профиль или инбаунды не найдены — создаём ноду без привязки профиля
        if [ -n "$config_profile_uuid" ] && [ -z "$inbound_uuid" ]; then
            echo -e "${COLOR_YELLOW}${LANG[NODE_PROFILE_INBOUND_NOT_FOUND]}${COLOR_RESET}"
        else
            echo -e "${COLOR_YELLOW}${LANG[NODE_PROFILE_NOT_FOUND]}${COLOR_RESET}"
        fi
        echo -e "${COLOR_YELLOW}${LANG[NODE_CREATED_SIMPLE]}${COLOR_RESET}"
        local node_data
        node_data=$(jq -n --arg name "Steal" --arg addr "$node_address" '{name: $name, address: $addr, port: 2222, isTrafficTrackingActive: false, trafficLimitBytes: 0, notifyPercent: 0, trafficResetDay: 31, excludedInbounds: [], countryCode: "XX", consumptionMultiplier: 1.0}')
        make_api_request "POST" "$api_base/api/nodes" "$token" "$node_data" > /dev/null
    fi

    # Получаем секрет ноды (подписанный сертификат панели) и прописываем в docker-compose
    local node_secret
    node_secret=$(get_node_secret_key "$domain_url" "$token")
    if [ -n "$node_secret" ] && [ "$node_secret" != "null" ]; then
        awk -v s="$node_secret" '{ if ($0 ~ /SECRET_KEY=/) print "      - SECRET_KEY=\"" s "\""; else print }' docker-compose.yml > /tmp/dc.tmp && mv /tmp/dc.tmp docker-compose.yml
        echo -e "${COLOR_GREEN}${LANG[NODE_SECRET_SET]}${COLOR_RESET}"
    else
        echo -e "${COLOR_RED}${LANG[NODE_SECRET_FAIL]}${COLOR_RESET}"
    fi
}
