#!/usr/bin/env bash
set -e

apt install -y supervisor

grep '- domain:' /opt/nioxon/config/server.yaml | while read -r line; do
  DOMAIN=$(echo "$line" | awk '{print $3}')
  ROOT=$(grep -A3 "$DOMAIN" /opt/nioxon/config/server.yaml | grep root | awk '{print $2}')
  QUEUE=$(grep -A3 "$DOMAIN" /opt/nioxon/config/server.yaml | grep queue | awk '{print $2}')

  if [ "$QUEUE" = "true" ]; then
    CONF="/etc/supervisor/conf.d/$DOMAIN-queue.conf"

    if [ ! -f "$CONF" ]; then
      echo "⚙️ Configuring queue for $DOMAIN"

      cat > "$CONF" <<EOF
[program:$DOMAIN-queue]
process_name=%(program_name)s_%(process_num)02d
command=php $ROOT/../artisan queue:work --sleep=3 --tries=3
autostart=true
autorestart=true
user=www-data
numprocs=1
redirect_stderr=true
stdout_logfile=/var/log/$DOMAIN-queue.log
EOF
    fi
  fi
done

supervisorctl reread
supervisorctl update
