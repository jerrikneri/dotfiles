echo 'Starting shared install script...'
########
# zsh #
#######

mkdir -p "$XDG_CONFIG_HOME/zsh"

ln -sf "$DOTFILES_CONFIG/zsh/.zshrc" "$ZDOTDIR/.zshrc"
# TODO: add nvim and nix here?
# ln -sf "$DOTFILES_CONFIG/nvim" "$XDG_CONFIG_HOME"

rm -rf "$XDG_CONFIG_HOME/zsh/external"
ln -sf "$DOTFILES_CONFIG/zsh/external" "$ZDOTDIR"

########
# tmux #
########

if [ ! -d "$XDG_CONFIG_HOME/tmux" ]; then
  mkdir "$XDG_CONFIG_HOME/tmux"
  git clone https://github.com/tmux-plugins/tpm "$XDG_CONFIG_HOME/tmux/plugins/tpm"
  "$XDG_CONFIG_HOME/tmux/plugins/tpm/bin/install_plugins"
fi

ln -sf "$DOTFILES_CONFIG/tmux/tmux.conf" "$XDG_CONFIG_HOME/tmux/tmux.conf"

# Generate default tmux conf
# tmux -f /dev/null show-options -s \; show-options -g \; list-keys > "$DOTFILES/tmux/tmux.defaults.conf"

# if [ ! -d "$XDG_CONFIG_HOME/tmux/plugins/tpm" ]
# then
#     git clone https://github.com/tmux-plugins/tpm "$XDG_CONFIG_HOME/tmux/plugins/tpm"
# fi
