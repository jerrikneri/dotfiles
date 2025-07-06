{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    amdgpu_top # Tool to display AMDGPU usage
    # btop # htop / top alternative
    (pkgs.btop.overrideAttrs (old: {
      cmakeFlags = (old.cmakeFlags or []) ++ [
        "-DBTOP_GPU=ON"
      ];
      buildInputs = old.buildInputs ++ [ pkgs.rocmPackages.rocm-smi ];
    }))
    caligula # DD TUI (writing to disks)
    lazydocker
    lazygit
    lazysql
    newsboat # RSS TUI
    posting # Postman TUI
    radeontop
    spotify-player
    yazi # File TUI
  ];
}

