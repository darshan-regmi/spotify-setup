# Spotify, but Apple Music

A reproducible spicetify setup that makes the Spotify desktop client look and
behave like Apple Music: glass sidebar, floating player, Apple-style Now Playing,
artwork-tinted pages, plus a small set of navigation and lyrics upgrades.

Everything is CLI-managed. No Marketplace click-installs, so the whole state
lives in files you can version, diff and share.

![preview](https://raw.githubusercontent.com/mcloudHQ/mcloud/main/docs/screenshot.png)

*Screenshot from the theme's own repo — see [mcloudHQ/mcloud](https://github.com/mcloudHQ/mcloud) for more.*

## What you get

| Piece | Source | Notes |
|---|---|---|
| **AppleMusicMac** theme | [mcloudHQ/mcloud](https://github.com/mcloudHQ/mcloud) (MIT), pinned commit | Glass sidebar, floating player, Now Playing panel, tinted artist pages, 9 accents |
| `fullAppDisplay` | shipped with spicetify | Full-window artwork on **Ctrl+Shift+F** (F11 is macOS's Show Desktop) |
| `keyboardShortcut` | shipped with spicetify | `Ctrl+Tab` sidebar, `g g` / `Shift+G`, `Shift+H`/`Shift+L`, `m` like, `Ctrl+arrows` |
| `shuffle+` | shipped with spicetify | True, unbiased shuffle |
| `bookmark` | shipped with spicetify | Bookmark a page, a track, or a track position |
| `lyrics-plus` | shipped with spicetify | Synced lyrics, LRCLIB / lrc.red / Genius / Netease |
| CSS overrides | this repo (`overrides.css`) | Type scale, reduce-motion, FAD chrome hiding, Home promo-row hiding |

Extensions and `lyrics-plus` are **not vendored** here. They are copied out of
your own spicetify install at setup time, so they always match your CLI version.

## Requirements

- macOS (tested), or Linux/Windows — the theme works, but the fish helpers are macOS-only
- Spotify desktop, launched once so it has generated its app files
- spicetify 2.46.7+ — `brew install spicetify-cli`, or see [spicetify.app/docs](https://spicetify.app/docs/getting-started)
- `git`, `curl`, `tar`

## Install

```sh
git clone <this-repo-url> ~/spotify-setup
cd ~/spotify-setup
./setup.sh            # writes files + config, does not restart Spotify
./setup.sh --apply    # same, then applies (Spotify restarts)
```

`setup.sh` is idempotent — run it as often as you like. It will:

1. fetch the theme at the pinned commit if it's missing,
2. copy the extensions and `lyrics-plus` from your spicetify install,
3. rebind `fullAppDisplay` to `Ctrl+Shift+F` (macOS steals F11),
4. set the spicetify config explicitly (including `experimental_features 0`),
5. append `overrides.css` to the theme's `user.css` between markers,
6. create a rollback backup if you have none, and apply if you asked.

It **replaces** `current_theme`, but `extensions` and `custom_apps` are
**merged** into whatever you already have — spicetify never drops an entry on
its own. To remove one: `spicetify config extensions "name.js-"` then
`spicetify apply`. If you already have a curated spicetify setup, read
`setup.sh` first — it's short and commented.

### Optional: shell helpers (fish)

```sh
curl -fsSL <this-repo-raw-url>/spicetify.fish -o ~/.config/fish/conf.d/spicetify.fish
```

Gives you `spotify-fix` (repair after a Spotify update), `spotify-theme <name>`,
and `spotify-status`.

### Enable lyrics inside Full App Display

Press **Ctrl+Shift+F**, **right-click** inside the view, toggle
**Enable Lyrics Plus integration**. `vertical` in the same modal stacks the
lyrics under the artwork.

## Customizing

Edit `overrides.css` here, then `./setup.sh --apply`. Your rules are appended
under a marker block, so a theme update can't silently eat them.

Good starting points:

- **Accent colour** — the theme's own settings (profile menu → mcloud) have 9
  palettes; no CSS needed.
- **Tighter rows** — add to section 2, e.g.
  `.main-trackList-trackListRow { height: 40px !important; }`
- **Kill the promo rows entirely** — set `homeStyle` to `spotify` in mcloud's
  settings, or disable section 5.
- **Live CSS iteration** — `spicetify watch -s` reloads the theme on save;
  `spicetify enable-devtools` then `Cmd+Opt+I` to find selectors. Turn devtools
  back off when you're done (`spicetify config always_enable_devtools 0`).

## Updating

```sh
brew upgrade spicetify-cli     # CLI + bundled extensions, then ./setup.sh --apply
brew upgrade --cask spotify    # Spotify itself, then expect to run spotify-fix
```

Theme updates are deliberate and pinned. To move to a newer mcloud:

```sh
THEME_COMMIT=<new-commit-sha> ./setup.sh --apply
```

Pinning matters: the theme's `user.css` is overwritten on update, which is why
`setup.sh` re-appends your overrides every time.

## Recovery

Run these in order; stop at the first one that works.

1. Patch lost after a Spotify update → `./setup.sh --repair`
   (= `spicetify restore`, `spicetify backup`, `spicetify apply`).
2. Theme looks wrong / CSS broken → `spicetify restore backup apply`.
3. Backup stale or broken → `spicetify restore`, `spicetify clear`,
   `spicetify backup`, `spicetify apply`.
4. Everything is a mess → reinstall Spotify cleanly
   (`brew reinstall --cask spotify`), open it once, quit,
   then `spicetify backup apply`.
5. Reset to stock UI →
   ```sh
   spicetify restore
   spicetify config current_theme "" inject_css 0 inject_theme_js 0 replace_colors 0 extensions "" custom_apps ""
   spicetify apply
   ```

Never run spicetify with `sudo` and never with `--bypass-admin`.

## Uninstall

```sh
spicetify restore                       # put Spotify's original files back
rm -f ~/.config/fish/conf.d/spicetify.fish
rm -rf ~/spotify-setup ~/.config/spicetify/Themes/AppleMusicMac
# optional: brew uninstall spicetify-cli
```

## Known limitations

- Spotify versions above spicetify's supported ceiling still patch, but can break
  on the next Spotify release. Check `spicetify -v` against the
  [release notes](https://github.com/spicetify/cli/releases) before blaming the theme.
- `keyboardShortcut` binds `Ctrl+Q` to quitting Spotify and `m` to liking.
  Remove those lines in `~/.config/spicetify/Extensions/keyboardShortcut.js`
  (or in `setup.sh` afterwards) if they get in the way.
- **Marketplace is left installed but is not used for themes.** Installing a
  theme there creates a second, unreproducible mechanism.
- **No playback-speed control for music, by design of the client.** Spotify's
  player exposes `Spicetify.Platform.PlayerAPI.setSpeed`, but for a music track
  it refuses with `not_supported_by_content_type`; its own speed UI is gated on
  the item being a podcast/audiobook episode. No extension can work around a
  refusal from the native player. Podcasts and audiobooks keep their built-in
  speed control.
- This repo does not block Spotify updates, remove ads, or unlock paid features.

## Credits & licence

- Theme: [mcloudHQ/mcloud](https://github.com/mcloudHQ/mcloud) — MIT.
- spicetify and its bundled extensions: [spicetify/cli](https://github.com/spicetify/cli) — LGPL-2.1.
- `lyrics-plus` by khanhas, bundled with spicetify.
- This repo's glue (`setup.sh`, `overrides.css`, docs): MIT — see `LICENSE`.
