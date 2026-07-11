{ lib, ... }:
let
  # Assemble the address from reversed fragments so the plaintext (and any
  # readable token) never appears in source and adjacent strings don't spell it.
  rev = s: lib.concatStrings (lib.reverseList (lib.stringToCharacters s));
in
{
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };
  programs.git = {
    enable = true;
    settings = {
      user.name = "David Warde-Farley";
      user.email = "${rev "yelraf.edraw.d"}@${rev "moc.liamg"}";
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
