{ config, pkgs, ... }:

{
  environment.systemPackages = [ pkgs.sunshine ];

  networking.firewall = {
    allowedTCPPorts = [ 47984 47989 47990 48010 ];
    allowedUDPPortRanges = [
      { from = 47998; to = 48000; }
    ];
  };

  services.pipewire.extraConfig.pipewire."92-sunshine-virtual-sink" = {
    "context.modules" = [
      {
        name = "libpipewire-module-combine-stream";
        args = {
          "combine.mode" = "sink";
          "node.name" = "SunshineSink";
          "node.description" = "Sunshine Virtual Sink";
          "stream.rules" = [
            {
              matches = [ { "media.class" = "Audio/Sink"; } ];
              actions = { create-stream = { }; };
            }
          ];
        };
      }
    ];
  };

  systemd.services.sunshine = {
    description = "Sunshine self-hosted game stream host for Moonlight";
    wantedBy = [ "graphical.target" ];
    after = [ "network.target" "graphical.target" ];
    serviceConfig = {
      ExecStart = "/run/wrappers/bin/sunshine";
      Restart = "always";
      RestartSec = "5s";
      User = "kgh";
      Environment = [
        "DISPLAY=:0"
        "WAYLAND_DISPLAY=wayland-0"
        "XDG_SESSION_TYPE=wayland"
        "XDG_RUNTIME_DIR=/run/user/1000"
        "DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/1000/bus"
      ];
    };
  };

  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };
}
