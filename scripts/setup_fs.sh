#!/bin/bash

ROLE=$1

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash setup_fs.sh web|app|db|ops"
  exit 1
fi

if [ "$ROLE" != "web" ] && [ "$ROLE" != "app" ] && [ "$ROLE" != "db" ] && [ "$ROLE" != "ops" ]; then
  echo "Usage: sudo bash setup_fs.sh web|app|db|ops"
  exit 1
fi

if ! id nc-ttp > /dev/null 2>&1; then
  useradd --system --no-create-home --home-dir /var/lib/nc-ttp --shell /usr/sbin/nologin nc-ttp
  echo "  user  nc-ttp created"
fi

echo "== Common directories =="

mkdir -p /opt/nc-ttp/scripts
chown root:root /opt/nc-ttp /opt/nc-ttp/scripts
chmod 755 /opt/nc-ttp /opt/nc-ttp/scripts

mkdir -p /etc/nc-ttp
chown root:nc-ttp /etc/nc-ttp
chmod 750 /etc/nc-ttp

mkdir -p /var/lib/nc-ttp /var/log/nc-ttp
chown nc-ttp:nc-ttp /var/lib/nc-ttp /var/log/nc-ttp
chmod 750 /var/lib/nc-ttp /var/log/nc-ttp

mkdir -p /var/backups/nc-ttp
chown root:root /var/backups/nc-ttp
chmod 700 /var/backups/nc-ttp

if [ ! -f /etc/nc-ttp/node.env ]; then
cat > /etc/nc-ttp/node.env <<EOF
PROJECT=nc-ttp
NODE_ROLE=$ROLE
ENVIRONMENT=dev
WEB_HOST=192.168.56.10
APP_HOST=192.168.56.11
DB_HOST=192.168.56.12
OPS_HOST=192.168.56.13
EOF
  chown root:nc-ttp /etc/nc-ttp/node.env
  chmod 640 /etc/nc-ttp/node.env
  echo "  file  /etc/nc-ttp/node.env"
else
  echo "  skip  /etc/nc-ttp/node.env (exists)"
fi

if [ "$ROLE" = "web" ]; then
  echo "== Web (nginx) =="

  mkdir -p /etc/nc-ttp/nginx
  chown root:root /etc/nc-ttp/nginx
  chmod 755 /etc/nc-ttp/nginx

  mkdir -p /etc/nc-ttp/ssl
  chown root:root /etc/nc-ttp/ssl
  chmod 700 /etc/nc-ttp/ssl

  mkdir -p /srv/nc-ttp/www
  chown nc-ttp:www-data /srv/nc-ttp /srv/nc-ttp/www
  chmod 750 /srv/nc-ttp /srv/nc-ttp/www

  if [ ! -f /etc/nc-ttp/nginx/nc-ttp.conf ]; then
cat > /etc/nc-ttp/nginx/nc-ttp.conf <<'EOF'
upstream nc_ttp_app {
    server 192.168.56.11:8080;
}

server {
    listen 80;
    server_name nc-ttp.local;

    root /srv/nc-ttp/www;
    index index.html;

    access_log /var/log/nginx/nc-ttp.access.log;
    error_log  /var/log/nginx/nc-ttp.error.log;

    location /api/ {
        proxy_pass http://nc_ttp_app;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    location / {
        try_files $uri $uri/ /index.html;
    }
}
EOF
    chown root:root /etc/nc-ttp/nginx/nc-ttp.conf
    chmod 644 /etc/nc-ttp/nginx/nc-ttp.conf
    echo "  file  /etc/nc-ttp/nginx/nc-ttp.conf"
  else
    echo "  skip  /etc/nc-ttp/nginx/nc-ttp.conf (exists)"
  fi

  if [ ! -f /srv/nc-ttp/www/index.html ]; then
