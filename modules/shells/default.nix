{ ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells = {
        default = pkgs.mkShell {
          packages = with pkgs; [ git vim ];
        };
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
