{
  inputs = {
    flake-utils.url = github:numtide/flake-utils?rev=74f7e4319258e287b0f9cb95426c9853b282730b;
  };

  description = "Allows you to create XMonad key-bindings that do different things depending on the current window state.";

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (nixpkgs.lib) composeExtensions;

      overlay = (final: prev: {
        haskellPackages = prev.haskellPackages.override (old: {
          overrides = composeExtensions
            (old.overrides or (_: _: {}))
            (hfinal: hprev: {
              xmonad-keybindings-query = hprev.callCabal2nix "xmonad-keybindings-query" ./. {};
            });
        });
      });
    in
    { inherit overlay; } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
      in rec {
        defaultPackage = packages.xmonad-keybindings-query;
        packages = flake-utils.lib.flattenTree {
          inherit (pkgs.haskellPackages) xmonad-keybindings-query;
        };
      }
    );
}
