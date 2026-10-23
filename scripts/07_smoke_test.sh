#!/bin/bash

ROLE=$1

if [ "$ROLE" != "web" ] && [ "$ROLE" != "app" ] && [ "$ROLE" != "db" ] && [ "$ROLE" != "ops" ]; then
  echo "Usage: bash 07_smoke_test.sh web|app|db|ops"
  exit 1
fi

WEB=192.168.56.10
APP=192.168.56.11
DB=192.168.56.12
OPS=192.168.56.13

PASSED=0
FAILED=0

check() {
  NAME=$1
  shift
  if "$@" > /dev/null 2>&1; then
    echo "  PASS  $NAME"
    PASSED=$((PASSED + 1))
  else
    echo "  FAIL  $NAME"
    FAILED=$((FAILED + 1))
  fi
}

echo "== Smoke test on $(hostname), role $ROLE =="

echo "-- local binaries --"
check "yq is in PATH" command -v yq
check "git from ppa is installed" command -v git
check "git-core repository is added" grep -rq git-core /etc/apt/sources.list.d
check "ufw is installed" command -v ufw

echo "-- network --"
check "ping web" ping -c 1 -W 2 $WEB
check "ping app" ping -c 1 -W 2 $APP
check "ping db" ping -c 1 -W 2 $DB
check "DNS works" getent hosts github.com

echo "-- firewall --"
check "firewall is active" bash -c "sudo ufw status | grep -q 'Status: active'"

echo "-- services --"
if [ "$ROLE" = "app" ]; then
  check "service nc-ttp is active" systemctl is-active --quiet nc-ttp
  check "port 8080 answers" curl -fs http://127.0.0.1:8080
  check "db port 5432 is open from app" nc -z -w 2 $DB 5432
fi

if [ "$ROLE" = "web" ]; then
  check "nginx is active" systemctl is-active --quiet nginx
  check "port 80 answers" curl -fs http://127.0.0.1
  check "app port 8080 is open from web" nc -z -w 2 $APP 8080
fi

if [ "$ROLE" = "db" ]; then
  check "postgresql is active" systemctl is-active --quiet postgresql
  check "port 5432 is listening" grep -q 5432 <(ss -ltn)
fi

if [ "$ROLE" = "ops" ]; then
  check "node exporter is active" systemctl is-active --quiet prometheus-node-exporter
  check "port 9100 answers" curl -fs http://127.0.0.1:9100/metrics
fi

echo
echo "== Result: $PASSED passed, $FAILED failed =="

if [ $FAILED -gt 0 ]; then
  exit 1
fi

exit 0
