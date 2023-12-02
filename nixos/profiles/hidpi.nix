{
  services.xserver.displayManager.lightdm.greeters.gtk = {
    # Fix for tiny cursor on HiDPI display in the display manager.
    # There's a separate fix in home config for once we're logged in.
    cursorTheme.size = 32;
    extraConfig = "xft-dpi = 192";
  };
}
