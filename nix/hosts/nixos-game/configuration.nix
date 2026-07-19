# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  # 9800X3D (8c/16t) + 32GB RAM
  nix.settings = {
    max-jobs = 4;
    cores = 8;
  };

  # Bootloader.
  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      # grub = {
      #   enable = true;
      #   device = "/dev/sda";
      # };
      systemd-boot.enable = true;
    };
  };

  boot.kernelModules = [ "amdgpu" ];
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.kernelParams = [
    "amdgpu.ppfeaturemask=0xffffffff"
    "video=HDMI-A-1:1920x1080@60e"
  ];

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # Common packages - /modules/common/packages/index.nix
  # NixOS only packages here
  environment.sessionVariables = {
    MOZ_ENABLE_WAYLAND = "1";   # Firefox
    QT_QPA_PLATFORM = "wayland"; # Qt apps
    SDL_VIDEODRIVER = "wayland"; # SDL games
    VKBASALT_CONFIG_FILE = "/etc/vkBasalt.conf";
  };
  environment.systemPackages = with pkgs; [
    ethtool
    gcc
    gnumake # compile DOOM
    rocmPackages.rocm-smi # System Management Interface for AMD GPU
    # rtw89-unstable
    vulkan-tools
  ];

  fileSystems."/mnt/games" = {
    device = "/dev/disk/by-uuid/90bea1e5-871a-4e58-b092-1be923a95b96";
    fsType = "ext4";
    options = [ "defaults" ];
  };


  hardware = {
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
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
      ./hardware-configuration.nix
      ../../modules/common/font.nix
      ../../modules/common/sunshine.nix
    ];

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;
  networking = {
    firewall = {
      enable = true;
    };
    hostName = "nixos"; # Define your hostname.

    interfaces.enp10s0.wakeOnLan.enable = true;
    interfaces.enp7s0.wakeOnLan.enable = true;

    # Enable networking
    networkmanager.enable = true;
  };

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

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
  programs.kdeconnect.enable = true;
  programs.neovim.enable = true;
  programs.nix-ld.enable = true;
  programs.zsh.enable = true;

  # List services that you want to enable:
  services = {
    avahi = {
      publish = {
        enable = true;
        userServices = true;
      };
    };

    blueman.enable = true;

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

    gnome.gnome-keyring.enable = true;

    openssh = {
      enable = true;
      settings = {
        KbdInteractiveAuthentication = false;
        PermitRootLogin = "no";       # Change to "yes" if you really want root SSH login (not recommended).
        PasswordAuthentication = false; # Use keys instead of passwords.
        PermitEmptyPasswords = false;
      };
    };

    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
      jack.enable = true;
      audio.enable = true;
    };

    pulseaudio.enable = false;

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
  };

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";


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
      "audio"
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

  xdg.portal.enable =true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
}
