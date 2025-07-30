#!/usr/bin/env sh
set -eu

path="/var/www/vhosts/"
website="sitename.com"
user="root"
group="www-data"

echo "INFO: set-permission script for $website started."
echo "INFO: analyzing folder structure for $path$website."

total_items=$(find "$path$website" | wc -l)
total_files=$(find "$path$website" -type f | wc -l)
total_folders=$(find "$path$website" -type d | wc -l)

echo "INFO: total number of items =    $total_items"
echo "INFO: total number of files =    $total_files"
echo "INFO: total number of folders =  $total_folders"

# Chown on all items
echo "INFO: running chown $user:$group on $total_items items"
chown -R $user:$group "$path$website"

# Chmod and set g+s on all items
echo "INFO: running chmod 664 on $total_files files"
find "$path$website" -type f -exec chmod 664 {} +

echo "INFO: running chmod 2775 on $total_folders dirs"
find "$path$website" -type d -exec chmod 2775 {} +

echo "INFO: setting execute bit on set-permission.sh"
chmod +x "$0"
chmod +x "$path$website/config/scripts/log_rotate.sh"

echo "INFO: set-permission script for $website completed."
