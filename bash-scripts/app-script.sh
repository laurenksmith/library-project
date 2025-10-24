#!/bin/bash

# Purpose: To automate the running of the Spring Boot App
# Tested on: AWS, Ubuntu 22.04 LTS 
# Works on: multiple VMs, multiple times
# Tested by:  Lauren Copas 
# Date Tested on: 23/10/2025

GITHUB_TOKEN="ghpxxxxxx"
REPO_OWNER="laurenksmith"
REPO_NAME="library-java17-mysql-app"
BRANCH=""
DB_HOST="PASTE DP PRIVATE IP ADDRESS HERE"

set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y install openjdk-17-jdk maven git ca-certificates mysql-client-core-8.0 netcat

APP_DB="library"
APP_USER="appuser"
APP_PASS="StrongPass123!"
APP_PORT=5000

for i in $(seq 1 60); do
  nc -z "${DB_HOST}" 3306 && echo "[APP] DB TCP reachable." && break || true
  sleep 2
  [ "$i" -eq 60 ] && { echo "[APP] DB not reachable"; exit 20; }
done

for i in $(seq 1 40); do
  mysqladmin ping -h "${DB_HOST}" -u"${APP_USER}" -p"${APP_PASS}" --silent && echo "[APP] DB auth OK." && break || true
  sleep 2
  [ "$i" -eq 40 ] && { echo "[APP] DB auth failed"; exit 21; }
done

APP_SRC="/opt/library-src"
APP_DIR="/opt/library-app"
mkdir -p "$APP_SRC" "$APP_DIR"
cd "$APP_SRC"
rm -rf repo || true

for i in $(seq 1 10); do
  if git clone --depth 1 "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${REPO_OWNER}/${REPO_NAME}.git" repo; then
    break
  fi
  echo "[APP] git clone attempt $i failed; retrying..."
  sleep 5
  [ "$i" -eq 10 ] && exit 30
done
GITHUB_TOKEN=""

cd repo
if [ -n "$BRANCH" ]; then git checkout -q "$BRANCH" || true; else
  DEF="$(git remote show origin | sed -n 's/.*HEAD branch: //p')"
  [ -n "$DEF" ] && git checkout -q "$DEF" || true
fi

POM_DIR="$(dirname "$(find . -maxdepth 3 -type f -name 'pom.xml' | head -n1)")"
[ -n "$POM_DIR" ] || { echo "[APP] No pom.xml found"; exit 31; }
echo "[APP] Using Maven project at: $POM_DIR"
cd "$POM_DIR"

mvn -q -DskipTests package

JAR_PATH="$(ls -1 target/*.jar | head -n1)"
[ -f "$JAR_PATH" ] || { echo "[APP] No JAR produced"; exit 32; }
cp "$JAR_PATH" "$APP_DIR/library.jar"

cat >/etc/systemd/system/library.service <<EOF
[Unit]
Description=Library App
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
Environment=DB_HOST=${DB_HOST}
Environment=DB_NAME=${APP_DB}
Environment=DB_USER=${APP_USER}
Environment=DB_PASS=${APP_PASS}
ExecStart=/usr/bin/java -jar ${APP_DIR}/library.jar \
  --server.port=${APP_PORT} \
  --spring.datasource.url=jdbc:mysql://\${DB_HOST}:3306/\${DB_NAME} \
  --spring.datasource.username=\${DB_USER} \
  --spring.datasource.password=\${DB_PASS}
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now library

sleep 3
ss -ltnp | grep ":${APP_PORT}" || true
curl -sSf "http://localhost:${APP_PORT}/web/authors" | head -c 200 || true
