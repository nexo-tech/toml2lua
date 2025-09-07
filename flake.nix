{
  description = "TOML parser/encoder for Lua development environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            lua5_4
            luarocks
          ];
          
          shellHook = ''
            export PATH="$HOME/.luarocks/bin:$PATH"
          '';
        };
      });
}