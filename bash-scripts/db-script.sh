#!/bin/bash

# Purpose: To automate the seeding of the database for the Spring Boot app
# Tested on: AWS, Ubuntu 22.04 LTS 
# Works on: multiple VMs, multiple times
# Tested by:  Lauren Copas 
# Date Tested on: 23/10/2025

GITHUB_TOKEN="ghpxxxxxxx"
REPO_OWNER="laurenksmith"
REPO_NAME="library-java17-mysql-app"
SQL_PATH="library.sql"

set -euxo pipefail
exec > >(tee -a /var/log/user-data.log) 2>&1
export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get -y install mysql-server git ca-certificates

systemctl enable --now mysql

MYSQL_CNF="/etc/mysql/mysql.conf.d/mysqld.cnf"
if grep -qE '^\s*bind-address' "$MYSQL_CNF"; then
  sed -i 's/^\s*bind-address\s*=.*/bind-address = 0.0.0.0/' "$MYSQL_CNF"
else
  echo "bind-address = 0.0.0.0" >> "$MYSQL_CNF"
fi
systemctl restart mysql

APP_DB="library"
APP_USER="appuser"
APP_PASS="StrongPass123!"

mysql -e "
  CREATE DATABASE IF NOT EXISTS \`${APP_DB}\`;
  CREATE USER IF NOT EXISTS '${APP_USER}'@'%'        IDENTIFIED BY '${APP_PASS}';
  CREATE USER IF NOT EXISTS '${APP_USER}'@'localhost' IDENTIFIED BY '${APP_PASS}';
  ALTER USER '${APP_USER}'@'%'        IDENTIFIED BY '${APP_PASS}';
  ALTER USER '${APP_USER}'@'localhost' IDENTIFIED BY '${APP_PASS}';
  GRANT ALL PRIVILEGES ON \`${APP_DB}\`.* TO '${APP_USER}'@'%' , '${APP_USER}'@'localhost';
  FLUSH PRIVILEGES;"

SEED_DIR="/opt/library-seed"
mkdir -p "$SEED_DIR"
cd "$SEED_DIR"
rm -rf repo || true

for i in $(seq 1 10); do
  if git clone --depth 1 --filter=blob:none --sparse \
    "https://${GITHUB_TOKEN}:x-oauth-basic@github.com/${REPO_OWNER}/${REPO_NAME}.git" repo; then
    break
  fi
  echo "[DB] git clone attempt $i failed; retrying..."
  sleep 5
  [ "$i" -eq 10 ] && exit 10
done
GITHUB_TOKEN=""

cd repo
git sparse-checkout init --cone
git sparse-checkout set "$SQL_PATH"
git checkout -q "$(git remote show origin | sed -n 's/.*HEAD branch: //p')" || true

mysql -h 127.0.0.1 -u"${APP_USER}" -p"${APP_PASS}" "${APP_DB}" < "${SQL_PATH}"

# Added this whilst troubleshooting to help pinpoint errors
mysql -h 127.0.0.1 -u"${APP_USER}" -p"${APP_PASS}" -e "SHOW TABLES" "${APP_DB}" || true
mysql -h 127.0.0.1 -u"${APP_USER}" -p"${APP_PASS}" -e "SELECT COUNT(*) AS authors FROM ${APP_DB}.authors;" || true