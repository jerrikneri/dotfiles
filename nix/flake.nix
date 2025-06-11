{
  description = "Cross-platform flake config (NixOS + macOS + Arch)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    darwin = {
      url = "github:lnl7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, darwin, ... }:
    let
      supportedSystems = ["x86_64-linux" "aarch64-linux"];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/shell.nix
          ./modules/linux/system.nix
          home-manager.nixosModules.default
        ];
      };

      darwinConfigurations.darwin = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/darwin/default.nix
          ./modules/common/packages/index.nix
          ./modules/darwin/shell.nix
          ./modules/darwin/system.nix
          home-manager.darwinModules.default
        ];
      };

      homeConfigurations.arch = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          ./hosts/arch/default.nix
          ./modules/common/packages/index.nix
          ./modules/common/shell.nix
        ];
      };

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          languages = [ "default" "go" "node" "php" "python" "rust" ];
        in {
          devShells = nixpkgs.lib.genAttrs languages (lang:
            import (./modules/common/dev + "/${lang}.nix") { inherit pkgs; }
          );
          # go = import ./modules/common/dev/go.nix { inherit pkgs; };
          # node = import ./modules/common/dev/node.nix { inherit pkgs; };
          # php = import ./modules/common/dev/php.nix { inherit pkgs; };
          # python = import ./modules/common/dev/python.nix { inherit pkgs; };
          # rust = import ./modules/common/dev/rust.nix { inherit pkgs; };
          # default = import ./modules/common/dev/shell.nix { inherit pkgs; };
        }
      );
    };
}

