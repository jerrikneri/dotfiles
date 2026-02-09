{ pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    # btop # htop / top alternative
    caligula # DD TUI (writing to disks)
    lazydocker
    lazygit
    lazysql
    jiratui
    # newsboat # RSS TUI
    # posting # Postman TUI # broken package python3.13-textual-4.0.0
    spotify-player
    (weechat.override {
      configure = { availablePlugins, ... }: {
        plugins = with availablePlugins; [
          python
          perl
        ];
        scripts = with pkgs.weechatScripts; [
          wee-slack
        ];
      };
    })
    yazi # File TUI
  ] ++ lib.optionals pkgs.stdenv.isDarwin [
    btop # htop / top alternative
  ];
}

