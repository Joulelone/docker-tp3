#!/usr/bin/env bash
set -euo pipefail

NET_NAME="tp3net"
PHP_NAME="script"
NGX_NAME="http"

# 0) Nettoyage des conteneurs homonymes pour éviter les conflits
docker rm -f "$NGX_NAME" "$PHP_NAME" 2>/dev/null || true

# 1) Réseau dédié (pas le réseau par défaut)
if ! docker network inspect "$NET_NAME" >/dev/null 2>&1; then
  docker network create "$NET_NAME" >/dev/null
fi

# 2) Container SCRIPT = PHP-FPM
#    - Monte /app depuis ./src (bind mount)
docker run -d --name "$PHP_NAME" \
  --network "$NET_NAME" \
  -v "$(pwd)/src:/app" \
  -w /app \
  php:8.2-fpm >/dev/null

# 3) Container HTTP = NGINX
#    - Publie port 8080 -> 80
#    - Monte la même /app et la conf nginx
docker run -d --name "$NGX_NAME" \
  --network "$NET_NAME" \
  -p 8080:80 \
  -v "$(pwd)/src:/app" \
  -v "$(pwd)/config/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro" \
  nginx:1.27-alpine >/dev/null

echo "[OK] Étape 1 lancée. Ouvre http://localhost:8080/ (phpinfo)."
echo "Astuce nettoyage: docker rm -f $NGX_NAME $PHP_NAME"
