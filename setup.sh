#!/bin/sh
# spotify-setup/setup.sh — idempotent re-install of the Spotify customization.
# Safe to run repeatedly. Does not apply unless you pass --apply
# (applying restarts Spotify and interrupts playback).
#
#   ./setup.sh            # install files + config, then tell you what to run
#   ./setup.sh --apply    # install, then `spicetify apply` (restarts Spotify)
#   ./setup.sh --repair   # after a Spotify update: restore/backup + apply
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)
THEME=${THEME:-AppleMusicMac}
SCHEME=${SCHEME:-Dark}
EXTENSIONS="fullAppDisplay.js|keyboardShortcut.js|shuffle+.js|bookmark.js"
CUSTOM_APPS="marketplace|lyrics-plus"

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[32m  ok\033[0m %s\n' "$*"; }
die() { printf '\033[31m  !! %s\033[0m\n' "$*" >&2; exit 1; }

command -v spicetify >/dev/null 2>&1 || die "spicetify not on PATH"
say "spicetify: $(command -v spicetify) $(spicetify -v 2>/dev/null | tail -1)"

CFG=$(dirname "$(spicetify -c)")
BUNDLED=$(brew --prefix spicetify-cli 2>/dev/null || true)/libexec
[ -d "$BUNDLED" ] || BUNDLED="$HOME/.spicetify"
[ -d "$BUNDLED/Extensions" ] || die "cannot find bundled extensions (looked in $BUNDLED)"

# --- repair mode: after a Spotify update wipes the patch --------------------
if [ "${1:-}" = "--repair" ]; then
  say "repairing (restore backup, then re-apply)"
  spicetify restore backup apply || die "restore backup apply failed; see README > Recovery"
  ok "repaired"
  exit 0
fi

# --- 1. extensions + custom apps ------------------------------------------
mkdir -p "$CFG/Extensions" "$CFG/CustomApps"
for f in fullAppDisplay.js keyboardShortcut.js "shuffle+.js" bookmark.js; do
  [ -f "$BUNDLED/Extensions/$f" ] || die "missing $BUNDLED/Extensions/$f"
  cp "$BUNDLED/Extensions/$f" "$CFG/Extensions/$f"
done
ok "extensions copied from $BUNDLED"

# macOS reserves F11 (Show Desktop), so the key never reaches Spotify.
# Rebind fullAppDisplay to ctrl+shift+f; idempotent, reapplied on every run.
FAD="$CFG/Extensions/fullAppDisplay.js"
if grep -q 'Mousetrap.bind("f11", toggleFad)' "$FAD"; then
  TMPFAD=$(mktemp)
  awk '{gsub(/Mousetrap\.bind\("f11", toggleFad\)/,"Mousetrap.bind(\"ctrl+shift+f\", toggleFad)")}1' "$FAD" > "$TMPFAD"
  mv "$TMPFAD" "$FAD"
  ok "fullAppDisplay rebound: ctrl+shift+f (was f11, eaten by macOS)"
fi
[ -d "$CFG/CustomApps/lyrics-plus" ] || cp -R "$BUNDLED/CustomApps/lyrics-plus" "$CFG/CustomApps/"
ok "lyrics-plus present"

# --- 2. theme --------------------------------------------------------------
[ -f "$CFG/Themes/$THEME/color.ini" ] || die "theme $THEME not installed in $CFG/Themes"
ok "theme $THEME present"

# --- 3. config (explicit, so a fresh machine matches) ----------------------
spicetify config current_theme "$THEME" color_scheme "$SCHEME" >/dev/null
spicetify config inject_css 1 replace_colors 1 inject_theme_js 1 >/dev/null
spicetify config extensions "$EXTENSIONS" >/dev/null
spicetify config custom_apps "$CUSTOM_APPS" >/dev/null
spicetify config experimental_features 0 home_config 0 >/dev/null
spicetify config always_enable_devtools 0 check_spicetify_update 1 >/dev/null
spicetify config disable_sentry 1 disable_ui_logging 1 expose_apis 1 remove_rtl_rule 1 >/dev/null
ok "config set"

# --- 4. personal CSS overrides (idempotent) --------------------------------
CSS="$CFG/Themes/$THEME/user.css"
[ -f "$CSS" ] || die "no user.css in $CFG/Themes/$THEME"
[ -f "$CSS.orig" ] || cp "$CSS" "$CSS.orig"
TMP=$(mktemp)
awk '/^\/\* == user-overrides:start == \*\/$/{skip=1}
     !skip{print}
     /^\/\* == user-overrides:end == \*\/$/{skip=0}' "$CSS" > "$TMP"
printf '\n' >> "$TMP"
cat "$ROOT/overrides.css" >> "$TMP"
mv "$TMP" "$CSS"
ok "overrides.css appended between markers (original kept as user.css.orig)"

# --- 5. apply --------------------------------------------------------------
case "${1:-}" in
  --apply) say "applying (Spotify will restart)"; spicetify apply ;;
  *)       say "not applying. run: spicetify apply   (or: ./setup.sh --apply)" ;;
esac
