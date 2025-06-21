### Fresh NixOS ----------
`nix-shell -p git`

`git clone https://github.com/jerrikneri/dotfiles.git`

`cp /etc/nixos/hardware-configuration.nix ~/code/dotfiles/nix/hosts/nixos`

## Clear old builds
`sudo nix-collect-garbage --delete-older-than 3d`

## Darwin
### Rebuild nix config
`sudo darwin-rebuild switch --flake .\#darwin`

## Linux 
### Rebuild nix config
`sudo home-manager switch --flake .\#linux`


## NixOS 
### Rebuild nixos config
`sudo nixos-rebuild switch --flake .\#nixos`

## Tmux
`git clone https://github.com/tmux-plugins/tpm $DOTFILES_CONFIG/.config/tmux/plugins/tpm`
### Might install at ~/.tmux 
`rm $DOTFILES_CONFIG/.config/tmux`
`mv ~/.tmux/plugins $DOTFILES_CONFIG/.config/tmux`

`$DOTFILES_CONFIG/tmux/plugins/tpm/bin/install_plugins`
