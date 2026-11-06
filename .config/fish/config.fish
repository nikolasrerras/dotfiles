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






# no fastfetch inside tmux (dropdown terminal)
if set -q TMUX
    function fish_greeting; end
end

# starship prompt (comment out to go back to the CachyOS prompt)
starship init fish | source

# ── terminal tools: fzf, atuin, bat (zoxide is set up above) ──
set -gx FZF_DEFAULT_OPTS "--color=16 --layout=reverse --border=none"
set -gx FZF_DEFAULT_COMMAND "fd --type f --hidden --exclude .git"
set -gx FZF_CTRL_T_COMMAND $FZF_DEFAULT_COMMAND
set -gx FZF_CTRL_T_OPTS "--preview 'bat --color=always --style=numbers --line-range :200 {}'"
set -gx FZF_ALT_C_COMMAND "fd --type d --hidden --exclude .git"
set -gx FZF_ALT_C_OPTS "--preview 'eza --tree --level=2 --color=always {}'"
set -gx BAT_THEME ansi
if status is-interactive
    fzf --fish | source
    atuin init fish --disable-up-arrow | source
end
