{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  programs.git = {
    enable = true;
    settings = {
      user.name = "David Warde-Farley";
      user.email = builtins.concatStringsSep "@" [
        "dwf"
        (builtins.concatStringsSep "." [
          "google"
          "com"
        ])
      ];
      aliases = {
        ca = "commit -a";
        co = "checkout";
        s = "status";
        st = "status";
        ap = "add -p";
        ff = "merge --ff-only";
        record = "add -p";
        pop = "stash pop";
        shelve = "stash";
        unshelve = "stash pop";
      };
    };
    ignores = [
      ".*.swp"
      "tags"
      ".ropeproject"
      ".netrwhist"
    ];
  };
}
