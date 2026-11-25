# Plan — Apple-Music-style Spotify via spicetify

Status: awaiting approval. Nothing below has been executed.

## Assumptions
- Spotify is quit for every `apply` (it restarts the app).
- Theme mechanism is **CLI-managed only**: theme files live in `~/.config/spicetify/Themes/`, selected with `spicetify config`. We do **not** click-install themes in the Marketplace UI (its state lives in Spotify's localStorage, so it can't be reproduced).
- Everything is reversible with `spicetify restore backup apply` or by switching `current_theme` back and re-applying.
- No `sudo`. macOS standard `.app` build.

## Policy: Homebrew first
Anything installable goes through Homebrew. Spotify is already a cask (`spotify 1.3.10.2586`), and `spicetify-cli` is in homebrew-core at 2.46.7. Themes are not in Homebrew, so they come from their upstream GitHub repos, pinned to a commit.

## Step 0 — restore a real rollback baseline (recommended)
Why: `~/.config/spicetify/Backup` is missing, so `spicetify restore` has nothing to restore. Spotify's `xpui` is already patched, so `spicetify backup` today would capture *patched* files as "original".

```
osascript -e 'quit app "Spotify"'
brew reinstall --cask spotify          # cask, same version 1.3.10.2586, pristine files
open -a Spotify                        # start once so it writes its runtime files
osascript -e 'quit app "Spotify"'
spicetify backup                       # creates ~/.config/spicetify/Backup from pristine files
```
Verify: `ls ~/.config/spicetify/Backup/xpui | head` → files present.
Risk: low (same version; account state untouched; ~2 min).
Undo: not applicable — this *is* the undo.
Skip if: you'd rather not reinstall; then rollback = `brew reinstall --cask spotify`, and I run `spicetify backup apply` once so a backup exists.

## Step 0b — same-version sidegrade of the CLI to Homebrew (optional)
Why: `spicetify` 2.46.7 currently lives in `~/.spicetify` from the curl installer; the brew formula is the same version, so future upgrades become `brew upgrade spicetify-cli`.
```
brew install spicetify-cli
# then remove the two ~/.spicetify PATH lines from ~/.config/fish/config.fish (diff shown first)
exec fish -c 'command -v spicetify; spicetify -v'
```
Expected: `/opt/homebrew/bin/spicetify`, `2.46.7`.
Risk: two copies fight over `PATH`; `~/.spicetify` is left on disk untouched, so reverting is re-adding one line.
Undo: restore the `PATH` line; `brew uninstall spicetify-cli`.

## Step 1 — known-good apply (no theme change)
```
spicetify config inject_css 1 replace_colors 1 inject_theme_js 1
spicetify apply -n
```
Expect: Spotify restarts, Marketplace tab still present, nothing visually different.
Undo: `spicetify restore backup apply`.

## Step 2 — theme: try two, keep one
Install both CLI-side, then flip between them (each flip = one Spotify restart):
```
mkdir -p ~/.config/spicetify/Themes/AppleMusicMac ~/.config/spicetify/Themes/LiquidMusic
# mcloud (MIT, 25★, pushed 2026-11-22) — files: theme.js user.css color.ini
for f in theme.js user.css color.ini; do
  curl -fsSL "https://raw.githubusercontent.com/mcloudHQ/mcloud/<pinned-commit>/$f" \
    -o ~/.config/spicetify/Themes/AppleMusicMac/$f
done
# LiquidMusic (40★, 2026-11-21, NO LICENSE — local use only, not redistributable)
for f in theme.js user.css color.ini manifest.json; do
  curl -fsSL "https://raw.githubusercontent.com/fraustiz/LiquidMusic/<pinned-commit>/$f" \
    -o ~/.config/spicetify/Themes/LiquidMusic/$f
done

spicetify config current_theme AppleMusicMac color_scheme Dark
spicetify config inject_css 1 replace_colors 1 inject_theme_js 1
spicetify apply -n
```
Swap to `current_theme LiquidMusic` + `spicetify apply -n` to compare. Keep the winner, then:
```
rm -rf ~/.config/spicetify/Themes/<loser>
```
Why: both are purpose-built Apple-Music clones; hand-writing that much CSS is worse.
Risk: third-party `theme.js` executes inside Spotify. Both were read at plan time; installs are pinned to a commit, not `main`.
Undo: `spicetify config current_theme marketplace` … or `spicetify restore backup apply`, then delete the folder.

## Step 3 — extensions + lyrics app
All from the spicetify 2.46.7 release (verified present in the release tarball), copied from whichever copy of the CLI is active — `~/.spicetify/` now, `/opt/homebrew/opt/spicetify-cli/libexec/` if Step 0b happens:
```
EXT_SRC=~/.spicetify/Extensions        # after Step 0b: /opt/homebrew/opt/spicetify-cli/libexec/Extensions
APP_SRC=~/.spicetify/CustomApps        # after Step 0b: /opt/homebrew/opt/spicetify-cli/libexec/CustomApps
cp "$EXT_SRC"/{fullAppDisplay.js,keyboardShortcut.js,shuffle+.js,bookmark.js} ~/.config/spicetify/Extensions/
cp -R "$APP_SRC/lyrics-plus" ~/.config/spicetify/CustomApps/
spicetify config extensions "fullAppDisplay.js|keyboardShortcut.js|shuffle+.js|bookmark.js"
spicetify config custom_apps "marketplace|lyrics-plus"
spicetify apply -n -e -a
```
Dropped per your "trim to 5": `trashbin.js`, `autoSkipExplicit.js`, `autoSkipVideo.js` (add later in one line if missed).
Risk: `fullAppDisplay` is a full-window takeover and may fight the theme's floating player — first thing I'd drop if it looks wrong.
Undo: remove the name from the `extensions` list and `spicetify apply`.

## Step 4 — config hygiene
```
spicetify config experimental_features 0 home_config 0 always_enable_devtools 0 check_spicetify_update 1
spicetify config disable_sentry 1 disable_ui_logging 1 expose_apis 1 remove_rtl_rule 1
spicetify apply -n
```
`sentry`/`ui_logging`/`expose_apis` are already correct — re-asserted for idempotency.
Undo: set any field back to its old value (recorded in CHANGELOG).

## Step 5 — Apple Music polish (Phase 4, iterative)
Your overrides live in `~/spotify-setup/overrides.css`, appended to the active theme's `user.css` between `/* == user-overrides == */` markers by `setup.sh`. Theme updates can't silently eat them.
Tools: `spicetify watch -s` (live CSS), `spicetify enable-devtools` (only while tweaking, turned off after).
Undo: delete the marker block, `spicetify refresh`.

## Step 6 — lock it in
- `~/.config/fish/conf.d/spicetify.fish` with `spotify-fix` (repair after Spotify update) and `spotify-theme <name>` (switch theme). Diff shown before writing.
- `~/spotify-setup/setup.sh`: idempotent re-install of theme + extensions + config on a new machine or after a disaster.
- `git init` in `~/spotify-setup`, `.gitignore` = `backups/`, `*.dmg`, `.DS_Store`. Local only, no remote unless you ask.
- `README.md`: what's installed, update procedure, repair, rollback.

## Deliberately not doing
- Blocking Spotify updates (`spotify-updates block`) — you chose repair-alias instead.
- Marketplace-managed theme installs (state isn't reproducible).
- Ad-blocking / paid-feature unlocks — not requested, and they break the client's terms.
- Hand-editing Spotify's own files; any `sudo`; reading your prefs/credentials.
- Custom app/extension development.
- Always-on devtools.
