{ pkgs, ... }:
{
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.dejavu-sans-mono
    nerd-fonts.symbols-only
  ];

  # xdg.configFile."fontconfig/conf.d/10-nerd-font-symbols.conf".text = ''
  #   <?xml version="1.0"?>
  #   <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
  #   <fontconfig>
  #     <alias>
  #       <family>monospace</family>
  #       <prefer><family>Symbols Nerd Font Mono</family></prefer>
  #     </alias>
  #     <alias>
  #       <family>sans-serif</family>
  #       <prefer><family>Symbols Nerd Font</family></prefer>
  #     </alias>
  #     <alias>
  #       <family>serif</family>
  #       <prefer><family>Symbols Nerd Font</family></prefer>
  #     </alias>
  #   </fontconfig>
  # '';

  programs.waybar = {
    enable = true;

    settings.mainBar = {
      layer = "top";
      position = "top"; # niri's default config spawns waybar at the top; change to "bottom" if you prefer
      height = 26;
      spacing = 4;

      modules-left = [
        "niri/workspaces"
        "niri/window"
      ];
      modules-center = [ "clock" ];
      modules-right = [
        "network"
        "pulseaudio"
        "cpu"
        "memory"
        "battery"
        "tray"
      ];

      "niri/workspaces" = {
        format = "{icon}";
        format-icons = {
          active = "󰝥";
          focused = "󰝥";
          default = "󰝦";
          urgent = "󰀨";
        };
      };

      "niri/window" = {
        format = "{}";
        max-length = 60;
        separate-outputs = true;
      };

      clock = {
        format = "󰅐  {:%a %d/%m  %R}";
        tooltip-format = "<tt><small>{calendar}</small></tt>";
      };

      network = {
        format-wifi = "󰖩  {essid}";
        format-ethernet = "󰈀  {ifname}";
        format-disconnected = "󰤭  offline";
        tooltip-format = "{ifname}  {ipaddr}";
        on-click = "";
      };

      pulseaudio = {
        format = "{icon}  {volume}%";
        format-muted = "󰝟  muted";
        format-icons.default = [
          "󰕿"
          "󰖀"
          "󰕾"
        ];
        on-click = "pavucontrol"; # or wpctl / your mixer of choice
      };

      cpu = {
        format = "󰻟  {usage}%";
        interval = 5;
      };

      memory = {
        format = "󰍛  {percentage}%";
        interval = 5;
      };

      # Remove this whole block on a desktop with no battery.
      battery = {
        format = "{icon}  {capacity}%";
        format-charging = "󰂄  {capacity}%";
        format-icons = [
          "󰁺"
          "󰁼"
          "󰁾"
          "󰂀"
          "󰂂"
        ];
        states = {
          warning = 30;
          critical = 15;
        };
      };

      tray = {
        icon-size = 16;
        spacing = 8;
      };
    };

    # tokyonight (night)
    style = ''
      * {
        font-family: "DejaVuSansM Nerd Font", "Symbols Nerd Font", "Symbols Nerd Font Mono", monospace;
        font-size: 9pt;
        font-weight: normal;
        min-height: 0;
      }

      window#waybar {
        background: transparent;
        color: #c0caf5;
      }

      /* Each cluster of modules floats as its own rounded pill. */
      .modules-left,
      .modules-center,
      .modules-right {
        background-color: rgba(26, 27, 38, 0.92); /* #1a1b26 */
        border-radius: 10px;
        margin: 4px 6px 0 6px;
        padding: 0 4px;
      }

      #workspaces button {
        padding: 0 7px;
        margin: 3px 2px;
        color: #565f89;              /* muted / comment */
        background: transparent;
        border-radius: 8px;
        transition: all 0.2s ease;
      }
      #workspaces button:hover {
        color: #c0caf5;
        background-color: #292e42;
      }
      #workspaces button.active,
      #workspaces button.focused {
        color: #1a1b26;
        background-color: #7aa2f7;   /* blue */
      }
      #workspaces button.urgent {
        color: #1a1b26;
        background-color: #f7768e;   /* red */
      }

      #window   { color: #7dcfff; padding: 0 8px; }  /* cyan */
      #clock    { color: #bb9af7; padding: 0 9px; }  /* purple */
      #network  { color: #9ece6a; padding: 0 8px; }  /* green */
      #pulseaudio { color: #e0af68; padding: 0 8px; } /* yellow */
      #cpu      { color: #7dcfff; padding: 0 8px; }
      #memory   { color: #bb9af7; padding: 0 8px; }
      #battery  { color: #9ece6a; padding: 0 8px; }
      #battery.warning  { color: #ff9e64; }           /* orange */
      #battery.critical { color: #f7768e; }           /* red */
      #tray     { padding: 0 8px; }

      /* Collapse the window title pill when nothing is focused. */
      window#waybar.empty #window { background: transparent; padding: 0; }

      tooltip {
        background-color: #1a1b26;
        border: 1px solid #7aa2f7;
        border-radius: 8px;
      }
      tooltip label { color: #c0caf5; }
    '';
  };
}
