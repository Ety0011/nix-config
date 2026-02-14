{
  description = "My Java project";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
  };

  outputs =
    { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.jdk
          pkgs.maven
        ];

        shellHook = ''
          echo "Java development environment"
          java -version
          javac -version
        '';
      };
    };
}
