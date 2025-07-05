### Fresh NixOS ----------
`mkdir -p ~/.config/nix && cd ~/.config/nix && touch nix.conf && echo "experimental-features = nix-command flakes" > nix.conf`

`nix-shell -p git`

`git clone https://github.com/jerrikneri/dotfiles.git`
`git clone git@github.com:jerrikneri/dotfiles.git`

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

### List Build Generations
`sudo nix-env --list-generations --profile /nix/var/nix/profiles/system`

### Revert to Previous Build Generation
`sudo nixos-rebuild switch --rollback --flake .\#nixos`

## Tmux
`git clone https://github.com/tmux-plugins/tpm $DOTFILES_CONFIG/tmux/plugins/tpm`

`$DOTFILES_CONFIG/tmux/plugins/tpm/bin/install_plugins`
