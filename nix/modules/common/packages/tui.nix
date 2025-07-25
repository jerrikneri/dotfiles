{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # btop # htop / top alternative
    caligula # DD TUI (writing to disks)
    lazydocker
    lazygit
    lazysql
    newsboat # RSS TUI
    # posting # Postman TUI # broken package python3.13-textual-4.0.0
    spotify-player
    yazi # File TUI
  ];
}

