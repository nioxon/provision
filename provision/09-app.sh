#!/usr/bin/env bash
set -euo pipefail

# ==================================================
# Load runtime configuration
# ==================================================
RUNTIME_ENV="/opt/nioxon/config/runtime.env"
[ -f "$RUNTIME_ENV" ] || { echo "❌ runtime.env missing"; exit 1; }
set -a
source "$RUNTIME_ENV"
set +a

echo "▶ Deploying NioxPlay Laravel App"

# ==================================================
# Variables (LOCKED)
# ==================================================
APP_BASE="/var/www/nioxplay"
APP_DIR="$APP_BASE/current"

DB_NAME="nioxplay_db"
DB_USER="nioxplay_user"
DB_PASS="niox_play_2190"

PHP_BIN="$(command -v php)"
MYSQL_BIN="$(command -v mysql)"

# ==================================================
# Guards
# ==================================================
command -v php >/dev/null || { echo "❌ PHP not installed"; exit 1; }
php -m | grep -q pdo_mysql || { echo "❌ php-mysql missing"; exit 1; }
systemctl is-active mysql >/dev/null || { echo "❌ MySQL not running"; exit 1; }

# ==================================================
# 1. Locate USB ZIP (OFFLINE SAFE)
# ==================================================
echo "🔍 Detecting USB device"

USB_PART=$(lsblk -rpno NAME,TRAN,FSTYPE | awk '$2=="usb" && $3!="" {print $1; exit}')

if [ -z "$USB_PART" ]; then
  echo "❌ No USB storage device detected"
  lsblk
  exit 1
fi

echo "✔ USB device: $USB_PART"

USB_MOUNT="/mnt/usb"

if ! mount | grep -q "$USB_PART"; then
  echo "▶ Mounting USB to $USB_MOUNT"
  mkdir -p "$USB_MOUNT"
  mount "$USB_PART" "$USB_MOUNT" || {
    echo "❌ Failed to mount USB"
    exit 1
  }
else
  USB_MOUNT=$(findmnt -n -o TARGET "$USB_PART")
fi

echo "✔ USB mounted at $USB_MOUNT"

echo "🔍 Searching for nioxplay.zip on USB"

#USB_ZIP="$(find /mnt /media /run/media -type f -iname 'nioxplay.zip' 2>/dev/null | head -n1 || true)"
USB_ZIP=$(find "$USB_MOUNT" -maxdepth 2 -type f -iname "*.zip" | grep -i nioxplay | head -n1)


if [ -z "$USB_ZIP" ]; then
  echo "❌ nioxplay ZIP not found"
  echo "Files on USB:"
  find "$USB_MOUNT" -maxdepth 2 -type f
  exit 1
fi

echo "✔ Found ZIP: $USB_ZIP"

# ==================================================
# 2. Extract Application (IDEMPOTENT)
# ==================================================
echo "▶ Extracting application"

mkdir -p "$APP_BASE"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

unzip -oq "$USB_ZIP" -d "$APP_DIR"

# Handle nested zip structure
if [ -d "$APP_DIR/nioxplay" ] && [ ! -f "$APP_DIR/artisan" ]; then
  mv "$APP_DIR/nioxplay/"* "$APP_DIR/"
  rmdir "$APP_DIR/nioxplay"
fi

[ -f "$APP_DIR/artisan" ] || { echo "❌ Invalid Laravel package (artisan missing)"; exit 1; }

cd "$APP_DIR"

# ==================================================
# 3. Environment Configuration
# ==================================================
echo "▶ Configuring environment"

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
php artisan config:clear

# ==================================================
# 4. Permissions
# ==================================================
echo "▶ Fixing permissions"

chown -R www-data:www-data "$APP_BASE"
find "$APP_DIR" -type d -exec chmod 755 {} \;
chmod -R 775 storage bootstrap/cache

# ==================================================
# 5. Database (TCP-ONLY, PRODUCTION SAFE)
# ==================================================
echo "▶ Preparing database"

mysql -u root <<SQL
CREATE DATABASE IF NOT EXISTS \`$DB_NAME\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '$DB_USER'@'127.0.0.1'
  IDENTIFIED WITH mysql_native_password BY '$DB_PASS';

CREATE USER IF NOT EXISTS '$DB_USER'@'%'
  IDENTIFIED WITH mysql_native_password BY '$DB_PASS';

GRANT ALL PRIVILEGES ON \`$DB_NAME\`.*
  TO '$DB_USER'@'127.0.0.1';

GRANT ALL PRIVILEGES ON \`$DB_NAME\`.*
  TO '$DB_USER'@'%';

FLUSH PRIVILEGES;
SQL

# ==================================================
# 6. Verify DB Access (HARD CHECK)
# ==================================================
php -r '
new PDO(
  "mysql:host=127.0.0.1;dbname='"$DB_NAME"'",
  "'"$DB_USER"'",
  "'"$DB_PASS"'"
);
' || { echo "❌ Database connection failed"; exit 1; }

# ==================================================
# 7. Migrations / Seed
# ==================================================
if [ -f database/init.sql ]; then
  echo "▶ Importing database/init.sql"
  mysql -u root "$DB_NAME" < database/init.sql
else
  echo "▶ Running migrations"
  php artisan migrate --force
  php artisan db:seed --force 2>/dev/null || true
fi

# ==================================================
# 8. Optimize Laravel
# ==================================================
composer install
php artisan config:cache
php artisan route:cache || true
php artisan view:clear


echo "✔ NioxPlay app deployed successfully"
