{ pkgs, lib, isLinux, isDarwin, desktop, game, ... }:

{
  environment.systemPackages = with pkgs; [
    # btop # htop / top alternative
    caligula # DD TUI (writing to disks)
    gh-dash
    lazydocker
    lazygit
    lazysql
    # newsboat # RSS TUI - broken on darwin with libc++ 20.1.0 (sizeof function type error)
    # posting # Postman TUI # broken package python3.13-textual-4.0.0
    slides
    spotify-player
    # (weechat.override {
    #   configure = { availablePlugins, ... }: {
    #     plugins = with availablePlugins; [
    #       python
    #       perl
    #     ];
    #     scripts = with pkgs.weechatScripts; [
    #       wee-slack
    #     ];
    #   };
    # })
    yazi # File TUI
  ] ++ lib.optionals isDarwin [
    btop
  ] ++ lib.optionals (isLinux && desktop) [
    # -- desktop: move packages here --
  ] ++ lib.optionals (isLinux && game) [
    # -- gaming: move packages here --
  ];
}

