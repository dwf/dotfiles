{
  programs.git = {
    enable = true;
    delta.enable = true;
    userName = "David Warde-Farley";
    userEmail = builtins.concatStringsSep "@" [
      "dwf"
      (builtins.concatStringsSep "." [
        "google"
        "com"
      ])
    ];
    aliases = {
      ca = "commit -a";
      co = "checkout";
      st = "status -a";
      ap = "add -p";
      ff = "merge --ff-only";
      record = "add -p";
      pop = "stash pop";
      shelve = "stash";
      unshelve = "stash pop";
    };
    ignores = [
      ".*.swp"
      "tags"
      ".ropeproject"
      ".netrwhist"
    ];
  };
}
