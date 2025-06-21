# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ../../modules/common/font.nix
    ];

  # 🧩 GPU passthrough-specific additions begin here -------------------------

  # Enable IOMMU (important for Intel passthrough hosts)
  boot.kernelParams = [ "intel_iommu=on" "iommu=pt" ];

  # Enable necessary kernel modules
  boot.initrd.kernelModules = [
    "vfio"
    "vfio_pci"
    "vfio_virqfd"
    "vfio_iommu_type1"
  ];

  # Optional: Prevent amdgpu from loading if you don't want drivers bound at boot
  boot.blacklistedKernelModules = [
    "amdgpu"
    "radeon"
    "drm_kms_helper"
    "drm"
  ];

  # Tell the system to bind the GPU to vfio-pci (RX 480 and HDMI audio)
  # You can confirm these IDs with `lspci -nn` on the Proxmox host
  boot.extraModprobeConfig = ''
    options vfio-pci ids=1002:67df,1002:aaf0
  '';

  # Optional: if you'll use the GPU in the VM for graphics
  hardware.opengl.enable = true;
  hardware.opengl.driSupport = true;
  hardware.opengl.driSupport32Bit = true;
  services.xserver.videoDrivers = [ "amdgpu" ];

  # 🧩 End of passthrough additions -----------------------------------------

  virtualisation.docker.enable = true;

  home-manager.users.kgh = {
    imports = [
      ../../modules/common/home.nix
      # ../../modules/common/font.nix
    ];
    home.stateVersion = "25.11";
  };

  nixpkgs.config.allowUnfree = true;
  # nixpkgs.config.allowUnsupportedSystem = true;

  # Experimental flags
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # Bootloader.
  boot.loader.systemd-boot.enable = false;
  boot.loader.efi.canTouchEfiVariables = true;

  boot.loader.grub = {
    enable = true;
    device = "/dev/sda";
  };

  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Los_Angeles";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
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

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";       # Change to "yes" if you really want root SSH login (not recommended).
      PasswordAuthentication = false; # Use keys instead of passwords.
    };
  };

  services.qemuGuest.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.kgh = {
    isNormalUser = true;
    description = "kgh";
    extraGroups = [ "networkmanager" "wheel" "docker"];
    packages = with pkgs; [];
    shell = pkgs.zsh;
  };

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
   gcc
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
  # programs.alacritty.enabled = true; -- Not supported here
  programs.neovim.enable = true;
  programs.zsh.enable = true;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "25.05"; # Did you read the comment?

}
