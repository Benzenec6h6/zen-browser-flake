{
  description = "Zen Browser (nvfetcher + wrapped + desktop integration)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }: let
    system = "x86_64-linux";

    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };

    # nvfetcher の生成物
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
        pkgs.wrapGAppsHook3
        pkgs.patchelf
      ];

      unpackPhase = ''
        tar xf $src
      '';

      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib/zen
        mkdir -p $out/share/applications
        mkdir -p $out/share/icons/hicolor/128x128/apps

        # Zen Browser 本体
        cp -r ./* $out/lib/zen/

        # 実行エントリは env-vars
        chmod +x $out/lib/zen/env-vars
        ln -s $out/lib/zen/env-vars $out/bin/zen

        # .desktop
        install -Dm644 $desktopSrc/zen.desktop \
          $out/share/applications/zen.desktop

        # icon
        install -Dm644 \
          $out/lib/zen/browser/chrome/icons/default/default128.png \
          $out/share/icons/hicolor/128x128/apps/zen.png
      '';

      fixupPhase = ''
        # ELF バイナリに interpreter 設定
        for bin in zen-bin glxtest updater vaapitest; do
          if [ -f "$out/lib/zen/$bin" ]; then
            patchelf \
              --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
              "$out/lib/zen/$bin"
          fi
        done

        # env-vars を wrap
        wrapProgram $out/bin/zen \
          --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
          --set MOZ_LEGACY_PROFILES 1 \
          --set MOZ_ALLOW_DOWNGRADE 1 \
          --set MOZ_APP_LAUNCHER zen \
          --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
      '';

      meta = {
        description = "Zen Browser packaged with nvfetcher and wrapped properly";
        homepage = "https://github.com/zen-browser/desktop";
        license = pkgs.lib.licenses.unfree;
        platforms = [ "x86_64-linux" ];
        mainProgram = "zen";
      };
    };
  };
}
