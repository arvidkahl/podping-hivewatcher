#!/bin/bash
set -eEo pipefail  # Exit on error, propagate ERR traps, and ensure pipeline errors are propagated

# Function to log messages
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Function to log errors
log_error() {
    log_message "ERROR: $1" >&2
}

# Trap to catch and log any unexpected errors
trap 'log_error "Unexpected error occurred. Exit code: $? (Line: $LINENO, Command: $BASH_COMMAND)"' ERR

# Activate the virtual environment
if ! source venv/bin/activate; then
    log_error "Failed to activate virtual environment"
    exit 1
fi

# Trap to ensure deactivation of virtual environment
trap 'deactivate; log_message "Script execution completed."' EXIT

while true; do
    log_message "Starting hive-watcher.py and transmission.php"
    
    # Use a named pipe to capture output and error streams
    pipe=$(mktemp -u)
    mkfifo "$pipe"
    
    # Run the pipeline with timeout and capture its exit status
    (
        timeout 300 python3 -u ./hive-watcher.py --json --unix_epoch=$(($(date +'%s') - 30)) 2>&1 | \
        tee "$pipe" | \
        php transmission.php
    ) &
    
    # Read from the pipe in the background
    cat "$pipe" > /dev/null &
    
    # Wait for the pipeline to finish and capture its exit status
    wait $! && pipeline_status=$? || pipeline_status=$?
    
    # Clean up the named pipe
    rm "$pipe"
    
    if [ $pipeline_status -ne 0 ]; then
        log_error "Pipeline failed with exit code $pipeline_status"
        sleep 5  # Wait for 5 seconds before restarting
        continue
    fi
    
    # If we reach here, it means the scripts completed successfully
    log_message "Scripts completed successfully"
    sleep 1  # Small delay before next iteration
done
