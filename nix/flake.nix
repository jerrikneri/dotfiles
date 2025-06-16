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
          ./modules/common/programs.nix
          ./modules/common/shell.nix
          ./modules/linux/system.nix
          home-manager.nixosModules.default
        ];
      };

      darwinConfigurations.darwin = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          ./hosts/darwin/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/programs.nix
          ./modules/darwin/system.nix
          home-manager.darwinModules.default
        ];
      };

      homeConfigurations.arch = home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs { system = "x86_64-linux"; };
        modules = [
          ./hosts/arch/configuration.nix
          ./modules/common/packages/index.nix
          ./modules/common/programs.nix
          ./modules/common/shell.nix
        ];
      };

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          languages = [ "go" "node" "php" "python" "rust" ];
          projects = [ "tp" ];
        in 
          nixpkgs.lib.genAttrs languages (lang:
            import ./modules/dev/${lang}.nix { inherit pkgs; }
          ) // nixpkgs.lib.genAttrs projects (project:
            import ./modules/dev/projects/${project}.nix { inherit pkgs; }
          )
      );
    };
}

