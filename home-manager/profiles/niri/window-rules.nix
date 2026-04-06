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
      default-column-width = {
        proportion = 0.5;
      };
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
    {
      matches = [
        {
          app-id = "^steam$";
        }
      ];
      open-maximized = true;
    }
  ];
}
