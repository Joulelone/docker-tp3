#!/usr/bin/env bash
set -euo pipefail

# Étape 2 : HTTP (NGINX) + SCRIPT (PHP-FPM+mysqli) + DATA (MariaDB)
# A exécuter depuis etape2 :  ./launch.sh

NET_NAME="tp3net"
PHP_NAME="script"
NGX_NAME="http"
DB_NAME="data"

# 0) Nettoyage des conteneurs homonymes
docker rm -f "$NGX_NAME" "$PHP_NAME" "$DB_NAME" 2>/dev/null || true

# 1) Réseau dédié
if ! docker network inspect "$NET_NAME" >/dev/null 2>&1; then
  docker network create "$NET_NAME" >/dev/null
fi

# 2) Build de l'image PHP-FPM avec mysqli
docker build -t php-fpm-mysqli:8.2 ./php

# 3) Container DATA = MariaDB
#    - DB "tp" + user/pass app/app
#    - Init SQL via /docker-entrypoint-initdb.d
docker run -d --name "$DB_NAME" \
  --network "$NET_NAME" \
  -e MARIADB_RANDOM_ROOT_PASSWORD=1 \
  -e MARIADB_DATABASE=tp \
  -e MARIADB_USER=app \
  -e MARIADB_PASSWORD=app \
  -v "$(pwd)/db/init:/docker-entrypoint-initdb.d:ro" \
  mariadb:11.4

echo "[i] Attente du démarrage de MariaDB (quelques secondes)..."
sleep 8

# 4) Container SCRIPT = PHP-FPM (code monté en volume)
docker run -d --name "$PHP_NAME" \
  --network "$NET_NAME" \
  -v "$(pwd)/src:/app" \
  -w /app \
  php-fpm-mysqli:8.2

# 5) Container HTTP = NGINX (port 8080 -> 80)
docker run -d --name "$NGX_NAME" \
  --network "$NET_NAME" \
  -p 8080:80 \
  -v "$(pwd)/src:/app" \
  -v "$(pwd)/config/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:1.27-alpine

echo
echo "[OK] Étape 2 lancée."
echo "    - PHP info     : http://localhost:8080/"
echo "    - Test mysqli  : http://localhost:8080/test.php"
echo
echo "Nettoyage (si besoin) : docker rm -f $NGX_NAME $PHP_NAME $DB_NAME"
