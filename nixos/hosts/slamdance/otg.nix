{ lib, pkgs, ... }:
{
  systemd.targets.getty.wants = [
    "serial-getty@ttyGS0.service"
  ];
  boot.kernelPackages = lib.mkForce pkgs.linuxPackages_rpi0;

  boot.kernelParams = [
    "dwc_otg.lpm_enable=0"
  ];
  services.getty.autologinUser = lib.mkDefault "root";

  boot.kernelPatches = [
    {
      name = "otg-serial-console";
      patch = null;
      extraConfig = ''
        USB_GADGET y
        USB_DWC2 m
        USB_DWC2_DUAL_ROLE y
        USB_G_SERIAL m
      '';
    }
  ];
  boot.kernelModules = [ "dwc2" "g_serial" ];

  hardware.deviceTree.enable = true;
  hardware.deviceTree.name = "bcm2835-rpi-zero-w.dtb";
  hardware.deviceTree.filter = "bcm2835-rpi-zero-w.dtb";
  hardware.deviceTree.overlays = [
    {
      name = "dwc2_overlay_git";
      dtsText =  # From https://github.com/raspberrypi/linux/blob/rpi-5.15.y/arch/arm/boot/dts/overlays/dwc2-overlay.dts
      # The "compatible" string starts as "brcm,bcm2835" but this fails to apply.
      # Changing it to "bcm2835-rpi-zero-w" or "bcm2835*" makes the overlay apply.

      # With the Raspberry Pi kernel this blob renders the system unbootable,
      # and with the mainline kernel this doesn't do anything.
      ''
        /dts-v1/;
        /plugin/;

        /{
                compatible = "brcm,bcm2835-rpi-zero-w";

                fragment@0 {
                        target = <&usb>;
                        #address-cells = <1>;
                        #size-cells = <1>;
                        dwc2_usb: __overlay__ {
                                compatible = "brcm,bcm2835-usb";
                                dr_mode = "otg";
                                g-np-tx-fifo-size = <32>;
                                g-rx-fifo-size = <558>;
                                g-tx-fifo-size = <512 512 512 512 512 256 256>;
                                status = "okay";
                        };
                };

                __overrides__ {
                        dr_mode = <&dwc2_usb>, "dr_mode";
                        g-np-tx-fifo-size = <&dwc2_usb>,"g-np-tx-fifo-size:0";
                        g-rx-fifo-size = <&dwc2_usb>,"g-rx-fifo-size:0";
                };
        };
      '';
    }
  ];

  # Generated with (fixing up "compatible" string)
  #
  #   nix run nixpkgs#dtc -- -I dtb -O dts /nix/store/wziyfww28fn8pvamvsxynphjhc6rm18l-linux-5.15.32-1.20220331/dtbs/overlays/dwc2.dtbo
  #
  # Almost the same, with __symbols__, __fixups__, and __local_fixups__
  # sections, a 'phandle' thing under __overlay__, and __overrides__ has
  # a bunch of numbers instead of text labels.
  #
  # hardware.deviceTree.overlays = [
  #   {
  #     name = "dwc2";
  #     dtsText = ''
  #       /dts-v1/;

  #       / {
  #               compatible = "bcm2835-rpi-zero-w";

  #               fragment@0 {
  #                       target = <0xffffffff>;
  #                       #address-cells = <0x01>;
  #                       #size-cells = <0x01>;

  #                       __overlay__ {
  #                               compatible = "brcm,bcm2835-usb";
  #                               dr_mode = "otg";
  #                               g-np-tx-fifo-size = <0x20>;
  #                               g-rx-fifo-size = <0x22e>;
  #                               g-tx-fifo-size = <0x200 0x200 0x200 0x200 0x200 0x100 0x100>;
  #                               status = "okay";
  #                               phandle = <0x01>;
  #                       };
  #               };

  #               __overrides__ {
  #                       dr_mode = <0x01 0x64725f6d 0x6f646500>;
  #                       g-np-tx-fifo-size = <0x01 0x672d6e70 0x2d74782d 0x6669666f 0x2d73697a 0x653a3000>;
  #                       g-rx-fifo-size = [00 00 00 01 67 2d 72 78 2d 66 69 66 6f 2d 73 69 7a 65 3a 30 00];
  #               };

  #               __symbols__ {
  #                       dwc2_usb = "/fragment@0/__overlay__";
  #               };

  #               __fixups__ {
  #                       usb = "/fragment@0:target:0";
  #               };

  #               __local_fixups__ {

  #                       __overrides__ {
  #                               dr_mode = <0x00>;
  #                               g-np-tx-fifo-size = <0x00>;
  #                               g-rx-fifo-size = <0x00>;
  #                       };
  #               };
  #       };
  #       
  #     '';
  #   }
  # ];
}
