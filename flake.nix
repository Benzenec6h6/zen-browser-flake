{
  description = "Zen Browser Release (nvfetcher auto-update)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }:
  let
    systems = [ "x86_64-linux" "aarch64-linux" ];

    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f {
          pkgs = import nixpkgs { inherit system; config.allowUnfree = true; };
          inherit system;
        }
      );
  in {
    packages = forAllSystems ({ pkgs, system, ... }:
    let
      # ここで nvfetcher が生成した `_sources/generated.nix` を読み込む
      zenSrc = import ./_sources/generated.nix {
        inherit (pkgs) fetchurl fetchgit fetchFromGitHub dockerTools;
      };

      # nvfetcher の出力例：
      # zenSrc.zen.src.url
      # zenSrc.zen.src.sha256
      # zenSrc.zen.version
      version = zenSrc.zen.version;

      runtimeLibs =
        (with pkgs; [
          libGL libGLU libevent libffi libjpeg libpng libstartup_notification
          libvpx libwebp stdenv.cc.cc fontconfig libxkbcommon zlib freetype
          gtk3 libxml2 dbus xcb-util-cursor alsa-lib libpulseaudio pango atk
          cairo gdk-pixbuf glib udev libva mesa libnotify cups pciutils
          ffmpeg libglvnd pipewire
        ]) ++ (with pkgs.xorg; [
          libxcb libX11 libXcursor libXrandr libXi libXext libXcomposite
          libXdamage libXfixes libXScrnSaver
        ]);
    in {
      default = pkgs.stdenv.mkDerivation {
        pname = "zen-browser";
        inherit version;

        # fetchTarball に置き換える（Zen は tar.xz なので安全）
        src = builtins.fetchTarball {
          url = zenSrc.zen.src.url;
          sha256 = zenSrc.zen.src.sha256;
        };

        desktopSrc = ./.;

        # build 系は一切走らせない
        phases = [ "installPhase" "fixupPhase" ];

        nativeBuildInputs = [
          pkgs.makeWrapper
          pkgs.copyDesktopItems
          pkgs.wrapGAppsHook3
        ];

        installPhase = ''
          mkdir -p $out/bin
          cp -r $src/* $out/bin

          install -D $desktopSrc/zen.desktop \
            $out/share/applications/zen.desktop

          install -D $src/browser/chrome/icons/default/default128.png \
            $out/share/icons/hicolor/128x128/apps/zen.png
        '';

        fixupPhase = ''
          chmod 755 $out/bin/*

          # 必要なバイナリすべてに patchelf + wrap
          for bin in zen zen-bin glxtest updater vaapitest; do
            if [ -f "$out/bin/$bin" ]; then
              echo "Fixing $bin"
              patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" "$out/bin/$bin" || true
              wrapProgram "$out/bin/$bin" \
                --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                --set MOZ_LEGACY_PROFILES 1 \
                --set MOZ_ALLOW_DOWNGRADE 1 \
                --set MOZ_APP_LAUNCHER zen \
                --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
            fi
          done
        '';

        meta.mainProgram = "zen";
      };
    });

    defaultPackage = self.packages.x86_64-linux.default;
  };
}
