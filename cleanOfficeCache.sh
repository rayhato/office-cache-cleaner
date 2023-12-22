#!/bin/bash

SCRIPT_DIR="$HOME/.local/scripts"
SCRIPT_PATH="$SCRIPT_DIR/cleanOfficeCache.sh"
CRON_JOB="*/15 * * * * $SCRIPT_PATH"

# Step 1: Create ~/.local/scripts directory if it doesn't exist
mkdir -p "$SCRIPT_DIR"

# Step 2: Create cleanOfficeCache.sh file in ~/.local/scripts
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash

cleanCacheFiles() {
  EXTENSIONS='docx xlsx pdf'
  for FILE_TYPE in \$EXTENSIONS; do
    find \$HOME/Library/Containers/com.microsoft.* -name "*.\${FILE_TYPE}" -exec ls -la {} \; >> $TMPDIR/cacheCleaned.log
    find \$HOME/Library/Containers/com.microsoft.* -name "*.\${FILE_TYPE}" -exec rm -f {} \;
  done
  touch "\$TMPDIR/cacheCleaned.tmp"
}

CACHE_FILE="\$TMPDIR/cacheCleaned.tmp"

# Check if the cache file does not exist or was modified more than 12 hours ago
if [ ! -e "\$CACHE_FILE" ] || [ "\$(find "\$TMPDIR" ! -newermt '-60 minutes' -type f -name "cacheCleaned.tmp" 2>/dev/null)" ]; then
  cleanCacheFiles
fi
EOF

# Step 3: Add a crontab job for the current user
(crontab -l; echo "$CRON_JOB") | crontab -

echo "Deployment completed successfully. The script cleanOfficeCache.sh will run every 15 minutes."