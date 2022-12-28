{ config, lib, pkgs, ... }:
with lib;
let
  cfg = config.services.auto-abcde;
  mkEnableTrue = (description: mkOption {
    inherit description;
    type = types.bool;
    default = true;
    example = false;
  });
in
{
  options.services.auto-abcde = {
    enable = mkEnableOption "Auto-ripping with abcde.";
    cddbMethod = mkOption {
      type = types.enum [ "musicbrainz" "cddb" ];
      default = "musicbrainz";
      example = "cddb";
      description = "CDDB method used to retrieve track information.";
    };
    actions = mkOption {
      type = types.str;
      default = "default,playlist,getalbumart,read,encode,tag,move,clean";
      example = "default,playlist,read,encode,tag,move,clean";
      description = "Sequence of actions to perform.";
    };
    flacOpts = mkOption {
      type = types.str;
      default = "-s -e -V -8";
      example = "-s -e -V -6";
      description = "Options passed to FLAC encoder.";
    };
    outputType = mkOption {
      type = types.str;  # with types; listOf enum...
      default = "flac";
      example = "flac";
      description = "Output types.";
    };
    outputPath = mkOption {
      type = types.path;
      example = "/mnt/media/Music";
      description = "Output directory for encoded music.";
    };
    # TODO(dwf): expose CDROMREADERSYNTAX, format strings.
    maxEncoderProcesses = mkOption {
      type = types.int;
      default = 4;
      example = 16;
      description = "Maximum number of encoder processes.";
    };
    padTracks = mkEnableTrue "Left pad track numbers with zeros.";
    eject = mkEnableTrue "Eject CD when finished.";
  };

  config = mkIf cfg.enable {
    services.udev = {
      extraRules = let
        boolYN = (b: if b then "y" else "n");
        abcdeConfigFile = let
          OUTPUTFORMAT="\${OUTPUT}/\${ARTISTFILE}/\${ALBUMFILE}/\${TRACKNUM} \${TRACKFILE}";
          VAOUTPUTFORMAT="\${OUTPUT}/Various Artists/\${ALBUMFILE}/\${TRACKNUM} \${ARTISTFILE} - \${TRACKFILE}";
          ONETRACKOUTPUTFORMAT="\${OUTPUT}/\${ARTISTFILE}/\${ALBUMFILE}/\${ALBUMFILE}";
          VAONETRACKOUTPUTFORMAT="\${OUTPUT}/Various Artists/\${ALBUMFILE}/\${ALBUMFILE}";
          PLAYLISTFORMAT="\${OUTPUT}/\${ARTISTFILE}/\${ALBUMFILE}/\${ALBUMFILE}.m3u";
          VAPLAYLISTFORMAT="\${OUTPUT}/Various Artists/\${ALBUMFILE}/\${ALBUMFILE}.m3u";
          configText = ''
            INTERACTIVE=n
            FLACENCODERSYNTAX=flac
            FLAC=flac
            CDROMREADERSYNTAX=cdparanoia

            OUTPUTFORMAT='${OUTPUTFORMAT}'
            VAOUTPUTFORMAT='${VAOUTPUTFORMAT}'
            ONETRACKOUTPUTFORMAT='${ONETRACKOUTPUTFORMAT}'
            VAONETRACKOUTPUTFORMAT='${VAONETRACKOUTPUTFORMAT}'
            PLAYLISTFORMAT='${PLAYLISTFORMAT}'
            VAPLAYLISTFORMAT='${VAPLAYLISTFORMAT}'
            mungefilename ()
            {
              echo "$@" | sed -e 's/^\.*//' | tr -d ":><|*/\"'?[:cntrl:]"
            }
            EXTRAVERBOSE=2
            COMMENT='${replaceStrings [ "/nix/store/" ] [ "" ] (toString pkgs.abcde)}'
            EJECTCD=${boolYN cfg.eject}
            MAXPROCS=${toString cfg.maxEncoderProcesses}
            PADTRACKS=${boolYN cfg.padTracks}
            OUTPUTDIR='${cfg.outputPath}'
            FLACOPTS='${cfg.flacOpts}'
            OUTPUTTYPE=flac
            WAVOUTPUTDIR=/tmp
          '';
        in pkgs.writeTextFile {
          name = "abcde.conf";
          text = configText;
        };
        abcdeScript = let
          rootPath = "/run/wrappers/bin:/root/.nix-profile/bin:/etc/profiles/per-user/root/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
        in pkgs.writeShellScript "rip.sh" ''
          if [ "$ID_CDROM_MEDIA_CD" == "1" ]; then
            cd /tmp
            # udev's sandbox forbids network access. Get around this by scheduling the rip with `at`.
            # TODO(dwf): Don't run as root; use su and set up an appropriate user.
            echo 'PATH=${rootPath} ${pkgs.abcde}/bin/abcde -c ${abcdeConfigFile} 2>&1 |tee /var/log/auto-abcde.log' | ${pkgs.at}/bin/at now
          fi
        '';
      in
      ''
        ACTION=="change", SUBSYSTEM=="block", RUN+="${abcdeScript}"
      '';
    };

    services.atd.enable = true;

  };
}
