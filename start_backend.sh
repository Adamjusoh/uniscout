#!/usr/bin/env bash
set -euo pipefail

DIR="/Users/adam/Desktop/Software-Development-Workshop/database"
echo "Starting UniScout MySQL Workbench PHP REST API on http://0.0.0.0:8080 ..."
echo "  -> Android Emulator URL : http://10.0.2.2:8080/api.php"
echo "  -> macOS / Chrome URL   : http://127.0.0.1:8080/api.php"
echo "  -> Tip: Enter your MySQL root password directly inside the app's DB Settings dialog."
exec /opt/homebrew/bin/php -S 0.0.0.0:8080 -t "$DIR"

