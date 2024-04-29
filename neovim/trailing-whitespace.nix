{
  config = {
    highlight.ExtraWhitespace.ctermbg = "red";
    autoCmd = [
      {
        event = "InsertEnter";
        command = "match ExtraWhitespace /\\s\\+\\%#\\@<!$/";
        pattern = "*";
      }
    ] ++
    (map (event:
    {
      inherit event;
      command = "match ExtraWhitespace /\\s\\+$/";
      pattern = "*";
    }) [ "InsertLeave" "BufReadPre" ]);
  };
}
