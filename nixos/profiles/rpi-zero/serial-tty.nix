{ lib, pkgs, ... }: {
  boot = {
    # Bizarrely I can only manage to get a serial console working on the stock
    # kernel, not the Raspberry Pi kernel. I tried messing with the contents of
    # the boot partition, config.txt, various ways of applying overlays, etc.
    # The stock kernel plus this patch just works.
    kernelPackages = lib.mkForce pkgs.linuxPackages_6_3;

    # Compiling dwc2 and g_serial as modules seems to obviate obtaining
    # messages during the boot process. Also, spawning a tty on ttyGS0
    # didn't work properly if the USB cable had been plugged in since boot
    # powering the Pi, unless I ssh'ed in and restarted the serial-getty,
    # which defeats the purpose of having a serial console at all.
    #
    # The config below gets us all the boot messages and an automatic
    # tty at the end of it. I got the idea from the very helpful page at
    # https://wiki.postmarketos.org/index.php?title=Serial_debugging/Serial_gadget
    kernelParams = [ "console=ttyGS0,115200" "console=tty1" ];
    kernelPatches = [
      {
        name = "otg-serial";
        patch = null;
        extraConfig = ''
          USB_GADGET y
          USB_DWC2 y
          USB_DWC2_DUAL_ROLE y
          USB_G_SERIAL y
          USB_U_SERIAL y
          U_SERIAL_CONSOLE y
        '';
      }
    ];
  };
}
