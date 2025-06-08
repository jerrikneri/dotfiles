Test
## Symlink /etc/nixos
sudo ln -s ~/code/nix-config/hosts/nixos /etc/nixos

## Clear old builds
sudo nix-collect-garbage -D

## Rebuild nixos config
sudo nixos-rebuild switch
