# MerPkgs

🧜‍♀️ My nix package repository for when I don't want to deal with nixpkgs maintainers bullshit.

Includes packages and modules such as catask and buttui, as well as beta or alternative versions of nixpkgs packages. See full list below. These are here for my own use and made public in the hope that they may be useful, but everything is provided with no warranty at all. Use at your own risk.

## Adding to NixOS

These are packaged here for my own use and made public in the hope that they may be useful, but all modules, packages and everything else here are packaged with no warranty at all. Use at your own risk.

Add merpkgs to your flake's inputs:

```nix
inputs = {
  # ...
  
  merpkgs = {
    url = "github:LuNeder/merpkgs";
    inputs.nixpkgs.follows = "nixpkgs";
  };
};
```

Then, on your `configuration.nix` (or similar) add the merpkgs overlay:

```nix
nixpkgs.overlays = [
  inputs.merpkgs.overlays.default

  # your other overlays here, if any
];
```

Packages will now be available under `pkgs.merpkgs`, for example:

```nix
environment.systemPackages = [
  # ...
  pkgs.merpkgs.buttui
];
```

For the NixOS modules, you make all of them available in your configuration by importing `builtins.attrValues inputs.merpkgs.nixosModules` in your config, for example:

```nix
imports = [
  ./hardware-configuration.nix
  # ...
] ++ (builtins.attrValues inputs.merpkgs.nixosModules);
```

Modules will then usually be under the `merpkgs` name, such as:

```nix
merpkgs.services.catask = {
  enable = true;
  listenAddress = "[::]";
  port = 8220;
  openFirewall = true;
  dotenvPath = config.sops.templates."cataskenv".path;
  configPath = config.sops.templates."cataskcfg".path;
};
```

Similarly, for Home Manager modules (tho none are available yet!):

```nix
imports = [
  ./hardware-configuration.nix
  # ...
  ] ++ (builtins.attrValues inputs.merpkgs.nixosModules) ++
  (builtins.attrValues inputs.merpkgs.homeModules)
;
```

## Package list

- [`buttui`](https://buttui.de/): Terminal UI for [buttplug.io](https://buttplug.io) compatible devices
- [`catask`](https://catask.org/): CatAsk is a simple & easy to use Q&A software. (Here temporarily until I get back to the nixpkgs PR)
- More to come soon!

## NixOS modules list

- `merpkgs.services.catask`
- More to come soon!

## Special thanks

As usual, tysm Gabs GELOS for helping me and making the [base flake](https://github.com/Misterio77/exemplo-lu) for this!!