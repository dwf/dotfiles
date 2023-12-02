{ lib, ... }: {
  programs.i3status-rust.bars.bottom.blocks = lib.mkAfter [
    {
      block = "battery";
      interval = 30;
    }
  ];
}
