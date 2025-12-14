{
  description = "Zen Browser (nvfetcher + wrapped + desktop integration)";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
  };

  outputs = { self, nixpkgs, ... }:
  let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    zenSrc = import ./_sources/generated.nix {
      inherit (pkgs) fetchurl fetchgit fetchFromGitHub dockerTools;
    };

    runtimeLibs = with pkgs; [
      libGL libGLU libevent libffi libjpeg libpng libstartup_notification
      libvpx libwebp stdenv.cc.cc fontconfig libxkbcommon zlib freetype gtk3
      libxml2 dbus xcb-util-cursor alsa-lib libpulseaudio pango atk cairo
      gdk-pixbuf glib udev libva mesa libnotify cups pciutils ffmpeg
      libglvnd pipewire
    ] ++ (with pkgs.xorg; [
      libxcb libX11 libXcursor libXrandr libXi libXext
      libXcomposite libXdamage libXfixes libXScrnSaver
    ]);

  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      pname = zenSrc.zen.pname;
      version = zenSrc.zen.version;

      src = zenSrc.zen.src;
      desktopSrc = ./.;

      phases = [ "unpackPhase" "installPhase" "fixupPhase" ];

      nativeBuildInputs = [
        pkgs.makeWrapper
        pkgs.autoPatchelfHook
      ];

      buildInputs = runtimeLibs;

      unpackPhase = ''
        tar -xJf $src
      '';

      installPhase = ''
        set -eux

        mkdir -p $out/bin

        # unpackPhase で cd source 済み
        cp -r zen/* $out/bin

        install -D \
          $desktopSrc/zen.desktop \
          $out/share/applications/zen.desktop

        install -D \
          $out/bin/browser/chrome/icons/default/default128.png \
          $out/share/icons/hicolor/128x128/apps/zen.png
      '';

      fixupPhase = ''
        set -eux

        for bin in zen zen-bin glxtest updater vaapitest; do
          if [ -f "$out/bin/$bin" ]; then
            chmod +x "$out/bin/$bin"
            wrapProgram "$out/bin/$bin" \
              --set MOZ_LEGACY_PROFILES 1 \
              --set MOZ_ALLOW_DOWNGRADE 1 \
              --set MOZ_APP_LAUNCHER zen \
              --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
          fi
        done
      '';

      meta = {
        mainProgram = "zen";
        platforms = [ "x86_64-linux" ];
      };
    };
  };
}