cat > /srv/nc-ttp/www/index.html <<'EOF'
<!doctype html>
<html>
<head><meta charset="utf-8"><title>NC-TTP</title></head>
<body>
<h1>NC-TTP: Table Tennis Platform</h1>
<p>Frontend placeholder. API is available at /api/</p>
</body>
</html>
EOF
    chown nc-ttp:www-data /srv/nc-ttp/www/index.html
    chmod 640 /srv/nc-ttp/www/index.html
    echo "  file  /srv/nc-ttp/www/index.html"
  else
    echo "  skip  /srv/nc-ttp/www/index.html (exists)"
  fi
fi

if [ "$ROLE" = "app" ]; then
  echo "== App (Spring Boot) =="

  mkdir -p /opt/nc-ttp/app /opt/nc-ttp/releases
  chown root:root /opt/nc-ttp/app /opt/nc-ttp/releases
  chmod 755 /opt/nc-ttp/app /opt/nc-ttp/releases

  mkdir -p /var/lib/nc-ttp/uploads/avatars /var/lib/nc-ttp/tmp
  chown nc-ttp:nc-ttp /var/lib/nc-ttp/uploads /var/lib/nc-ttp/uploads/avatars /var/lib/nc-ttp/tmp
  chmod 750 /var/lib/nc-ttp/uploads /var/lib/nc-ttp/uploads/avatars /var/lib/nc-ttp/tmp

  if [ ! -f /etc/nc-ttp/application.yml ]; then
cat > /etc/nc-ttp/application.yml <<'EOF'
server:
  port: 8080

spring:
  datasource:
    url: jdbc:postgresql://192.168.56.12:5432/nc_ttp
    username: nc_ttp
    password: ${DB_PASSWORD}

app:
  uploads-dir: /var/lib/nc-ttp/uploads
  elo:
    start-rating: 1000
    k-factor: 32

logging:
  file:
    name: /var/log/nc-ttp/app.log
EOF
    chown root:nc-ttp /etc/nc-ttp/application.yml
    chmod 640 /etc/nc-ttp/application.yml
    echo "  file  /etc/nc-ttp/application.yml"
  else
    echo "  skip  /etc/nc-ttp/application.yml (exists)"
  fi

  if [ ! -f /etc/nc-ttp/secrets.env ]; then
cat > /etc/nc-ttp/secrets.env <<'EOF'
DB_PASSWORD=change_me
EOF
    chown root:nc-ttp /etc/nc-ttp/secrets.env
    chmod 640 /etc/nc-ttp/secrets.env
    echo "  file  /etc/nc-ttp/secrets.env"
  else
    echo "  skip  /etc/nc-ttp/secrets.env (exists)"
  fi

  if [ ! -f /opt/nc-ttp/app/nc-ttp.service ]; then
cat > /opt/nc-ttp/app/nc-ttp.service <<'EOF'
[Unit]
Description=NC-TTP backend
After=network.target

[Service]
User=nc-ttp
Group=nc-ttp
EnvironmentFile=/etc/nc-ttp/secrets.env
WorkingDirectory=/opt/nc-ttp/app
ExecStart=/usr/bin/java -jar /opt/nc-ttp/app/nc-ttp.jar --spring.config.additional-location=/etc/nc-ttp/application.yml
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    chown root:root /opt/nc-ttp/app/nc-ttp.service
    chmod 644 /opt/nc-ttp/app/nc-ttp.service
    echo "  file  /opt/nc-ttp/app/nc-ttp.service"
  else
    echo "  skip  /opt/nc-ttp/app/nc-ttp.service (exists)"
  fi

  if [ ! -f /opt/nc-ttp/app/README.txt ]; then
cat > /opt/nc-ttp/app/README.txt <<'EOF'
Place nc-ttp.jar here. Old versions are kept in /opt/nc-ttp/releases for rollback.
EOF
    chown root:root /opt/nc-ttp/app/README.txt
    chmod 644 /opt/nc-ttp/app/README.txt
    echo "  file  /opt/nc-ttp/app/README.txt"
  else
    echo "  skip  /opt/nc-ttp/app/README.txt (exists)"
  fi
fi

