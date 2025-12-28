{
  programs.niri.settings.window-rules = [
    {
      matches = [ ]; # Empty matches = all windows
      draw-border-with-background = false;
    }
    {
      matches = [
        { app-id = "Alacritty"; }
      ];
      open-maximized = true;
    }
  ];
}
