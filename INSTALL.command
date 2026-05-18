#!/usr/bin/env bash
# Double-clickable installer wrapper.
# Cd's into the install directory, runs install.sh, and waits for a keypress
# before closing so the user can read any output.

cd "$(dirname "$0")"

if [[ ! -f ./install.sh ]]; then
  echo "ERROR: install.sh not found next to INSTALL.command"
  read -r -p "Press Enter to close..." _
  exit 1
fi

chmod +x ./install.sh
./install.sh

echo
read -r -p "Press Enter to close this window..." _
