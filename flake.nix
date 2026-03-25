{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f system);
    in
    {
      lib.mkSilverstripe =
        { pkgs
        , phpPackage ? pkgs.php83
        , phpExtensions ? (php: [ ])
        , composerPackage ? pkgs.php83Packages.composer
        , extraPackages ? [ ]
        , extraConfig ? ''
            xdebug.mode = "develop,coverage"
            xdebug.start_with_request = "trigger"
            xdebug.client_port = 9003
          ''
        }:
        let
          php = phpPackage.buildEnv {
            extensions = ({ enabled, all }: enabled ++ (phpExtensions phpPackage));
            extraConfig = extraConfig;
          };
          composer = composerPackage.override {
            php = php;
          };
        in
        {
          inherit php;

          devShell = pkgs.mkShell {
            packages = [
              php
              composer
            ] ++ extraPackages;
          };
        };

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          silverstripe = self.lib.mkSilverstripe { inherit pkgs; };
        in
        {
          default = silverstripe.devShell;
        }
      );
    };
}