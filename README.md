# dwf's dotfiles

This repository contains public Nix configurations for my systems and home
directories.

`nixos/` contains (some of) my [NixOS][2] machine configurations, while
`home-manager/` contains my home directory configuration, managed with
(naturally) [Home Manager][1]. Note that these configurations are _not_
managed as part of the NixOS configuration.

This repository is a [flake][3]. My goal is to expose things I imagine as being
independently useful. Right now that includes the following under
`nixosModules`:

| Flake target              |Description                                                                                     |
|---------------------------|------------------------------------------------------------------------------------------------|
|`hardware.macbook-pro-11-1`|Hardware profile customizing NixOS to my laptop, a `MacBookPro11,1` (Retina display, late 2014).|


I rebuild my NixOS system configurations with

    sudo nixos-rebuild switch --flake .

And my managed home directory with

    home-manager switch --flake .

## Acknowledgements

* [@shazow][4] for pushing me down the NixOS garden path, and nagging me until
  I cleaned them up for public consumption.
* [@mgdm][5] for elegantly [reimplementing the fan control daemon][6] for the
  Raspberry Pi 4 case I use, so that I didn't have to wrestle with the
  manufacturer's inscrutable shell script.
* All the contributors to the NixOS and Home Manager projects.
* All the people who've put their Nix configurations on GitHub, from which I've
  learned much.

[1]: https://github.com/nix-community/home-manager
[2]: https://nixos.org/
[3]: https://nixos.wiki/wiki/Flakes
[4]: https://github.com/shazow
[5]: https://github.com/mgdm
[6]: https://github.com/mgdm/argonone-utils
[7]: https://github.com/nixos/nixos-hardware
