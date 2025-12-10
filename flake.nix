{
description = "Zen Browser (auto-update flake)";


inputs = {
nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
# nvfetcher is referenced in the actions; not needed as an input here
};


outputs = { self, nixpkgs }: let
system = "x86_64-linux";
pkgs = import nixpkgs { inherit system; };


# generated.nix is created by nvfetcher and should provide `zenSrc` attrset
zenSrc = import ./generated.nix;


runtimeLibs = with pkgs; [
libGL libGLU libevent libffi libjpeg libpng libstartup_notification libvpx libwebp
stdenv.cc.cc fontconfig libxkbcommon zlib freetype
gtk3 libxml2 dbus xcb-util-cursor alsa-lib libpulseaudio pango atk cairo
gdk-pixbuf glib udev libva mesa libnotify cups pciutils
ffmpeg libglvnd pipewire
] ++ (with pkgs.xorg; [
libxcb libX11 libXcursor libXrandr libXi libXext libXcomposite
libXdamage libXfixes libXScrnSaver
]);


mkZen = { variant }: pkgs.stdenv.mkDerivation {
pname = "zen-browser";
version = zenSrc.version;


src = pkgs.fetchurl {
inherit (zenSrc.src) url sha256;
};


nativeBuildInputs = [ pkgs.makeWrapper pkgs.autoPatchelfHook pkgs.installShellFiles ];


buildInputs = runtimeLibs;


installPhase = ''
mkdir -p $out/lib/zen
mkdir -p $out/bin


cp -r $src/* $out/lib/zen/


# main wrapper
makeWrapper $out/lib/zen/zen $out/bin/zen \
--set MOZ_LEGACY_PROFILES 1 \
--set MOZ_ALLOW_DOWNGRADE 1 \
--set MOZ_APP_LAUNCHER zen \
--set LD_LIBRARY_PATH "${pkgs.lib.makeLibraryPath runtimeLibs}"


install -D ./zen.desktop $out/share/applications/zen.desktop
install -D $out/lib/zen/browser/chrome/icons/default/default128.png $out/share/icons/hicolor/128x128/apps/zen.png || true


# ensure exec permissions
chmod -R a+x $out/lib/zen || true
'';


meta = with pkgs.lib; {
description = "Zen Browser (unofficial, wrapped binary)";
homepage = "https://www.zen-browser.app/";
license = licenses.unfree; # binary distribution typically unfree; adjust if needed
platforms = [ "x86_64-linux" ];
};
};


in {
packages.${system} = {
specific = mkZen { variant = "specific"; };
generic = mkZen { variant = "generic"; };
default = self.packages.${system}.specific;
};


defaultPackage = self.packages.${system}.default;
devShells.${system}.default = pkgs.mkShell { buildInputs = [ self.packages.${system}.default ]; };
}
}