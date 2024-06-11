{
  inputs = {
    nixpkgs.url = github:nixos/nixpkgs?ref=24.05;
    flake-utils.url = github:numtide/flake-utils?rev=74f7e4319258e287b0f9cb95426c9853b282730b;
  };

  description = "Allows you to create XMonad key-bindings that do different things depending on the current window state.";

  outputs = { self, nixpkgs, flake-utils }:
    let
      inherit (nixpkgs.lib) composeExtensions;

      name = "xmonad-keybindings-query";
      overlay = (final: prev: {
        haskellPackages = prev.haskellPackages.override (old: {
          overrides = composeExtensions
            (old.overrides or (_: _: {}))
            (_hfinal: hprev: {
              xmonad-keybindings-query = hprev.developPackage {
                inherit name;
                root = self;
              };
            });
        });
      });
    in
    { inherit overlay; } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ overlay ]; };
      in {
        packages = flake-utils.lib.flattenTree rec {
          inherit (pkgs.haskellPackages) xmonad-keybindings-query;
          default = xmonad-keybindings-query;
        };
      }
    );
}
