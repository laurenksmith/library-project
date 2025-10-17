#!/bin/bash

# Purpose: 
# Tested on: AWS, Ubuntu 22.04 LTS
# Works on:  
# Tested by:  Lauren Copas 
# Date Tested on: 

echo Update...
sudo apt update
echo Done!
echo

# upgrade 
echo Upgrade...
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
echo Done!
echo

# install gnupg and curl
echo Install gnupg and curl...
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y gnupg curl
echo Done!
echo

# Mongo gpg key
echo Getting gpg key for Mongo db....
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
  sudo gpg -o /usr/share/keyrings/mongodb-server-7.0.gpg --dearmor
echo Done!
echo

# Create list file
echo Creating list file....
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
  sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list >/dev/null
echo Done!
echo

# Apt Update
echo Updating apt...
sudo apt-get update
echo Done!
echo

# Install Mongo db v7
echo Installing Mongo db v7...
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
  mongodb-org=7.0.22 \
  mongodb-org-database=7.0.22 \
  mongodb-org-server=7.0.22 \
  mongodb-mongosh \
  mongodb-org-shell=7.0.22 \
  mongodb-org-mongos=7.0.22 \
  mongodb-org-tools=7.0.22 \
  mongodb-org-database-tools-extra=7.0.22
echo Done!
echo

# Start the database
echo Starting Mongo db...
sudo systemctl start mongod
echo Done!
echo

# Enable Mongo db
echo Enabling Mongo db...
sudo systemctl enable mongod
echo Done!
echo

# Change bindIp from 127.0.0.1 to 0.0.0.0
echo Changing the bindIP address...
sudo sed -i 's/^\([[:space:]]*bindIp:[[:space:]]*\)[0-9.]\+/\10.0.0.0/' /etc/mongod.conf
echo Done!
echo

echo Restarting MongoDB...
sudo systemctl restart mongod
sudo systemctl status mongod --no-pager -l
echo Done!
echo