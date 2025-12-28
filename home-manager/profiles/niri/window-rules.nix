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
    {
      matches = [
        {
          app-id = "^steam$";
          title = "^notificationtoasts.*$";
        }
      ];
      default-floating-position = {
        x = 25;
        y = 25;
        relative-to = "bottom-right";
      };
      open-focused = false;
    }
  ];
}
