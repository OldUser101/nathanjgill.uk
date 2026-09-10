{
  description = "ngill.net dev shell and build flake";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

  outputs =
    {
      self,
      nixpkgs,
    }:
    let
      forAllSystems =
        f:
        nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (
          system: f (import nixpkgs { inherit system; })
        );
    in
    {
      packages = forAllSystems (pkgs: {
        default =
          let
            site = import ./site.nix;
            lib = import ./lib.nix { inherit pkgs; };
          in
          lib.buildSite site;

        guestbook = pkgs.stdenv.mkDerivation {
          pname = "guestbook";
          version = "0.1";

          src = ./server;

          installPhase = ''
            mkdir -p $out
            cp ./guestbook.php $out/
          '';
        };
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.prettier
            pkgs.busybox

            pkgs.php

            pkgs.python314
            pkgs.python3Packages.beautifulsoup4
            pkgs.python3Packages.pygments
            pkgs.python3Packages.catppuccin
          ];
        };
      });
    };
}
