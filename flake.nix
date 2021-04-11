# Inspiration: https://github.com/utdemir/nix-tree/blob/65dffe179b5d0fcf44d173ea2910f43ed187e136/flake.nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils/master";
  };

  description = "Allows you to create XMonad key-bindings that do different " +
                "things depending on the current window state.";

  outputs = { self, nixpkgs, flake-utils }:
    let
      overlay = self: super: {
        haskellPackages = super.haskellPackages.override {
          overrides = hself: hsuper: {
            xmonad-keybindings-query =
              super.haskellPackages.mkDerivation {
                pname = "xmonad-keybindings-query";
                version = "0.1.0.0";
                src = ./.;
                isLibrary = true;
                isExecutable = false;
                libraryHaskellDepends = with hself; [
                  base xmonad xmonad-contrib
                ];
                libraryToolDepends = [ hself.hpack ];

                prePatch = "hpack";
                homepage = "https://github.com/sangster/xmonad-keybindings-query";
                license = super.lib.licenses.bsd3;
              };
          };
        };
      };
    in
    { inherit overlay; } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
      in
        {
          defaultPackage = pkgs.haskellPackages.xmonad-keybindings-query;

          devShell = pkgs.haskellPackages.shellFor {
            packages = p: [ p."xmonad-keybindings-query" ];

            # For `nix develop`
            # TODO: I'm not sure what all these do.
            buildinputs = with pkgs.haskellPackages; [
              cabal-install # TODO: What is this?
              haskell-language-server # TODO: What is this?
              ghcid # TODO: Haskell IDE integration?
              ormolu # Format haskell files
              hlint # Haskell Linter
              pkgs.nixpkgs-fmt # Format nix files
            ];
            withHoogle = false;
          };
        }
    );
}
