#!/bin/sh
# HELP: Shake the jar to pick your next game -- scans SD1, SD2 and PortMaster
# ICON: jarmu
# GRID: JarMu

. /opt/muos/script/var/func.sh

APP_NAME="JarMu"

# ---------------------------------------------------------------------------
# App directory. Andromeda bind-mounts "application" from SD1/SD2, so prefer
# $MUOS_SHARE_DIR; fall back to the store, then the legacy rom-mount path.
# JarMu keeps its LÖVE source in game/ (bundled runtime in bin/).
# ---------------------------------------------------------------------------
APP_SUBPATH="application/$APP_NAME"
APP_DIR="$MUOS_SHARE_DIR/$APP_SUBPATH"
[ -d "$APP_DIR" ] || APP_DIR="$MUOS_STORE_DIR/$APP_SUBPATH"
[ -d "$APP_DIR" ] || APP_DIR="$(GET_VAR "device" "storage/rom/mount")/MUOS/$APP_SUBPATH"

BIN_DIR="$APP_DIR/bin"
GAME_DIR="$APP_DIR/game"
LOVE_BIN="$BIN_DIR/love"
LOG_FILE="$APP_DIR/jarmu.log"

# Persistent, always-writable store for state / cache / overrides. Written
# from Lua with plain io (see modules/store.lua).
DATA_DIR="$APP_DIR/save"
mkdir -p "$DATA_DIR"
export JARMU_DATA="$DATA_DIR"

# ROM storage on both cards, resolved from muOS (all-variant safe). The
# scanner scans <mount>/ROMS/<system>/ and <mount>/ports/ on each.
SD1="$(GET_VAR "device" "storage/rom/mount" 2>/dev/null)"
SD2="$(GET_VAR "device" "storage/sdcard/mount" 2>/dev/null)"
[ -n "$SD1" ] && export JARMU_ROM_SD1="$SD1"
# Only advertise SD2 if it is actually mounted with content on it.
if [ -n "$SD2" ] && { [ -d "$SD2/ROMS" ] || [ -d "$SD2/roms" ] || [ -d "$SD2/ports" ]; }; then
    export JARMU_ROM_SD2="$SD2"
fi

# muOS bind-mounts info/catalogue (box art / previews) here from whichever card
# holds it -- SD2 takes priority, else SD1. One path, card-agnostic.
[ -d "$MUOS_STORE_DIR/info/catalogue" ] && export JARMU_CATALOGUE="$MUOS_STORE_DIR/info/catalogue"

# Render target: internal 640x480 or 1280x720 on HDMI. LÖVE letterboxes it.
SCREEN_W="$(GET_VAR device mux/width)"
SCREEN_H="$(GET_VAR device mux/height)"
SCREEN_RES="${SCREEN_W:-640}x${SCREEN_H:-480}"

CAFFEINE="$(command -v CAFFEINE 2>/dev/null || true)"
trap '[ -n "$CAFFEINE" ] && "$CAFFEINE" off' EXIT INT TERM HUP

export HOME="$APP_DIR"
export XDG_DATA_HOME="$APP_DIR/.local/share"
export XDG_CONFIG_HOME="$APP_DIR/.local/config"
export SDL_HQ_SCALER=1
export SDL_GAMECONTROLLERCONFIG_FILE="/usr/lib/gamecontrollerdb.txt"
export LD_LIBRARY_PATH="$BIN_DIR/libs.aarch64${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"

command -v STOP_MUSIC >/dev/null 2>&1 && STOP_MUSIC
killall -q playbgm.sh mpg123 2>/dev/null || true

echo app >/tmp/act_go

chmod +x "$LOVE_BIN" 2>/dev/null || true
cd "$APP_DIR" || exit 1

[ -n "$CAFFEINE" ] && "$CAFFEINE" on
SET_VAR "system" "foreground_process" "love"
"$LOVE_BIN" "$GAME_DIR" "$SCREEN_RES" >"$LOG_FILE" 2>&1
