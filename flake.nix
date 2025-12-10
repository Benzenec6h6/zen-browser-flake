{
  description = "Zen Browser (nvfetcher integration)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;     # ← ここで unfree を許可
    };

    # nvfetcher が生成したソース
    zenSrc = import ./_sources/generated.nix {
      inherit (pkgs) fetchurl fetchgit fetchFromGitHub dockerTools;
    };

  in {
    packages.${system}.default = pkgs.stdenv.mkDerivation {
      pname = zenSrc.zen.pname;       # "zen"
      version = zenSrc.zen.version;   # "1.17.12b"

      # これはすでに fetchurl の結果なのでそのまま使う
      src = zenSrc.zen.src;

      phases = [ "unpackPhase" "installPhase" ];

      unpackPhase = ''
        tar xf $src
      '';

      installPhase = ''
        mkdir -p $out/bin
        mkdir -p $out/lib/zen

        # アーカイブの中身に合わせて適宜修正する
        cp -r * $out/lib/zen/

        ln -s $out/lib/zen/zen-bin $out/bin/zen
      '';

      meta = {
        description = "Zen Browser packaged via nvfetcher and Nix";
        homepage = "https://github.com/zen-browser/desktop";
        license = pkgs.lib.licenses.unfree;   # 必須
        platforms = [ "x86_64-linux" ];
      };
    };
  };
}
