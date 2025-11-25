fpath=($ZDOTDIR/external $fpath)

# autocorrect
setopt CORRECT

# history setup
setopt SHARE_HISTORY               # Share history across all sessions immediately
setopt INC_APPEND_HISTORY         # Write to history file immediately, not on shell exit
setopt HIST_EXPIRE_DUPS_FIRST     # Expire duplicates first when trimming history
setopt EXTENDED_HISTORY           # Record timestamp of command in HISTFILE
setopt HIST_IGNORE_DUPS           # Don't record duplicate consecutive commands
setopt HIST_FIND_NO_DUPS          # Don't display duplicates when searching history

# glob
setopt DOT_GLOB
setopt EXTENDED_GLOB

# autocompletion using arrow keys (based on history)
# Note: replaced by history-substring-search below (see macOS section)
# bindkey '\e[A' history-search-backward
# bindkey '\e[B' history-search-forward

# try j k for arrows history autocomplete
#bindkey -M vicmd "j" up-line-or-beginning-search
#bindkey -M vicmd "k" down-line-or-beginning-search

zmodload zsh/complist
zmodload zsh/zprof # time profile initiation

bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char
bindkey -M menuselect 'j' vi-down-line-or-history

autoload -Uz compinit; compinit -C
_comp_options+=(globdots) # With hidden files
source $DOTFILES_CONFIG/zsh/external/completion.zsh

autoload -Uz prompt_purification_setup && prompt_purification_setup

# Push the current directory visited on to the stack.
setopt AUTO_PUSHD
# Do not store duplicate directories in the stack
setopt PUSHD_IGNORE_DUPS
# Do not print the directory stack after using
setopt PUSHD_SILENT

bindkey -v
export KEYTIMEOUT=1

#autoload -Uz cursor_mode && cursor_mode

autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd v edit-command-line

source $DOTFILES_CONFIG/zsh/external/bd.zsh

if [ "$(tty)" = "/dev/tty1" ];
then
#    pgrep i3 || exec startx "$XDG_CONFIG_HOME/X11/.xinitrc"
fi

#source $DOTFILES_CONFIG/scripts.sh

source $SCRIPTS/set_os.sh

# Perform actions based on the value of CURRENT_OS
case "$CURRENT_OS" in
    macOS)
        echo "You are on macOS."

        # Try Nix-installed plugins first if NIX_ENABLED
        if [[ "$NIX_ENABLED" == "true" ]]; then
            echo "NixOS Enabled."
            [[ -f "$NIX_SHARE_PATH/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
              && source "$NIX_SHARE_PATH/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
            [[ -f "$NIX_SHARE_PATH/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] \
              && source "$NIX_SHARE_PATH/zsh/plugins/zsh-history-substring-search/zsh-history-substring-search.zsh"
            [[ -f "$NIX_SHARE_PATH/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]] \
              && source "$NIX_SHARE_PATH/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
            [[ -f "$NIX_SHARE_PATH/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
              && source "$NIX_SHARE_PATH/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
        fi

        # Fallback to Homebrew if Nix not enabled or plugins not found
        if command -v brew &> /dev/null; then
            if [[ -n "$BREW_PREFIX" ]]; then
              [[ -f "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
                && source "$BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh"

              [[ -f "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh" ]] \
                && source "$BREW_PREFIX/share/zsh-history-substring-search/zsh-history-substring-search.zsh"

              [[ -f "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]] \
                && source "$BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh"

              [[ -f "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] \
                && source "$BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
            fi
            # BREW_PREFIX=$(brew --prefix)
            # source $BREW_PREFIX/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
            # source $BREW_PREFIX/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

            #source $(brew --prefix)/opt/zsh-vi-mode/share/zsh-vi-mode/zsh-vi-mode.plugin.zsh
            #source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        fi

        if command -v fzf &> /dev/null; then
            source <(fzf --zsh)
        fi
        ;;

    arch)
        echo "You are on Arch Linux."
        if [ $(command -v "fzf") ]; then
            source /usr/share/fzf/completion.zsh
            source /usr/share/fzf/key-bindings.zsh
        fi

        source /usr/share/zsh/plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh
        source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
        ;;

    debian)
        echo "You are on Debian-based Linux."
        ;;

    *)
        echo "Unknown or unsupported OS: $CURRENT_OS"
        ;;
esac

# Bind arrow keys to history substring search (after plugins are loaded, works on all OS)
bindkey '\e[A' history-substring-search-up
bindkey '\e[B' history-substring-search-down

if [ -f $SCRIPTS/import_aliases_functions_modules.sh ]; then
    echo 'Sourcing from aliases functions modules from .zshrc'
    source $SCRIPTS/import_aliases_functions_modules.sh
fi

if command -v talosctl &> /dev/null && [ -n "$CONTROL_PLANE_IP" ]; then
    talosctl config endpoint $CONTROL_PLANE_IP
    talosctl config node $CONTROL_PLANE_IP
else
    echo "Either talosctl is not installed or CONTROL_PLANE_IP is not set."
fi

# export PROMPT_COMMAND='time_start=$(date +%s); $PROMPT_COMMAND; echo "Startup took $(($(date +%s) - $time_start)) seconds"'

export PATH="/opt/homebrew/bin:$PATH"
export PATH="$DOTFILES/bin:$PATH"
