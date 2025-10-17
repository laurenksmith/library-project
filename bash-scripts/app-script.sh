#!/bin/bash

# Tested on: AWS, Ubuntu 22.04 LTS
# Works on: 
# Tested by:  Lauren Copas 
# Date Tested on: 

echo Update...
sudo apt-get update
echo Done!
echo

# upgrade 
echo Upgrade...
sudo DEBIAN_FRONTEND=noninteractive apt upgrade -y
echo Done!
echo

# install nginx
echo Install nginx...
sudo DEBIAN_FRONTEND=noninteractive apt install nginx -y
echo Done!
echo

# configure nginx
echo Restart nginx...
sudo systemctl restart nginx
echo Done!
echo

# Ensure curl is present for NodeSource (harmless if already installed)
echo Ensure curl is installed...
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl
echo Done!
echo

# Download script
echo Download script to update things to install node js v20...
curl -sL https://deb.nodesource.com/setup_20.x -o nodesource_setup.sh
echo Done!
echo

# Update things prior to installing node js v20
echo Run script to update things to install node js v20...
sudo DEBIAN_FRONTEND=noninteractive bash nodesource_setup.sh
echo Done!
echo

# Install node js v20
echo Install node js v20...
sudo DEBIAN_FRONTEND=noninteractive apt install -y nodejs
echo Done!
echo

# Use the CURRENT folder (User Data runs as root; working dir is "/")
WORKDIR="$(pwd)"
echo "Working directory is: $WORKDIR"
echo

# get app code using a git clone
echo Get app code from GitHub...
git clone https://github.com/laurenksmith/library-java17-mysql-app.git "$WORKDIR/libraryproject2" || true
echo Done! 
echo

# cd into app folder
echo Moving into app directory...
cd "$WORKDIR/library-java17-mysql-app/LibraryProject2"
echo Done!
echo

# Connect database to app - MAKE SURE TO UPDATE THE DATABASE IP ADDRESS
echo Connecting to the database...
export DB_HOST="mongodb://3.254.231.201:27017/posts"
echo Done!
echo

# run npm install
echo Installing dependencies...
npm install
echo Done!
echo

# install pm2
echo Installing PM2...
sudo npm install -g pm2
echo Done!
echo

# Stop if app still running
echo Stopping any existing pm2 process...
pm2 stop app || true
echo Done!
echo

# run app in the background with pm2
echo Starting up the app...
pm2 start app.js --name app --update-env
echo Done!
echo

# Reverse Proxy
# back up first (overwrites backup each time)
sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak
echo Removing need to port to port 3000....
# Replace only the try_files line INSIDE the location block with proxy_pass
sudo sed -i 's|^\s*try_files\s\+\$uri\s\+\$uri/\s\+=404;|proxy_pass http://localhost:3000;|' /etc/nginx/sites-available/default
echo Done!
echo

# configure nginx
echo Restart nginx...
sudo systemctl restart nginx
echo Done!
echo