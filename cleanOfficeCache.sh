#!/bin/bash

# Define variables
SCRIPT_DIR="$HOME/.local/scripts"
SCRIPT_PATH="$SCRIPT_DIR/cleanOfficeCache.sh"
CRON_JOB="*/15 * * * * $SCRIPT_PATH"
CACHE_EXPIRATION="-60 minutes"  # Define cache expiration time
TELEGRAM_BOT_TOKEN="YOUR_TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="YOUR_TELEGRAM_CHAT_ID"

# Function to send a message using Telegram API
sendTelegramMessage() {
  MESSAGE="$1"
  curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$TELEGRAM_CHAT_ID" -d "text=$MESSAGE" > /dev/null
}

# Step 1: Create ~/.local/scripts directory if it doesn't exist
mkdir -p "$SCRIPT_DIR"

# Step 2: Create cleanOfficeCache.sh file in ~/.local/scripts
cat > "$SCRIPT_PATH" <<EOF
#!/bin/bash

SCRIPT_DIR="\$HOME/.local/scripts"
CACHE_FILE="\$SCRIPT_DIR/cacheCleaned.tmp"

cleanCacheFiles() {
  EXTENSIONS='docx xlsx pdf'
  for FILE_TYPE in \$EXTENSIONS; do
    # Clean cache files from Microsoft Office application containers in two possible locations
    find \$HOME/Library/Containers/com.microsoft.* /System/Volumes/Data/private/var/folders/yd -name "*.\${FILE_TYPE}" -exec ls -la {} \; >> \$SCRIPT_DIR/cacheCleaned.log
    find \$HOME/Library/Containers/com.microsoft.* /System/Volumes/Data/private/var/folders/yd -name "*.\${FILE_TYPE}" -exec rm -f {} \;
  done
  touch "\$CACHE_FILE"
}

# Check if the cache file does not exist or was modified more than specified time ago
if [ ! -e "\$CACHE_FILE" ] || [ "\$(find "\$SCRIPT_DIR" ! -newermt '$CACHE_EXPIRATION' -type f -name "cacheCleaned.tmp" 2>/dev/null)" ]; then
  cleanCacheFiles
  # Send Telegram message
  HOSTNAME=\$(hostname)
  USERNAME=\$(whoami)
  DATE_TIME=\$(date +"%Y-%m-%d %H:%M:%S")
  MESSAGE="Cache cleaning script ran on \$HOSTNAME by \$USERNAME at \$DATE_TIME.\n\nContents of cacheCleaned.log:\n\$(cat \$SCRIPT_DIR/cacheCleaned.log)"
  sendTelegramMessage "\$MESSAGE"
fi
EOF

chmod u+x $SCRIPT_PATH

# Step 3: Add a crontab job for the current user
# Remove existing cron record if it present
crontab -l | grep -v cleanOfficeCache.sh | crontab -
(crontab -l; echo "$CRON_JOB") | crontab -

echo "Deployment completed successfully."
