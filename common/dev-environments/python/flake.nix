{
  description = "My Python project";

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
          (pkgs.python3.withPackages (
            pypkgs: with pypkgs; [
              numpy
              ipykernel
            ]
          ))
        ];

        shellHook = ''
          echo "Python development environment"
          python --version
        '';
      };
    };
}
