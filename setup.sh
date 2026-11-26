#!/bin/sh
# setup.sh — install / repair an Apple-Music-style Spotify customization.
#
#   ./setup.sh              install files + config (no restart)
#   ./setup.sh --apply      install, then apply (restarts Spotify)
#   ./setup.sh --repair     after a Spotify update: restore -> backup -> apply
#
# Idempotent: safe to run repeatedly. Never uses sudo.
set -eu

ROOT=$(cd "$(dirname "$0")" && pwd)

THEME=${THEME:-AppleMusicMac}
SCHEME=${SCHEME:-Dark}
# Pinned on purpose: a theme update must be a deliberate act, and it overwrites user.css.
THEME_REPO=${THEME_REPO:-mcloudHQ/mcloud}
THEME_COMMIT=${THEME_COMMIT:-91ee20818ddbf1df276904411fc61c917d362c04}
EXTENSIONS=${EXTENSIONS:-"fullAppDisplay.js|keyboardShortcut.js|shuffle+.js"}
CUSTOM_APPS=${CUSTOM_APPS:-"marketplace|lyrics-plus"}
FAD_KEY=${FAD_KEY:-"ctrl+shift+f"}   # macOS owns f11 (Show Desktop)

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
ok()  { printf '\033[32m  ok\033[0m %s\n' "$*"; }
warn(){ printf '\033[33m  !!\033[0m %s\n' "$*"; }
die() { printf '\033[31m  !! %s\033[0m\n' "$*" >&2; exit 1; }

command -v spicetify >/dev/null 2>&1 || die "spicetify not on PATH. Install it: brew install spicetify-cli"
say "spicetify: $(command -v spicetify) $(spicetify -v 2>/dev/null | tail -1)"

CFG=$(dirname "$(spicetify -c)")
command -v brew >/dev/null 2>&1 && BUNDLED=$(brew --prefix spicetify-cli 2>/dev/null || true)/libexec
[ -d "${BUNDLED:-}/Extensions" ] || BUNDLED="$HOME/.spicetify"
[ -d "$BUNDLED/Extensions" ] || die "no bundled extensions found (looked in $BUNDLED)"

# --- repair mode -----------------------------------------------------------
if [ "${1:-}" = "--repair" ]; then
  say "repairing after a Spotify update"
  spicetify restore || die "restore failed; see README > Recovery"
  spicetify backup  || die "backup failed; see README > Recovery"
  spicetify apply   || die "apply failed; see README > Recovery"
  ok "repaired"
  exit 0
fi

# --- 1. theme (fetch at the pinned commit if missing) ----------------------
if [ ! -f "$CFG/Themes/$THEME/color.ini" ]; then
  say "theme $THEME missing — fetching $THEME_REPO@$THEME_COMMIT"
  TMPT=$(mktemp -d)
  trap 'rm -rf "$TMPT"' EXIT INT TERM
  curl -fL --max-time 120 "https://codeload.github.com/$THEME_REPO/tar.gz/$THEME_COMMIT" \
    -o "$TMPT/theme.tgz" || die "theme download failed"
  tar xzf "$TMPT/theme.tgz" -C "$TMPT"
  SRC=$(find "$TMPT" -maxdepth 1 -type d -name 'mcloud-*' | head -1)
  [ -n "$SRC" ] || die "unexpected theme archive layout"
  mkdir -p "$CFG/Themes/$THEME"
  for f in theme.js user.css color.ini; do cp "$SRC/$f" "$CFG/Themes/$THEME/$f"; done
  ok "theme installed to $CFG/Themes/$THEME"
else
  ok "theme $THEME present"
fi

# --- 2. extensions + custom apps ------------------------------------------
mkdir -p "$CFG/Extensions" "$CFG/CustomApps"
for f in $(printf '%s' "$EXTENSIONS" | tr '|' ' '); do
  [ -f "$BUNDLED/Extensions/$f" ] || die "missing bundled extension: $f"
  cp "$BUNDLED/Extensions/$f" "$CFG/Extensions/$f"
done
ok "extensions copied from $BUNDLED"
[ -d "$CFG/CustomApps/lyrics-plus" ] || cp -R "$BUNDLED/CustomApps/lyrics-plus" "$CFG/CustomApps/"
ok "lyrics-plus present"

# Spicy Lyrics is not shipped with spicetify; it is installed from Marketplace,
# which writes this loader into Extensions. Only list it when it is actually
# there, so a fresh machine does not get a config entry pointing at nothing.
# The theme's artwork button prefers its fullscreen view over Spotify's
# Cinema Mode (see README > Full screen).
if [ -f "$CFG/Extensions/spicy-lyrics.mjs" ]; then
  case "|$EXTENSIONS|" in
    *"|spicy-lyrics.mjs|"*) ;;
    *) EXTENSIONS="$EXTENSIONS|spicy-lyrics.mjs" ;;
  esac
  ok "spicy-lyrics.mjs present (installed from Marketplace)"
else
  warn "spicy-lyrics.mjs missing; the player's fullscreen button will fall back to Spotify Cinema Mode"
fi

# macOS reserves F11, so rebind fullAppDisplay. Reapplied on every run because
# the extension file is copied fresh above.
FAD="$CFG/Extensions/fullAppDisplay.js"
if grep -q 'Mousetrap.bind("f11", toggleFad)' "$FAD"; then
  TMPFAD=$(mktemp)
  awk -v k="$FAD_KEY" '{gsub(/Mousetrap\.bind\("f11", toggleFad\)/,"Mousetrap.bind(\""k"\", toggleFad)")}1' "$FAD" > "$TMPFAD"
  mv "$TMPFAD" "$FAD"
  ok "fullAppDisplay rebound to $FAD_KEY"
fi

# --- 3. config -------------------------------------------------------------
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
TMPC=$(mktemp)
awk '/^\/\* == user-overrides:start == \*\/$/{skip=1}
     !skip{print}
     /^\/\* == user-overrides:end == \*\/$/{skip=0}' "$CSS" > "$TMPC"
printf '\n' >> "$TMPC"
cat "$ROOT/overrides.css" >> "$TMPC"
mv "$TMPC" "$CSS"
ok "overrides.css appended between markers (theme original kept as user.css.orig)"

# --- 5. backup + apply -----------------------------------------------------
if [ ! -d "$HOME/.local/state/spicetify/Backup" ] && [ ! -d "$CFG/Backup" ]; then
  warn "no spicetify backup yet — creating one (needed for rollback)"
  spicetify backup >/dev/null || die "backup failed"
fi

case "${1:-}" in
  --apply) say "applying (Spotify will restart)"; spicetify apply ;;
  *)       say "not applying. run: spicetify apply   (or: ./setup.sh --apply)" ;;
esac
