{
  config = {
    plugins.snacks = {
      enable = true;
      settings = {
        input.enabled = true;
        notifier.enabled = true;

        # Roughly mimic dressing.nvim
        styles.input = {
          relative = "cursor";
          row = -3;
          col = 0;
        };
      };
    };
  };
}
