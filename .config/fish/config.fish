source /usr/share/cachyos-fish-config/cachyos-config.fish

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
zoxide init fish | source

# ── fastfetch greeting ──────────────────────────────────────────────
# Overrides the CachyOS greeting (must stay below its `source` line).
# Uses the small logo in narrow windows, and redraws once the window
# gets its final size (niri resizes new windows right after they open).




# fastfetch greeting: big CachyOS logo; zoom out once in narrow kitty windows
function __ff_show
    if test $COLUMNS -lt 118; and set -q KITTY_LISTEN_ON; and not set -q __ff_zoomed
        set -g __ff_zoomed 1
        kitty @ set-font-size 9 2>/dev/null; and return  # the resize redraws it
    end
    fastfetch
end

function fish_greeting
    function __ff_redraw --on-signal WINCH
        clear
        __ff_show
        commandline -f repaint
    end
    function __ff_done --on-event fish_preexec
        functions -e __ff_redraw __ff_done
    end
    __ff_show
end
