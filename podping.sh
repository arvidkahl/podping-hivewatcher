#!/bin/bash

set -e  # Exit immediately if a command exits with a non-zero status
set -o pipefail  # Ensure that pipeline errors are propagated

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to log errors
log_error() {
    log_message "ERROR: $1" >&2
}

# Trap to catch and log any unexpected errors
trap 'log_error "Unexpected error occurred. Exit code: $?"' ERR

# Activate the virtual environment
if ! source venv/bin/activate; then
    log_error "Failed to activate virtual environment"
    exit 1
fi

# Trap to ensure deactivation of virtual environment
trap 'deactivate; log_message "Script execution completed."' EXIT

while true; do
    log_message "Starting hive-watcher.py and transmission.php"

    if ! python3 -u ./hive-watcher.py --json --unix_epoch=$(($(date +'%s') - 30)) | php transmission.php; then
        log_error "Python script or PHP script failed"
        sleep 5  # Wait for 5 seconds before restarting
        continue
    fi

    # If we reach here, it means the scripts completed successfully
    log_message "Scripts completed successfully"
    sleep 1  # Small delay before next iteration
done