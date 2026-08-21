# NOTE: This module is currently DISABLED and not imported by any host.
# It is kept for reference only.
#
# Why disabled: the `ffAddons` binding below calls
#   pkgs.callPackage (pkgs.path + "/pkgs/applications/networking/browsers/firefox/addons") {}
# but that path no longer exists in the pinned nixpkgs (nixpkgs-unstable),
# causing a hard config-evaluation error on every host:
#   error: path '.../pkgs/applications/networking/browsers/firefox/addons' does not exist
#
# To re-enable: source the extensions a different way (e.g. a
# `nixpkgs/firefox-addons` flake input, or NUR) and re-add
# `imports = [ ./firefox.nix ];` to modules/common/home.nix.

{ config, pkgs, ... }:

let
  ffAddons = pkgs.callPackage (pkgs.path + "/pkgs/applications/networking/browsers/firefox/addons") { };
in
{
  programs.firefox = {
    enable = true;
    profiles.default = {
      isDefault = true;
      extensions = with ffAddons; [
        ublock-origin
        bitwarden
        vimium
        darkreader
        multi-account-containers
        noscript
        duckduckgo-privacy-essentials
      ];
      settings = {
        "browser.startup.homepage" = "chrome://browser/content/blanktab.html";
        "browser.startup.page" = 3;
        "browser.discovery.enabled" = false;
        "browser.formfill.enable" = false;
        "browser.newtabpage.enabled" = false;
        "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        "browser.newtabpage.activity-stream.feeds.topsites" = false;
        "browser.newtabpage.activity-stream.showSearch" = false;
        "browser.newtabpage.activity-stream.showSponsored" = false;
        "browser.newtabpage.activity-stream.showWeather" = false;
        "browser.search.suggest.enabled" = false;
        "browser.shell.checkDefaultBrowser" = false;
        "browser.contentblocking.category" = "strict";
        "browser.urlbar.suggest.bookmark" = false;
        "browser.urlbar.suggest.engines" = false;
        "browser.urlbar.suggest.history" = false;
        "browser.urlbar.suggest.openpage" = false;
        "browser.urlbar.suggest.searches" = false;
        "browser.urlbar.suggest.topsites" = false;
        "dom.security.https_only_mode" = true;
        "general.autoScroll" = false;
        "layout.css.always_underline_links" = true;
        "layout.spellcheckDefault" = 0;
        "media.autoplay.default" = 5;
        "network.dns.disablePrefetch" = true;
        "network.prefetch-next" = false;
        "network.trr.mode" = 3;
        "network.trr.uri" = "https://dns.quad9.net/dns-query";
        "places.history.enabled" = false;
        "privacy.donottrackheader.enabled" = true;
        "privacy.fingerprintingProtection" = true;
        "privacy.globalprivacycontrol.enabled" = true;
        "privacy.trackingprotection.enabled" = true;
        "privacy.trackingprotection.emailtracking.enabled" = true;
        "privacy.trackingprotection.socialtracking.enabled" = true;
        "signon.rememberSignons" = false;
        "sidebar.verticalTabs" = true;
        "sidebar.revamp" = true;
        "toolkit.telemetry.enabled" = false;
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.usage.uploadEnabled" = false;
        "app.normandy.enabled" = false;
        "app.shield.optoutstudies.enabled" = false;
        "extensions.pocket.enabled" = false;
        "privacy.firstparty.isolate" = true;
        "geo.enabled" = false;
        "browser.send_pings" = false;
      };
    };
  };
}
