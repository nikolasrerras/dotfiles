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





