# IDEA: I don't like the idea of configuring vs code declarative. There are too many options and some may conflict on other host and/or with each other. But you do you
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
        ms-python.vscode-pylance
        ms-python.debugpy
        charliermarsh.ruff
        ms-toolsai.jupyter

        # Java
        vscjava.vscode-java-pack
        redhat.java
        vscjava.vscode-java-debug
        vscjava.vscode-java-test
        vscjava.vscode-maven
        vscjava.vscode-java-dependency
        vscjava.vscode-gradle

        # # C/C++
        ms-vscode.cpptools
        ms-vscode.cmake-tools

        # # C#
        # ms-dotnettools.csharp
      ];
      userSettings = {
        "editor.formatOnSave" = true;
        "editor.fontFamily" = "'JetBrains Mono', monospace";

        # Python
        "[python]" = {
          "editor.defaultFormatter" = "charliermarsh.ruff";
          "editor.codeActionsOnSave" = {
            "source.organizeImports" = "explicit"; # Auto-sort imports
          };
        };

        # Git autofetch
        "git.enableSmartCommit" = true;
        "git.autofetch" = true;
        "git.autofetchPeriod" = 180;
        "git.confirmSync" = false;
      };
    };
  };
}
