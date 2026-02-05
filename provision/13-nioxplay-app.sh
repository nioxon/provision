#!/usr/bin/env bash
set -e

# --------------------------------------------------
# Load runtime config
# --------------------------------------------------
RUNTIME_ENV="/opt/nioxon/config/runtime.env"
if [ ! -f "$RUNTIME_ENV" ]; then
  echo "❌ runtime.env not found"
  exit 1
fi

set -a
source "$RUNTIME_ENV"
set +a

export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

echo "▶ Setting up NioxPlay Laravel App (USB mode)"

APP_DIR="/var/www/nioxplay/current"

DB_NAME="nioxplay"
DB_USER="root"
DB_PASS=""

# --------------------------------------------------
# 0. Locate nioxplay.zip on USB (ROBUST)
# --------------------------------------------------
echo "🔍 Searching for nioxplay.zip on removable media..."

ZIP_FILE=$(find /media /run/media -type f -iname "nioxplay.zip" 2>/dev/null | head -n1)

if [ -z "$ZIP_FILE" ]; then
  echo "❌ nioxplay.zip not found on any mounted USB"
  echo "Expected file: nioxplay.zip at root of USB"
  exit 1
fi

echo "✔ Found ZIP at: $ZIP_FILE"

# --------------------------------------------------
# 1. Extract app
# --------------------------------------------------
echo "▶ Extracting Laravel app"

mkdir -p /var/www/nioxplay
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

unzip -oq "$ZIP_FILE" -d "$APP_DIR"

# Handle extra nesting if ZIP contains nioxplay/
if [ -d "$APP_DIR/nioxplay" ] && [ ! -f "$APP_DIR/artisan" ]; then
  echo "ℹ Fixing nested zip structure"
  mv "$APP_DIR/nioxplay/"* "$APP_DIR/"
  rmdir "$APP_DIR/nioxplay"
fi

cd "$APP_DIR"

if [ ! -f artisan ]; then
  echo "❌ Invalid Laravel app: artisan not found"
  exit 1
fi

# --------------------------------------------------
# 2. ENV setup
# --------------------------------------------------
[ ! -f .env ] && cp .env.example .env

sed -i "s|^APP_NAME=.*|APP_NAME=NioxPlay|" .env
sed -i "s|^APP_ENV=.*|APP_ENV=local|" .env
sed -i "s|^APP_DEBUG=.*|APP_DEBUG=false|" .env
sed -i "s|^APP_URL=.*|APP_URL=http://$SITE_DOMAIN|" .env

sed -i "s|^DB_CONNECTION=.*|DB_CONNECTION=mysql|" .env
sed -i "s|^DB_HOST=.*|DB_HOST=127.0.0.1|" .env
sed -i "s|^DB_PORT=.*|DB_PORT=3306|" .env
sed -i "s|^DB_DATABASE=.*|DB_DATABASE=$DB_NAME|" .env
sed -i "s|^DB_USERNAME=.*|DB_USERNAME=$DB_USER|" .env
sed -i "s|^DB_PASSWORD=.*|DB_PASSWORD=$DB_PASS|" .env

grep -q "^APP_MODE=" .env || echo "APP_MODE=local" >> .env

# --------------------------------------------------
# 3. App key
# --------------------------------------------------
php artisan key:generate --force

# --------------------------------------------------
# 4. Permissions
# --------------------------------------------------
chown -R www-data:www-data /var/www/nioxplay
chmod -R 775 storage bootstrap/cache

# --------------------------------------------------
# 5. Database
# --------------------------------------------------
mysql -u"$DB_USER" -p"$DB_PASS" -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

php artisan migrate:status >/dev/null 2>&1 || {
  echo "❌ Database connection failed"
  exit 1
}

# --------------------------------------------------
# 6. Migrate / Seed / SQL
# --------------------------------------------------
if [ -f database/init.sql ]; then
  echo "▶ Importing SQL"
  mysql -u"$DB_USER" -p"$DB_PASS" "$DB_NAME" < database/init.sql
else
  php artisan migrate --force
  php artisan db:seed --force 2>/dev/null || true
fi

# --------------------------------------------------
# 7. Optimize
# --------------------------------------------------
php artisan config:clear
php artisan config:cache
php artisan route:cache || true
php artisan view:clear

# --------------------------------------------------
# 8. PM2 (non-root user recommended)
# --------------------------------------------------
pm2 delete nioxplay-worker 2>/dev/null || true

pm2 start "php artisan queue:work --sleep=3 --tries=3" \
  --name nioxplay-worker

pm2 save

echo "✔ NioxPlay app setup completed successfully (USB)"
