{
  nixpkgs.overlays = [

    (_: prev: {
      taglib = prev.taglib.overrideAttrs rec {
        version = "2.0.2";
        src = prev.fetchFromGitHub {
          owner = "taglib";
          repo = "taglib";
          rev = "v${version}";
          hash = "sha256-3cJwCo2nUSRYkk8H8dzyg7UswNPhjfhyQ704Fn9yNV8=";
        };
        buildInputs = with prev; [ utf8cpp ];
      };
    })
  ];
}
