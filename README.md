# Zen Browser (Nix flake)

This repository provides **Zen Browser** as a Nix flake, wrapping the official **prebuilt Linux binary** and integrating it cleanly into the Nix ecosystem (desktop entry, icon, auto-patchelf, and runtime dependencies).

The goal of this flake is **not** to build Zen Browser from source, but to:

* Track upstream binary releases automatically
* Provide a reproducible Nix package
* Make it easy to use from NixOS and Home Manager

---

## Release Tracking Policy

This flake tracks the **latest upstream release** of Zen Browser using `nvfetcher`.

* The upstream repository is checked on **Fridays at 00:00 (GMT)**
* If a new release is available at that time, the flake will reference the **newest binary**
* Version information is recorded in `_sources/generated.nix`

This means:

* The referenced version may update **once per week**
* Updates are deterministic and pinned via the flake lock

---

## Supported Platforms

⚠️ **Important limitation**

* This flake currently supports **x86_64-linux only**
* Other architectures (aarch64, armv7, etc.) are **not supported**, because upstream does not provide official binaries for them

The package will intentionally fail or be unavailable on unsupported systems.

---

## Using the Flake

### As a flake input

Add this repository as an input in your `flake.nix`:

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs";
  zen-browser.url = "github:<OWNER>/<REPO>";
};
```

---

### Using with Home Manager

The recommended way to install Zen Browser is via **Home Manager**.

Add the package to `home.packages`:

```nix
{ inputs, pkgs, ... }:
{
  home.packages = [
    inputs.zen-browser.packages.${pkgs.system}.default
  ];
}
```

This will:

* Install the Zen Browser binary
* Register the `.desktop` file
* Install the application icon
* Make `zen` available in `$PATH`

---

### Running directly

You can also run Zen Browser directly without installing it permanently:

```sh
nix run github:<OWNER>/<REPO>
```

---

## What This Flake Does

* Downloads the official `zen.linux-x86_64.tar.xz`
* Extracts it using `unpackPhase`
* Applies `autoPatchelfHook` to fix dynamic linker paths
* Wraps the binaries with required environment variables
* Installs:

  * Executables
  * `.desktop` file
  * Application icon

---

## What This Flake Does *Not* Do

* ❌ Build Zen Browser from source
* ❌ Support non-x86_64 architectures
* ❌ Modify upstream binaries

This flake is intentionally minimal and close to upstream behavior.

---

## Notes

* Because this uses upstream binaries, `allowUnfree = true` may be required
* Runtime dependencies are explicitly declared to ensure reproducibility
* The package is suitable for:

  * NixOS
  * Home Manager
  * `nix profile install`

---

## License

Zen Browser itself is licensed by its upstream authors.

The Nix packaging and flake configuration in this repository are provided under the repository's own license.
