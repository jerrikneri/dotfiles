{
  description = "Cross-platform flake config (Darwin + Linux + NixOS)";

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
      supportedSystems = ["x86_64-linux" "aarch64-linux" "aarch64-darwin"];
      forAllSystems = f: nixpkgs.lib.genAttrs supportedSystems f;
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };
      username = builtins.getEnv "USER";
    in {
      nixosConfigurations.nixos = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { game = true; };
        modules = [
          ./hosts/nixos/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/programs.nix
          ./modules/common/shell.nix
          ./modules/linux/system.nix
          home-manager.nixosModules.default
        ];
      };

      nixosConfigurations.nixos-game = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        specialArgs = { game = true; };
        modules = [
          ./hosts/nixos-game/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/programs.nix
          ./modules/common/shell.nix
          ./modules/linux/system.nix
          home-manager.nixosModules.default
        ];
      };

      nixosConfigurations.nixos-pve = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos-pve/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/shell.nix
          ./modules/linux/system.nix
          home-manager.nixosModules.default
        ];
      };

      nixosConfigurations.nixos-utm = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/nixos-utm/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/shell.nix
          ./modules/linux/system.nix
          home-manager.nixosModules.default
        ];
      };


      darwinConfigurations.darwin = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        specialArgs = { game = false; };
        modules = [
          ./hosts/darwin/configuration.nix
          ./modules/common/packages/index.nix
          # ./modules/common/programs.nix
          ./modules/darwin/system.nix
          home-manager.darwinModules.default
          # {
          #   home-manager.useUserPackages = true;
          #   home-manager.users.${username} = {
          #     imports = [
          #       ./modules/common/programs.nix
          #     ];
          #   };
          # }
        ];
      };

      homeConfigurations.linux = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          ./hosts/linux/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/programs.nix
          ./modules/common/shell.nix
        ];
      };

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          languages = [ "go" "node" "php" "python" "rust" ];
          projects = [ "tp" "doom"];
        in 
          nixpkgs.lib.genAttrs languages (lang:
            import ./modules/dev/${lang}.nix { inherit pkgs; }
          ) // nixpkgs.lib.genAttrs projects (project:
            import ./modules/dev/projects/${project}.nix { inherit pkgs; }
          )
      );
    };
}

