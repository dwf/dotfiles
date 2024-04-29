{
  config = {
    highlight.ExtraWhitespace.ctermbg = "red";
    autoCmd = [
      {
        event = "InsertEnter";
        command = "match ExtraWhitespace /\\s\\+\\%#\\@<!$/";
        pattern = "*";
      }
      {
        event = "InsertLeave";
        command = "match ExtraWhitespace /\\s\\+$/";
        pattern = "*";
      }
    ];
  };
}
