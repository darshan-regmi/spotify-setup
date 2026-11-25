# spotify-setup — change log

Every action with a timestamp, the command, its purpose and the result. Newest at the bottom.

| When | Command | Purpose | Result |
|---|---|---|---|
| 2026-11-23 11:23 | `sw_vers`, `uname -m`, `echo $SHELL` | Phase 0 preflight: detect OS/shell | macOS 27.2.1 (26B131), arm64, fish |
| 2026-11-23 11:23 | `defaults read /Applications/Spotify.app/Contents/Info.plist CFBundleShortVersionString` | Spotify version | 1.3.10.2586 (standard .app) |
| 2026-11-23 11:23 | `spicetify --version`, `spicetify path all`, `spicetify config` | Inventory | spicetify 2.46.7, theme=marketplace, no extensions |
| 2026-11-23 11:23 | `curl api.github.com/repos/spicetify/cli/releases/latest` | Check for newer release | v2.46.7 = latest; supports macOS Spotify 1.2.14–1.3.9 |
| 2026-11-23 11:23 | `cp -R ~/.config/spicetify/. ~/spotify-setup/backups/20261123-112342/` | Backup spicetify config folder before any change | 1.9M copied, verified |
| 2026-11-23 11:26 | `curl` spicetify-cli + spicetify-themes + marketplace GitHub APIs | Vet theme/extension sources and recency | Themes dirs listed; marketplace catalog is a dynamic GitHub search |
| 2026-11-23 11:31 | `tar tzf spicetify-2.46.7-darwin-arm64.tar.gz` | Confirm extensions/lyrics-plus ship with the CLI | `Extensions/*.js` and `CustomApps/lyrics-plus/` present |
| 2026-11-23 11:34 | GitHub API: mcloud, LiquidMusic, Appletify | Compare Apple-Music themes | mcloud MIT 25★ 2026-11-22; LiquidMusic 40★ no license; Appletify 30 open issues |
| 2026-11-23 11:38 | `brew list --cask`, `brew info spicetify-cli` | Check Homebrew policy fit | Spotify is a cask 1.3.10.2586; spicetify-cli 2.46.7 in core |
| 2026-11-23 11:41 | wrote `~/spotify-setup/PLAN.md` | Approval gate | Approved; Homebrew-first policy added |
| 2026-11-23 11:47 | `brew reinstall --cask spotify` | Pristine Spotify 1.3.10.2586 from cask | Success; `Apps/` contained only `xpui.spa` |
| 2026-11-23 11:50 | `spicetify backup` | Create real rollback baseline | Backup at `~/.local/state/spicetify/Backup` (15 MB: `xpui.spa`, `login.spa`) |
| 2026-11-23 11:53 | `brew install spicetify-cli` | Move CLI to Homebrew (same 2.46.7) | Installed; shadowed by `~/.spicetify` until PATH edit |
| 2026-11-23 11:56 | edit `~/.config/fish/config.fish` (diff approved) | Remove `~/.spicetify` PATH hunks | `fish -lc 'command -v spicetify'` → `/opt/homebrew/bin/spicetify` |
| 2026-11-23 11:58 | `spicetify config current_theme ""` + `apply -n` | Known-good baseline apply | exit 0, no errors (`logs/apply-01-baseline.log`) |
| 2026-11-23 11:56 | curl pinned commits → `Themes/AppleMusicMac`, `Themes/LiquidMusic` | Install both candidates | mcloud @91ee208, LiquidMusic @99d401b; sizes verified vs repo |
| 2026-11-23 11:58 | `spicetify config current_theme AppleMusicMac color_scheme Dark` + `apply` | Apply mcloud | exit 0; Spotify restarted (pid 18421→18555) |
| 2026-11-23 12:01 | `spicetify config current_theme LiquidMusic` + `apply` | Try-on comparison | exit 0; only update-check rate-limit errors |
| 2026-11-23 12:04 | back to `AppleMusicMac`, `rm -rf Themes/LiquidMusic` | Chosen theme: mcloud | exit 0 |
| 2026-11-23 12:06 | copy 4 extensions + `lyrics-plus`, `config extensions`/`custom_apps`, `apply` | Enable features | exit 0; restart ok; only rate-limit errors in log |
| 2026-11-25 12:20 | wrote `setup.sh`, appended `overrides.css` to theme `user.css` | Hide mcloud chrome + lift FAD above sidebar | Idempotent (re-run keeps 1 marker block); original kept as `user.css.orig` |
| 2026-11-25 12:26 | rebind `f11` → `ctrl+shift+f` in `fullAppDisplay.js` via `setup.sh` | macOS owns F11 ("Show Desktop") | Verified line 1040 |
| 2026-11-25 12:30 | `spicetify apply` | Load CSS + new keybind | FAD opens clean; lyrics visible once toggle enabled |
| 2026-11-25 12:38 | `spicetify config experimental_features 0 home_config 0` + `apply` | Config hygiene | Applied, exit 0 |
| 2026-11-25 12:44 | `overrides.css` §1 typography + §5 Home promo rows + `apply` | Apple-ish type, hide promo shelves | Applied, exit 0; user confirmed |
| 2026-11-25 12:52 | wrote `~/.config/fish/conf.d/spicetify.fish` | `spotify-fix`, `spotify-theme`, `spotify-status` | All three load in a fresh fish shell |
| 2026-11-25 12:58 | wrote `README.md`, `.gitignore`, `git init` + commit `9508307` | Lock it in | Clean tree; backups/ and logs/ ignored |
| 2026-11-25 13:00 | health check | Final verification | theme CSS + 4 extensions in app; lyrics-plus/marketplace routes built; backup present |
