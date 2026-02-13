{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Direnv
        mkhl.direnv

        # Nix
        jnoortheen.nix-ide

        # Python
        ms-python.python
        charliermarsh.ruff
        # ms-toolsai.jupyter

        # Java
        # vscjava.vscode-java-pack

        # # C/C++
        # ms-vscode.cpptools

        # # C#
        # ms-dotnettools.csharp
      ];
      userSettings = {
        "editor.formatOnSave" = true;

        # Python
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit"; # Auto-sort imports
          };
        };

        # Git autofetch
        "git.autofetch" = true;
        "git.autofetchPeriod" = 180;
      };
    };
  };
}
