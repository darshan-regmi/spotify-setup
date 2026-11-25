# Spicetify helpers — auto-loaded by fish from ~/.config/fish/conf.d/
# Created 2026-11-25 by spotify-setup. Delete this file to remove all helpers.

if type -q spicetify

    # Repair after Spotify updates itself and wipes the patch.
    # Flow is restore -> backup -> apply, so the backup matches the new
    # Spotify build instead of the old one.
    function spotify-fix --description "Re-apply spicetify after a Spotify update (restarts Spotify)"
        set -l dir ~/spotify-setup/logs
        set -l log $dir/fix-(date +%Y%m%d-%H%M%S).log
        mkdir -p $dir
        echo "→ 1/3 restore original app files"
        if not spicetify restore >>$log 2>&1
            echo "✗ restore failed — read $log, then see README > Recovery"
            return 1
        end
        echo "→ 2/3 backup the current Spotify build"
        spicetify backup >>$log 2>&1
        echo "→ 3/3 apply theme, extensions, apps (Spotify restarts)"
        if not spicetify apply >>$log 2>&1
            echo "✗ apply failed — read $log, then see README > Recovery"
            return 1
        end
        echo "✓ repaired — log: $log"
    end

    # Switch theme by folder name: spotify-theme AppleMusicMac
    function spotify-theme --description "Switch spicetify theme (restarts Spotify)"
        set -l themes (ls ~/.config/spicetify/Themes)
        if test (count $argv) -eq 0
            echo "Themes available: $themes"
            return 0
        end
        if not contains -- $argv[1] $themes
            echo "No such theme: $argv[1]"
            echo "Themes available: $themes"
            return 1
        end
        spicetify config current_theme $argv[1]
        and spicetify apply
    end

    # One-line health check.
    function spotify-status --description "Show spicetify health at a glance"
        set -l theme (spicetify config current_theme | string replace -r '^[a-z_]+:\s*' '' | string join ' ')
        set -l exts (spicetify config extensions | string replace -r '^[a-z_]+:\s*' '' | string join ' ')
        set -l apps (spicetify config custom_apps | string replace -r '^[a-z_]+:\s*' '' | string join ' ')
        echo "spicetify : "(command -v spicetify)" "(spicetify -v | tail -1)
        echo "spotify   : "(defaults read /Applications/Spotify.app/Contents/Info.plist CFBundleShortVersionString 2>/dev/null)
        echo "theme     : "$theme
        echo "extensions: "$exts
        echo "apps      : "$apps
        test -d ~/.local/state/spicetify/Backup
        and echo "backup    : present"
        or echo "backup    : MISSING — run: spicetify backup"
    end

end
