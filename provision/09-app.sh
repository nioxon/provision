#!/usr/bin/env bash
set -e

source /opt/nioxon/config/runtime.env

APP_BASE="/var/www/nioxplay"
APP_DIR="$APP_BASE/current"
USB_MOUNT="/mnt/usb"

DB_NAME="nioxplay_db"
DB_USER="nioxplay_user"
DB_PASS="niox_play_2190"

MYSQL="mysql -u root"

echo "▶ Deploying Laravel App (offline-safe)"

# --------------------------------------------------
# 1. Detect & mount USB (idempotent)
# --------------------------------------------------
if ! mount | grep -q "$USB_MOUNT"; then
  USB_PART=$(lsblk -rpno NAME,RM,FSTYPE | awk '$2==1 && $3!="" {print $1; exit}')
  [ -n "$USB_PART" ] || { echo "❌ No USB device found"; exit 1; }

  mkdir -p "$USB_MOUNT"
  mount "$USB_PART" "$USB_MOUNT"
fi

ZIP_FILE=$(find "$USB_MOUNT" -maxdepth 2 -iname "nioxplay.zip" | head -n1)
[ -f "$ZIP_FILE" ] || { echo "❌ nioxplay.zip not found on USB"; exit 1; }

echo "✔ Found app package"

# --------------------------------------------------
# 2. Extract app (idempotent)
# --------------------------------------------------
mkdir -p "$APP_BASE"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

unzip -oq "$ZIP_FILE" -d "$APP_DIR"

# Fix nested structure if needed
if [ -d "$APP_DIR/nioxplay" ] && [ ! -f "$APP_DIR/artisan" ]; then
  mv "$APP_DIR/nioxplay/"* "$APP_DIR/"
  rmdir "$APP_DIR/nioxplay"
fi

cd "$APP_DIR"
[ -f artisan ] || { echo "❌ Invalid Laravel package"; exit 1; }

# --------------------------------------------------
# 3. Environment configuration
# --------------------------------------------------
[ -f .env ] || cp .env.example .env

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

php artisan key:generate --force

# --------------------------------------------------
# 4. Permissions
# --------------------------------------------------
chown -R www-data:www-data "$APP_BASE"
chmod -R 775 storage bootstrap/cache

# --------------------------------------------------
# 5. Database setup (CORRECT UBUNTU WAY)
# --------------------------------------------------
echo "▶ Preparing database"

$MYSQL <<SQL
CREATE DATABASE IF NOT EXISTS $DB_NAME
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$DB_USER'@'localhost'
  IDENTIFIED WITH mysql_native_password
  BY '$DB_PASS';

GRANT ALL PRIVILEGES ON $DB_NAME.*
  TO '$DB_USER'@'localhost';

FLUSH PRIVILEGES;
SQL

# --------------------------------------------------
# 6. Verify DB access
# --------------------------------------------------
php artisan migrate:status >/dev/null 2>&1 || {
  echo "❌ Laravel cannot connect to database"
  exit 1
}

# --------------------------------------------------
# 7. Migrate / seed
# --------------------------------------------------
if [ -f database/init.sql ]; then
  mysql "$DB_NAME" < database/init.sql
else
  php artisan migrate --force
  php artisan db:seed --force 2>/dev/null || true
fi

echo "✔ Laravel app deployed successfully"
