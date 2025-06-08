{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    btop # htop / top alternative
    lazydocker
    lazygit
    lazysql
    newsboat # RSS TUI
    posting # Postman TUI
    yazi # File TUI
  ];
}

