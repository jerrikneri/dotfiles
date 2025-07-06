# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # Bootloader.
  boot = {
    # initrd.kernelModules = [ "zfs" ];
    loader = {
      efi.canTouchEfiVariables = true;
      # grub = {
      #   enable = true;
      #   device = "/dev/sda";
      # };
      systemd-boot.enable = true;
    };
    supportedFilesystems = [ "zfs" ];
    zfs.forceImportRoot = false;
  };

  boot.kernelModules = [ "amdgpu" "zfs" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Common packages - /modules/common/packages/index.nix
  # NixOS only packages here
  environment.sessionVariables = {
    MANGOHUD = "1";
    VKBASALT_CONFIG_FILE = "/etc/vkBasalt.conf";
  };
  environment.systemPackages = with pkgs; [
    disko
    zfs
  ];

  hardware = {
    enableAllFirmware = true;
    enableRedistributableFirmware = true;
    graphics = {
      enable = true;
      enable32Bit = true;
    };
  };

  # Allow home manager to symlink and backup when there are conflicts / existing files.
  home-manager.backupFileExtension = "backup";
  home-manager.users.kgh = {
    imports = [
      ../../modules/common/home.nix
      # ../../modules/common/font.nix
    ];
    home.stateVersion = "25.11";
  };

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_US.UTF-8";
    extraLocaleSettings = {
        LC_ADDRESS = "en_US.UTF-8";
        LC_IDENTIFICATION = "en_US.UTF-8";
        LC_MEASUREMENT = "en_US.UTF-8";
        LC_MONETARY = "en_US.UTF-8";
        LC_NAME = "en_US.UTF-8";
        LC_NUMERIC = "en_US.UTF-8";
        LC_PAPER = "en_US.UTF-8";
        LC_TELEPHONE = "en_US.UTF-8";
        LC_TIME = "en_US.UTF-8";
      };
  };

  imports =
    [
      # Include the results of the hardware scan.
      #
      ../../disko/zfs.nix
      ./hardware-configuration.nix
      ../../modules/common/font.nix
    ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking = {
    firewall = {
      enable = true;
      allowedTCPPorts = [ 47984 47989 47990 48010 ]; # sunshine
      allowedUDPPortRanges = [
        { from = 47998; to = 48000; }
        #{ from = 8000; to = 8010; }
      ];
    };
    hostName = "nixos"; # Define your hostname.
    hostId = "899d5514";

    # Enable networking
    networkmanager.enable = true;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Experimental flags
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.allowUnsupported = true;
  # nixpkgs.config.allowUnsupportedSystem = true;
  nixpkgs.config.rocmSupport = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  # /modules/common/programs.nix
  # programs.alacritty.enabled = true; -- Not supported here
  programs.gamemode.enable = true;
  programs.neovim.enable = true;
  programs.zsh.enable = true;

  # List services that you want to enable:
  services = {
    avahi = {
      publish = {
        enable = true;
        userServices = true;
      };
    };

    desktopManager = {
      # Gnome
      # gnome.enable = true;

      # KDE
      plasma6.enable = true;
    };

    displayManager = {
      autoLogin.enable = true;
      autoLogin.user = "kgh";
      # Set your display manager (login screen)
      # gdm.enable = true;
    };

    openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";       # Change to "yes" if you really want root SSH login (not recommended).
        PasswordAuthentication = false; # Use keys instead of passwords.
        PermitEmptyPasswords = false;
      };
    };

    xserver = {
      # Enable the X server (for graphical display)
      enable = true;

      videoDrivers = [ "amdgpu" ];
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "";
      };
    };

    zfs = {
      autoScrub.enable = true;
      autoSnapshot.enable = true;
      trim.enable = true;
    };
  };

  systemd.services.sunshine = {
    description = "Sunshine game streaming server";
    wantedBy = [ "default.target" ];
    serviceConfig = {
      ExecStart = "${pkgs.sunshine}/bin/sunshine";
      Restart = "on-failure";
      Environment = "DISPLAY=:0";
      # add WAYLAND_DISPLAY if using Wayland
    };
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  security.wrappers.sunshine = {
    owner = "root";
    group = "root";
    capabilities = "cap_sys_admin+p";
    source = "${pkgs.sunshine}/bin/sunshine";
  };


  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kgh = {
    description = "kgh";
    extraGroups = [
      "docker"
      "input"
      "kgh"
      "kvm"
      "networkmanager"
      "render"
      "video"
      "wheel"
    ];
    home = "/home/kgh";
    isNormalUser = true;
    packages = with pkgs; [];
    shell = pkgs.zsh;

    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIP5OPJM1PPOSi9TXVTBQ0EgZtwXlXpiKr7yUYmvyjY29"
    ];
  };

  virtualisation.docker.enable = true;
}
