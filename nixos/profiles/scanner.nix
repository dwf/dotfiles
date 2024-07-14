# Notes to self:
# - Scan documents from document feeder with
#
#     scanimage --batch=temporary-files-%02d.png -y 279.4 --resolution 300
#
# -y 279.4 sets the virtual scan area to Letter size where the default
# is Legal. Scanning directly to PDF results in a malformed pdf file not
# processable by ghostscript (invoked by ocrmypdf).
#
# - Use ImageMagick to convert to PDF:
#
#     convert temporary-files-*.png out.pdf
#
#   And then
#
#     ocrmypdf -i -r -d -O 3 out.pdf final.pdf
{ lib, pkgs, ... }:
let
  brscan4-supported = builtins.elem pkgs.system [ "i686-linux" "x86_64-linux" ];
in
{
  hardware.sane = {
    enable = true;

    # The official driver only supports i686 and x86_64
    brscan4 = lib.mkIf brscan4-supported {
      enable = true;
      netDevices.dcpl2540dw = {
        model = "DCP-L2540DW";
        ip = "192.168.2.12";
      };
    };

    # Fall back on sane-airscan driverless scanning.
    # Does not support lineart mode or duplex ADF scanning.
    extraBackends = lib.optionals (!brscan4-supported) [ pkgs.sane-airscan ];
  };
}
