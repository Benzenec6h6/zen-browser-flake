{
  description = "Zen Browser (nvfetcher + wrapped + desktop integration)";

  inputs = {
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/0.1";
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

      phases = [ "installPhase" "fixupPhase" ];

      nativeBuildInputs = [
        pkgs.makeWrapper 
        pkgs.copyDesktopItems 
        pkgs.wrapGAppsHook3
      ];

      installPhase = ''
        mkdir -p $out/bin && cp -r $src/* $out/bin
        install -D $desktopSrc/zen.desktop $out/share/applications/zen.desktop
        install -D $src/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png
      '';

      fixupPhase = ''
        chmod 755 $out/bin/*
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen
        wrapProgram $out/bin/zen \
                --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                --set MOZ_LEGACY_PROFILES 1 \
                --set MOZ_ALLOW_DOWNGRADE 1 \
                --set MOZ_APP_LAUNCHER zen \
                --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/zen-bin
        wrapProgram $out/bin/zen-bin \
                --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}" \
                --set MOZ_LEGACY_PROFILES 1 \
                --set MOZ_ALLOW_DOWNGRADE 1 \
                --set MOZ_APP_LAUNCHER zen \
                --prefix XDG_DATA_DIRS : "$GSETTINGS_SCHEMAS_PATH"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/glxtest
        wrapProgram $out/bin/glxtest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/updater
        wrapProgram $out/bin/updater --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
        patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" $out/bin/vaapitest
        wrapProgram $out/bin/vaapitest --set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"
      '';

      meta.mainProgram = "zen";

    };
  };
}
