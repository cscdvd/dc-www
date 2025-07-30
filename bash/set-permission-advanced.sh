#!/usr/bin/env sh
set -eu

# Config
path="/var/www/vhosts"
website="sitename.com"
full_path="$path/$website"
user="root"
group="www-data"

# Check directory
if [ ! -d "$full_path" ]; then
  echo "ERROR: directory $full_path not found" >&2
  exit 1
fi

echo "INFO: set-permission script for $website started."
echo "INFO: analyzing folder structure for $full_path"

# Counter (gestisce anche nomi con newline/spazi)
total_items=$(find "$full_path" -print0 | tr -cd '\0' | wc -c)
total_files=$(find "$full_path" -type f -print0 | tr -cd '\0' | wc -c)
total_folders=$(find "$full_path" -type d -print0 | tr -cd '\0' | wc -c)

echo "INFO: total number of items =   $total_items"
echo "INFO: total number of files =   $total_files"
echo "INFO: total number of folders = $total_folders"

# Chown on all items
if [ "$total_items" -gt 0 ]; then
  echo "INFO: running chown for $total_items items"
  find "$full_path" -print0 | pv -0 -l -s "$total_items" -N "chown" | xargs -0 chown "$user":"$group"
else
  echo "INFO: no items to chown"
fi

# Chmod on all files
if [ "$total_files" -gt 0 ]; then
  echo "INFO: running chmod 664 on $total_files files"
  find "$full_path" -type f -print0 | pv -0 -l -s "$total_files" -N "chmod-files" | xargs -0 chmod 664
else
  echo "INFO: no files to chmod"
fi

# Chmod on all dirs and setgid
if [ "$total_folders" -gt 0 ]; then
  echo "INFO: running chmod 2775 on $total_folders dirs"
  find "$full_path" -type d -print0 | pv -0 -l -s "$total_folders" -N "chmod-dirs" | xargs -0 chmod 2775
else
  echo "INFO: no dirs to chmod"
fi

# Set execute bit on set-permission.sh
echo "INFO: setting execute bit on set-permission.sh"
chmod +x "$0"

echo "INFO: set-permission script for $website completed."
