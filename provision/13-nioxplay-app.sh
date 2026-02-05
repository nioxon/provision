#!/usr/bin/env bash
set -e

# ==================================================
# Load runtime configuration
# ==================================================
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

# ==================================================
# Variables
# ==================================================
APP_BASE="/var/www/nioxplay"
APP_DIR="$APP_BASE/current"

DB_NAME="nioxplay"
DB_USER="root"
DB_PASS=""

# ==================================================
# 0. Detect and mount USB PARTITION (FIXED)
# ==================================================
echo "🔍 Detecting removable USB partition..."

USB_PART=$(lsblk -rpno NAME,RM,FSTYPE | awk '$2==1 && $3!="" {print $1; exit}')

if [ -z "$USB_PART" ]; then
  echo "❌ No removable USB partition found"
  lsblk
  exit 1
fi

echo "✔ USB partition detected: $USB_PART"

if ! mount | grep -q "$USB_PART"; then
  echo "▶ Mounting USB partition at /mnt/usb"
  mkdir -p /mnt/usb
  mount "$USB_PART" /mnt/usb
fi

# ==================================================
# 1. Locate ZIP
# ==================================================
echo "🔍 Searching for nioxplay.zip..."

ZIP_FILE=$(find /mnt/usb /media /run/media -type f -iname "nioxplay.zip" 2>/dev/null | head -n1)

if [ -z "$ZIP_FILE" ]; then
  echo "❌ nioxplay.zip not found on USB"
  echo "Contents of /mnt/usb:"
  ls /mnt/usb || true
  exit 1
fi

echo "✔ Found ZIP at: $ZIP_FILE"

# ==================================================
# 2. Extract application
# ==================================================
echo "▶ Extracting Laravel application"

mkdir -p "$APP_BASE"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR"

unzip -oq "$ZIP_FILE" -d "$APP_DIR"

# Fix nested ZIP structure (nioxplay/nioxplay/*)
if [ -d "$APP_DIR/nioxplay" ] && [ ! -f "$APP_DIR/artisan" ]; then
  echo "ℹ Fixing nested ZIP structure"
  mv "$APP_DIR/nioxplay/"* "$APP_DIR/"
  rmdir "$APP_DIR/nioxplay"
fi

cd "$APP_DIR"

if [ ! -f artisan ]; then
  echo "❌ Invalid Laravel package: artisan not found"
  exit 1
fi

# ==================================================
# 3. ENV setup
# ==================================================
echo "▶ Configuring environment"

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

# ==================================================
# 4. App key
# ==================================================
php artisan key:generate --force

# ==================================================
# 5. Permissions
# ==================================================
echo "▶ Fixing permissions"

chown -R www-data:www-data "$APP_BASE"
chmod -R 775 storage bootstrap/cache

# ==================================================
# 6. Database
# ==================================================
echo "▶ Preparing database"

MYSQL="mysql -u root"

$MYSQL -e "CREATE DATABASE IF NOT EXISTS $DB_NAME;"

if ! php artisan migrate:status >/dev/null 2>&1; then
  echo "❌ Database connection failed"
  exit 1
fi

# ==================================================
# 7. Migrate / Seed / SQL
# ==================================================
if [ -f database/init.sql ]; then
  echo "▶ Importing database/init.sql"
  $MYSQL "$DB_NAME" < database/init.sql
else
  echo "▶ Running migrations"
  php artisan migrate --force
  php artisan db:seed --force 2>/dev/null || true
fi

# ==================================================
# 8. Optimize Laravel
# ==================================================
php artisan config:clear
php artisan config:cache
php artisan route:cache || true
php artisan view:clear

# ==================================================
# 9. PM2 Queue Worker
# ==================================================
echo "▶ Starting PM2 worker"

pm2 delete nioxplay-worker 2>/dev/null || true

pm2 start "php artisan queue:work --sleep=3 --tries=3" \
  --name nioxplay-worker

pm2 save

echo "✔ NioxPlay app setup completed successfully (USB)"
