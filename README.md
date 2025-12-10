# zen-browser-flake (auto-update)


This repository contains a Nix flake packaging Zen Browser as a wrapped binary. It uses `nvfetcher` to fetch release tarballs and GitHub Actions to keep `generated.nix` up-to-date.


## Usage


Build locally:


```bash
nix build
# or
nix build .#defaultPackage

Install to your user profile (example):
nix profile install .#defaultPackage

Run the GUI app via your launcher (zen), or launch directly:
zen