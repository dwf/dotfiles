{
  # Use these defaults for bare metal machines.  Previously only applied to
  # desktop/laptop machines.
  fileSystems =
    let
      btrfsOptions = [
        "defaults"
        "compress=zstd"
        "noatime"
        "noautodefrag"
        "commit=100"
      ];
    in
    {
      "/".options = btrfsOptions;
      "/home".options = btrfsOptions;
    };

  boot.initrd.supportedFilesystems = [ "btrfs" ];

}
