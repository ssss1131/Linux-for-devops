#!/bin/bash

ROLE=$1

if [ "$(id -u)" != "0" ]; then
  echo "Run as root: sudo bash 04_service.sh app"
  exit 1
fi

if [ "$ROLE" != "app" ]; then
  echo "Service is installed only on the app server, skipping"
  exit 0
fi

echo "== Application file =="

mkdir -p /opt/nc-ttp/app

cat > /opt/nc-ttp/app/nc_ttp_stub.py <<'EOF'
from http.server import BaseHTTPRequestHandler, HTTPServer
import json

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        body = json.dumps({"service": "nc-ttp", "status": "ok"}).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, fmt, *args):
        print(fmt % args, flush=True)

HTTPServer(("0.0.0.0", 8080), Handler).serve_forever()
EOF

chown root:nc-ttp-deploy /opt/nc-ttp/app/nc_ttp_stub.py
chmod 644 /opt/nc-ttp/app/nc_ttp_stub.py
echo "  /opt/nc-ttp/app/nc_ttp_stub.py"

echo "== Systemd unit =="

cat > /etc/systemd/system/nc-ttp.service <<'EOF'
[Unit]
Description=NC-TTP table tennis service
After=network.target

[Service]
User=nc-ttp
Group=nc-ttp
ExecStart=/usr/bin/python3 /opt/nc-ttp/app/nc_ttp_stub.py
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

chown root:root /etc/systemd/system/nc-ttp.service
chmod 644 /etc/systemd/system/nc-ttp.service
echo "  /etc/systemd/system/nc-ttp.service"

echo "== Enable and start =="

systemctl daemon-reload
systemctl enable nc-ttp
systemctl restart nc-ttp
sleep 2

echo
echo "== Result on $(hostname) =="
systemctl status nc-ttp --no-pager
echo
curl -s http://127.0.0.1:8080
echo
echo "Service nc-ttp is ready"
