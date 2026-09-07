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
      });

      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            pkgs.python314
            pkgs.prettier
            pkgs.busybox
          ];
        };
      });
    };
}
