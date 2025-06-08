
## Clear old builds
sudo nix-collect-garbage -D

## Darwin
### Rebuild nix config
sudo darwin-rebuild switch --flake .\#darwin

## Linux 
### Rebuild nix config
sudo home-manager switch --flake .\#linux


## NixOS 
### Rebuild nixos config
sudo nixos-rebuild switch --flake .\#nixos
