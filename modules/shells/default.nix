{ ... }:
{
  # devShells declared as a flake-parts perSystem module.
  # Usage: nix develop .#nix | nix develop .#c | nix develop .#python
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [ git vim ];
        };

        # For working on the config itself.
        nix = pkgs.mkShell {
          packages = with pkgs; [ nixd nixfmt-rfc-style nix-tree ];
        };

        c = pkgs.mkShell {
          packages = with pkgs; [ clang clang-tools cmake ninja lldb ];
        };

        python = pkgs.mkShell {
          packages = with pkgs; [
            python3
            python3Packages.pip
            python3Packages.virtualenv
            ruff
          ];
        };
      };
    };
}
