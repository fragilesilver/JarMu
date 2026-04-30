#!/bin/sh
# JarMu - muOS launcher
# Targets: muOS 2601.1 Funky Jacaranda on RG35XX family (RG35XX+/2024/SP/H/Pro)

. /opt/muos/script/var/func.sh

echo app >/tmp/act_go

APPDIR="/mnt/mmc/MUOS/application/JarMu"
LOVEDIR="$APPDIR/love"
GAMEDIR="$APPDIR/game"

# muOS expects HOME to be writable for save files and configuration
export HOME="$APPDIR"
export XDG_DATA_HOME="$APPDIR/.local/share"
export XDG_CONFIG_HOME="$APPDIR/.config"

# Bundled LÖVE 11.4 needs its libs found at runtime
export LD_LIBRARY_PATH="$LOVEDIR/libs:$LD_LIBRARY_PATH"

# SDL setup matching muOS conventions
export SDL_HQ_SCALER=1
export SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"

# Tell muOS we're a foreground process
SET_VAR "system" "foreground_process" "love"

cd "$APPDIR" || exit 1

# Make LÖVE binary executable (in case zip stripped permissions during install)
chmod +x "$LOVEDIR/love" 2>/dev/null

# Run LÖVE pointing at the game directory; mirror logs for tester debugging
"$LOVEDIR/love" "$GAMEDIR" 2>&1 | tee "$APPDIR/jarmu.log"
