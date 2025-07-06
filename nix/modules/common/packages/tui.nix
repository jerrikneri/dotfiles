{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    amdgpu_top # Tool to display AMDGPU usage
    btop # htop / top alternative
    caligula # DD TUI (writing to disks)
    lazydocker
    lazygit
    lazysql
    newsboat # RSS TUI
    posting # Postman TUI
    spotify-player
    yazi # File TUI
  ];
}

