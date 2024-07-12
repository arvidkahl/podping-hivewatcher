#!/bin/bash

# Activate the virtual environment
source venv/bin/activate

# Run the Python script and pipe the output to the PHP script
python3 -u ./hive-watcher.py --json --unix_epoch=$(($(date +'%s') - 30)) | php transmission.php

# Deactivate the virtual environment
deactivate