if [ "$ROLE" = "db" ]; then
  echo "== DB (PostgreSQL) =="

  mkdir -p /etc/nc-ttp/db
  chown root:root /etc/nc-ttp/db
  chmod 755 /etc/nc-ttp/db

  mkdir -p /var/backups/nc-ttp/db
  chown root:root /var/backups/nc-ttp/db
  chmod 700 /var/backups/nc-ttp/db

  if [ ! -f /etc/nc-ttp/db/init.sql ]; then
cat > /etc/nc-ttp/db/init.sql <<'EOF'
CREATE TABLE IF NOT EXISTS players (
    id          SERIAL PRIMARY KEY,
    full_name   VARCHAR(100) NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    rating      INT NOT NULL DEFAULT 1000,
    created_at  TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS matches (
    id          SERIAL PRIMARY KEY,
    player1_id  INT NOT NULL REFERENCES players(id),
    player2_id  INT NOT NULL REFERENCES players(id),
    score1      INT NOT NULL,
    score2      INT NOT NULL,
    played_at   TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS table_bookings (
    id          SERIAL PRIMARY KEY,
    player_id   INT NOT NULL REFERENCES players(id),
    starts_at   TIMESTAMP NOT NULL,
    ends_at     TIMESTAMP NOT NULL
);
EOF
    chown root:root /etc/nc-ttp/db/init.sql
    chmod 644 /etc/nc-ttp/db/init.sql
    echo "  file  /etc/nc-ttp/db/init.sql"
  else
    echo "  skip  /etc/nc-ttp/db/init.sql (exists)"
  fi

  if [ ! -f /opt/nc-ttp/scripts/backup_db.sh ]; then
cat > /opt/nc-ttp/scripts/backup_db.sh <<'EOF'
#!/bin/bash
TS=$(date +%Y%m%d_%H%M%S)
sudo -u postgres pg_dump nc_ttp | gzip > /var/backups/nc-ttp/db/nc_ttp_$TS.sql.gz
find /var/backups/nc-ttp/db -name '*.sql.gz' -mtime +7 -delete
EOF
    chown root:root /opt/nc-ttp/scripts/backup_db.sh
    chmod 750 /opt/nc-ttp/scripts/backup_db.sh
    echo "  file  /opt/nc-ttp/scripts/backup_db.sh"
  else
    echo "  skip  /opt/nc-ttp/scripts/backup_db.sh (exists)"
  fi
fi

if [ "$ROLE" = "ops" ]; then
  echo "== Ops (monitoring) =="

  mkdir -p /etc/nc-ttp/prometheus /etc/nc-ttp/grafana
  chown root:root /etc/nc-ttp/prometheus /etc/nc-ttp/grafana
  chmod 755 /etc/nc-ttp/prometheus /etc/nc-ttp/grafana

  mkdir -p /var/lib/nc-ttp/prometheus /var/lib/nc-ttp/grafana
  chown nc-ttp:nc-ttp /var/lib/nc-ttp/prometheus /var/lib/nc-ttp/grafana
  chmod 750 /var/lib/nc-ttp/prometheus /var/lib/nc-ttp/grafana

  if [ ! -f /etc/nc-ttp/prometheus/prometheus.yml ]; then
cat > /etc/nc-ttp/prometheus/prometheus.yml <<'EOF'
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: node
    static_configs:
      - targets:
          - 192.168.56.10:9100
          - 192.168.56.11:9100
          - 192.168.56.12:9100
  - job_name: nc-ttp-app
    metrics_path: /actuator/prometheus
    static_configs:
      - targets: ['192.168.56.11:8080']
EOF
    chown root:root /etc/nc-ttp/prometheus/prometheus.yml
    chmod 644 /etc/nc-ttp/prometheus/prometheus.yml
    echo "  file  /etc/nc-ttp/prometheus/prometheus.yml"
  else
    echo "  skip  /etc/nc-ttp/prometheus/prometheus.yml (exists)"
  fi
fi

echo
echo "== Result on $(hostname) =="
tree -pug /etc/nc-ttp /opt/nc-ttp /var/lib/nc-ttp /var/log/nc-ttp /var/backups/nc-ttp
if [ -d /srv/nc-ttp ]; then
  tree -pug /srv/nc-ttp
fi
echo "Filesystem for role '$ROLE' is ready"
