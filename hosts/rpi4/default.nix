{ pkgs, ... }: 

let

  sources = import ../../sources.nix;

in

{

  imports = [
    # services
    ../../services/k3s
    ../../services/tailscale

    # users
    ../../users/rj

    # networking configuration
    ./network.nix

    # system-wide programs
    ../../programs/neovim
    ../../programs/starship
    ../../programs/tmux
    ../../modules/podman.nix

    # nix configuration
    ../../nix

    # external modules
    "${sources.agenix}/modules/age.nix"
    "${sources.nixos-hardware}/raspberry-pi/4"
  ];

  # set hostname
  networking.hostName = "rpi4";

  # enable SSH
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # allow sudo without password for %wheel
  security.sudo.wheelNeedsPassword = false;

  # This is a config that uses 23.11 state where relevant
  system.stateVersion = "23.11";

  hardware.enableRedistributableFirmware = true;

  # configure as a grub-based EFI install
  boot.loader.generic-extlinux-compatible.enable = false;
  boot.loader.grub.enable = true;
  boot.loader.grub.efiSupport = true;
  boot.loader.grub.efiInstallAsRemovable = true;
  boot.loader.grub.device = "nodev";
  boot.loader.efi.canTouchEfiVariables = false;

  # use the upstream (not rpi) kernel
  boot.kernelPackages = pkgs.linuxPackages;

  # allow USB HID and storage (latter required as the system drive is connected via USB) in initrd
  boot.initrd.availableKernelModules = [ "usbhid" "usb_storage" "uas" ];

  # clean /tmp on boot
  boot.tmp.cleanOnBoot = true;

  # do not enable hibernation
  boot.kernelParams = [
    "nohibernate"
  ];

  # enable bluetooth
  hardware.bluetooth.enable = true;

  # open firewall on web and syncthing ports (services are in containers so not automatic)
  networking.firewall.allowedTCPPorts = [ 80 443 22000 ];
  networking.firewall.allowedUDPPorts = [ 443 21027 22000 ];

  # allow unprivileged user to listen to ports >= 80 (to allow caddy container to run as user)
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 80;

  # fully spin up Argon One case fan on boot
  systemd.services."argon-one-fan-spindown" = {
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${pkgs.i2c-tools}/bin/i2cset -y 1 0x1a 100";
    };
  };

  # configure root on USB-attached SSD, /boot on microSD
  fileSystems = {
    "/" = {
      device = "/dev/disk/by-label/NIXOS_SD";
      fsType = "ext4";
    };
    "/boot" = {
      device = "/dev/disk/by-label/ESP";
      fsType = "vfat";
    };
  };

  # configure zram swap with the default limit of 50% physical RAM
  zramSwap.enable = true;

  # configure some swap-related memory parameters to take advantage of the speed of zram
  # - stolen from https://wiki.archlinux.org/title/Zram#Optimizing_swap_on_zram
  boot.kernel.sysctl = {
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # add agenix to PATH
  environment.systemPackages = with pkgs; [
    (pkgs.callPackage "${sources.agenix}/pkgs/agenix.nix" {})
  ];

}
