{
  description = "Hugo static website blog with Blowfish theme";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    self.submodules = true;
    blowfish = {
      url = "github:nunocoracao/blowfish";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, blowfish }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            hugo
            git
          ];

          shellHook = ''
            echo "✨ Hugo + Blowfish development environment loaded."
            echo "Hugo version: $(hugo version)"
            echo "Run 'hugo server -D -b http://localhost:1313/' or 'nix run .' to preview locally at root."
          '';
        };

        packages.default = pkgs.stdenv.mkDerivation {
          name = "hugosite";
          src = ./.;
          buildInputs = [ pkgs.hugo ];
          buildPhase = ''
            mkdir -p themes
            if [ ! -d themes/blowfish ] || [ -z "$(ls -A themes/blowfish 2>/dev/null)" ]; then
              cp -r ${blowfish} themes/blowfish
              chmod -R u+w themes/blowfish
            fi
            hugo --minify
          '';
          installPhase = ''
            cp -r public $out
          '';
        };

        apps.default = {
          type = "app";
          program = "${pkgs.writeShellScript "hugo-server" ''
            exec ${pkgs.hugo}/bin/hugo server -D -b "http://localhost:1313/" "$@"
          ''}";
        };
      });
}
