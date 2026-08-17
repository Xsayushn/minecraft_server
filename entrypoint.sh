#!/bin/bash
set -e

echo "============================================="
echo "  Starting 24/7 Minecraft Server on Render   "
echo "============================================="

# 1. Setup Rclone for Google Drive if credentials provided
if [ -n "$RCLONE_CONFIG_BASE64" ]; then
    echo "[Rclone] Configuring Google Drive connection from base64..."
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONFIG_BASE64" | base64 -d > ~/.config/rclone/rclone.conf
    echo "[Rclone] Configuration loaded."
elif [ -n "$RCLONE_CONFIG_DATA" ]; then
    echo "[Rclone] Configuring Google Drive connection from raw config..."
    mkdir -p ~/.config/rclone
    echo "$RCLONE_CONFIG_DATA" > ~/.config/rclone/rclone.conf
    echo "[Rclone] Configuration loaded."
fi

# 2. Download world/files from Google Drive if configured
if [ -f ~/.config/rclone/rclone.conf ] && [ -n "$GDRIVE_REMOTE_NAME" ]; then
    echo "[Google Drive] Downloading existing world & player data from $GDRIVE_REMOTE_NAME:minecraft-server/..."
    rclone copy "$GDRIVE_REMOTE_NAME:minecraft-server/" /server/ --exclude "*.jar" --exclude "logs/**" || true
    echo "[Google Drive] Sync completed."
else
    echo "[Google Drive] No Rclone config found or GDRIVE_REMOTE_NAME not set. Using local ephemeral storage."
fi

# 3. Accept Minecraft EULA
echo "eula=true" > /server/eula.txt

# 4. Start HTTP Keepalive Server (for Render health-checks & UptimeRobot)
node /server/keepalive.js &
KEEPALIVE_PID=$!

# 5. Start Playit.gg Tunnel (for TCP port forwarding)
if [ -n "$PLAYIT_SECRET_KEY" ]; then
    echo "[Playit] Starting playit tunnel with provided secret key..."
    playit --secret "$PLAYIT_SECRET_KEY" run &
    PLAYIT_PID=$!
else
    echo "[Playit] Starting playit in claim mode..."
    playit run &
    PLAYIT_PID=$!
fi

# 6. Background auto-backup function
auto_backup() {
    while true; do
        sleep 900 # Every 15 minutes
        if [ -f ~/.config/rclone/rclone.conf ] && [ -n "$GDRIVE_REMOTE_NAME" ]; then
            echo "[Auto-Backup] Backing up world to Google Drive ($GDRIVE_REMOTE_NAME:minecraft-server/)..."
            rclone copy /server/world "$GDRIVE_REMOTE_NAME:minecraft-server/world" --copy-links || true
            rclone copy /server/world_nether "$GDRIVE_REMOTE_NAME:minecraft-server/world_nether" --copy-links || true
            rclone copy /server/world_the_end "$GDRIVE_REMOTE_NAME:minecraft-server/world_the_end" --copy-links || true
            rclone copy /server/plugins "$GDRIVE_REMOTE_NAME:minecraft-server/plugins" --exclude "*.jar" || true
            echo "[Auto-Backup] Backup finished at $(date)"
        fi
    done
}
auto_backup &
BACKUP_PID=$!

# 7. Graceful shutdown handler
shutdown_handler() {
    echo "[Shutdown] Gracefully saving world and backing up to Google Drive..."
    if [ -n "$MC_PID" ]; then
        kill -TERM "$MC_PID" 2>/dev/null || true
        wait "$MC_PID" 2>/dev/null || true
    fi
    
    if [ -f ~/.config/rclone/rclone.conf ] && [ -n "$GDRIVE_REMOTE_NAME" ]; then
        echo "[Shutdown] Syncing final changes to Google Drive..."
        rclone copy /server/world "$GDRIVE_REMOTE_NAME:minecraft-server/world" || true
        rclone copy /server/world_nether "$GDRIVE_REMOTE_NAME:minecraft-server/world_nether" || true
        rclone copy /server/world_the_end "$GDRIVE_REMOTE_NAME:minecraft-server/world_the_end" || true
    fi
    
    kill "$KEEPALIVE_PID" "$PLAYIT_PID" "$BACKUP_PID" 2>/dev/null || true
    echo "[Shutdown] Done. Exiting."
    exit 0
}

trap shutdown_handler SIGTERM SIGINT

# 8. Start PaperMC Server
MEMORY_ALLOCATION="${RAM_MB:-400M}"
echo "[Server] Launching PaperMC with ${MEMORY_ALLOCATION} RAM..."

java -Xms${MEMORY_ALLOCATION} -Xmx${MEMORY_ALLOCATION} \
  -XX:+UseG1GC \
  -XX:+ParallelRefProcEnabled \
  -XX:MaxGCPauseMillis=200 \
  -XX:+UnlockExperimentalVMOptions \
  -XX:+DisableExplicitGC \
  -XX:+AlwaysPreTouch \
  -XX:G1NewSizePercent=30 \
  -XX:G1MaxNewSizePercent=40 \
  -XX:G1ReservePercent=20 \
  -XX:G1HeapWastePercent=5 \
  -XX:G1MixedGCCountTarget=4 \
  -XX:InitiatingHeapOccupancyPercent=15 \
  -XX:G1MixedGCLiveThresholdPercent=90 \
  -XX:G1RSetUpdatingPauseTimePercent=5 \
  -XX:SurvivorRatio=32 \
  -XX:+PerfDisableSharedMem \
  -XX:MaxTenuringThreshold=1 \
  -Dusing.aikars.flags=https://mcflags.emc.gs \
  -Daikars.new.flags=true \
  -jar /server/server.jar nogui &

MC_PID=$!
wait $MC_PID
