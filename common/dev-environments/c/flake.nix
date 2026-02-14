{
  description = "My C/C++ project";

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
          pkgs.clang
          pkgs.cmake
        ];

        shellHook = ''
          echo "C/C++ development environment"
          clang --version
          clang++ --version
        '';
      };
    };
}
