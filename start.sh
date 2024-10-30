#!/bin/bash
set -euo pipefail
trap 'echo "Error on line $LINENO"' ERR

# Function to log messages
log_message() {
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

# Function to setup rclone with validation
setup_rclone() {
    log_message "Setting up rclone..."
    # First check if config already exists in workspace
    if [ ! -f "/workspace/rclone.conf" ]; then
        log_message "No existing rclone.conf found in workspace, attempting to download..."
        if [[ -n "${RCLONE_CONF_URL:-}" ]]; then
            log_message "Downloading rclone.conf from Dropbox..."   
            curl -L -f -S "${RCLONE_CONF_URL}" -o /workspace/rclone.conf || {
                log_message "Failed to download rclone.conf"        
                return 1
            }
            if [ -s /workspace/rclone.conf ]; then
                log_message "Successfully downloaded rclone.conf"   
                chmod 600 /workspace/rclone.conf
            else
                log_message "Downloaded file is empty or missing"   
                return 1
            fi
        fi
    else
        log_message "Existing rclone.conf found in workspace"       
    fi

    # Configure rclone if file exists
    if [ -f "/workspace/rclone.conf" ]; then
        log_message "Copying rclone config to ~/.config/rclone/"    
        mkdir -p ~/.config/rclone
        cp /workspace/rclone.conf "$RCLONE_CONFIG_PATH"
        chmod 600 "$RCLONE_CONFIG_PATH"
        if rclone config show &>/dev/null; then
            log_message "Rclone configuration validated successfully"
            if rclone lsd dbx: &>/dev/null; then
                log_message "Successfully connected to Dropbox"     
            else
                log_message "Warning: Could not connect to Dropbox" 
            fi
        else
            log_message "Warning: Invalid rclone configuration"     
            return 1
        fi
    else
        log_message "No rclone configuration available"
    fi
}

# Setup rclone
setup_rclone

# Print system information
log_message "=== System Information ==="
log_message "CPU: $(nproc) cores"
log_message "Memory: $(free -h | awk '/Mem:/ {print $2}')"
log_message "GPU: $(nvidia-smi --query-gpu=gpu_name --format=csv,noheader 2>/dev/null || echo 'No GPU found')"

# Setup Python virtual environment
if [ ! -d "/workspace/venv" ]; then
    log_message "Creating virtual environment..."
    python3 -m venv /workspace/venv
fi
log_message "Activating virtual environment..."
source /workspace/venv/bin/activate || {
    log_message "Failed to activate virtual environment"
    mkdir -p /workspace/venv/bin
    touch /workspace/venv/bin/activate
}

# Look for StableSwarm startup script
if [ -f "/launchx/start.sh" ]; then
    log_message "Found StableSwarm startup at /launchx/start.sh"    
    cd /launchx
    exec ./start.sh "$@"
else
    log_message "Error: Could not find StableSwarm initialization script"
    log_message "Available start scripts:"
    find / -name "start.sh" 2>/dev/null || true
    exit 1
fi
