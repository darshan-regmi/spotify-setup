# Spotify customization (macOS, arm64)

Spicetify setup tuned to look and behave like Apple Music, built 2026‑11‑23/25.
Everything here is CLI‑managed: no Marketplace click-installs, so the whole state
is reproducible from this folder.

## What's installed

| Piece | Source | Notes |
|---|---|---|
| Spotify 1.3.10.2586 | Homebrew cask `spotify` | Standard `.app`, reinstallable with `brew reinstall --cask spotify` |
| spicetify 2.46.7 | Homebrew `spicetify-cli` | `/opt/homebrew/bin/spicetify`; old curl install left at `~/.spicetify` (unused) |
| Theme **AppleMusicMac** | [mcloudHQ/mcloud](https://github.com/mcloudHQ/mcloud) @ `91ee208`, MIT | Glass sidebar, floating player, Apple-style Now Playing, 9 accents, light/dark |
| `fullAppDisplay.js` | spicetify 2.46.7 release | Full-window artwork; **Ctrl+Shift+F** (was F11 — macOS owns that key) |
| `keyboardShortcut.js` | spicetify 2.46.7 release | `Ctrl+Tab` sidebar, `g g`/`Shift+G`, `Shift+H`/`Shift+L`, `m` like, `Ctrl+arrows` seek/volume. **`Ctrl+Q` quits Spotify** |
| `shuffle+.js` | spicetify 2.46.7 release | True shuffle; click the shuffle button |
| `bookmark.js` | spicetify 2.46.7 release | Bookmark page / track / track position |
| `lyrics-plus` custom app | spicetify 2.46.7 release | Synced lyrics; LRCLIB/lrc.red/Genius/Netease providers |
| Marketplace | (pre-existing) | Kept for browsing, **not** used to install themes |

Config: `inject_css 1`, `inject_theme_js 1`, `replace_colors 1`,
`experimental_features 0`, `home_config 0`, devtools off, update check on,
`disable_sentry 1`, `disable_ui_logging 1`, `remove_rtl_rule 1`, `expose_apis 1`.

Personal CSS lives in `overrides.css` and is appended to the theme's `user.css`
between `/* == user-overrides:start == */` and `/* == user-overrides:end == */`.
Sections: typography, motion, Full‑App‑Display chrome hiding, Home promo-row hiding.

## Daily commands

```sh
spotify-status            # spicetify/Spotify versions, theme, extensions, backup present?
spotify-theme <name>      # switch theme by folder name (restarts Spotify)
spotify-fix               # after a Spotify update: restore -> backup -> apply
```

`spotify-fix` and friends live in `~/.config/fish/conf.d/spicetify.fish`.

## Updating

```sh
brew upgrade spicetify-cli     # CLI + bundled extensions (then: ./setup.sh --apply)
brew upgrade --cask spotify    # Spotify itself; expect to run spotify-fix afterwards
```

Theme updates are manual and deliberate — the installed copy is pinned:

```sh
cd ~/spotify-setup
curl -fL https://codeload.github.com/mcloudHQ/mcloud/tar.gz/<new-commit> -o /tmp/mcloud.tgz
tar xzf /tmp/mcloud.tgz -C /tmp && cp /tmp/mcloud-*/{theme.js,user.css,color.ini} \
  ~/.config/spicetify/Themes/AppleMusicMac/
./setup.sh --apply             # re-appends your override block
```

Pinning matters: `main` can move under you, and a theme update overwrites
`user.css`, which is why overrides are re-applied by the script.

## Recovery, in order

1. **Patch lost after a Spotify update** → `spotify-fix`
   (= `spicetify restore`, `spicetify backup`, `spicetify apply`).
2. **Theme looks wrong / CSS errors** → `spicetify restore backup apply`.
3. **Backup itself is stale or broken** →
   `spicetify restore`, `spicetify clear`, `spicetify backup`, `spicetify apply`.
4. **Everything is a mess** → `brew reinstall --cask spotify` (pristine 1.3.10),
   open Spotify once, quit, then `spicetify backup apply`.
5. **Undo the customization entirely** →
   `spicetify restore && spicetify config current_theme "" inject_css 0 inject_theme_js 0 replace_colors 0 extensions "" custom_apps "" && spicetify apply`

Never run spicetify with `sudo`.

## Layout

```
~/spotify-setup/
  setup.sh          idempotent install / --apply / --repair
  overrides.css     your CSS layer (single source of truth)
  README.md         this file
  PLAN.md           the approved plan
  CHANGELOG.md      every command run, with timestamps
  logs/             spicetify apply output per batch
  backups/          config snapshots + pristine Spotify .app tarball dir
~/.config/spicetify/
  config-xpui.ini   spicetify config (CLI-managed)
  Themes/AppleMusicMac/{color.ini,user.css,user.css.orig,theme.js}
  Extensions/{fullAppDisplay,keyboardShortcut,shuffle+,bookmark}.js
  CustomApps/{lyrics-plus,marketplace}
~/.local/state/spicetify/Backup/    pristine xpui.spa/login.spa (rollback)
```

## Known risks

- **Spotify 1.3.10 is above spicetify 2.46.7's official ceiling (1.3.9).** It works
  today; a future Spotify release can break `apply` until spicetify ships support.
  Mitigation: `brew upgrade spicetify-cli`, then `spotify-fix`.
- **Two third-party pieces run JS inside Spotify**: mcloud's `theme.js` and the four
  extensions. Installed copies are pinned; review diffs before updating.
- **`Ctrl+Q` quits Spotify** via `keyboardShortcut.js`. Edit the copied file (and
  `setup.sh` copies it back on each run) if that bites.
- **Marketplace is installed but unused for themes.** Installing a theme there would
  create a second, unreproducible mechanism — don't.
- **LiquidMusic was evaluated and removed**; no license, so it's not redistributed here.

## Deliberate omissions

Spotify update blocking, Marketplace-managed themes, ad-blocking / premium unlocks,
sudo, custom app development, always-on devtools.
