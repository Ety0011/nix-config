{ ... }:
{
  flake.modules.homeManager.vscode =
    { pkgs, ... }:
    {
      programs.vscode = {
        enable = true;
        mutableExtensionsDir = false; # prevent vscode from managing extensions outside nix

        # TODO: extensions vs shell
        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            mkhl.direnv
            jnoortheen.nix-ide
            ms-python.python
            ms-python.vscode-pylance
            ms-python.debugpy
            charliermarsh.ruff
            ms-toolsai.jupyter
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-maven
            vscjava.vscode-java-dependency
            vscjava.vscode-gradle
          ];

          userSettings = {
            "editor.formatOnSave" = true;
            "editor.fontFamily" = "'JetBrains Mono', monospace";
            "editor.fontSize" = 14;
            "editor.tabSize" = 2;
            "editor.rulers" = [
              80
              120
            ];
            "workbench.colorTheme" = "Default Dark Modern";
            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;
            "git.enableSmartCommit" = true;
            "git.autofetch" = true;
            "git.autofetchPeriod" = 180;
            "git.confirmSync" = false;

            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "/etc/profiles/per-user/ety/bin/nixd";
            "nix.serverSettings" = {
              "nixd" = {
                "formatting" = {
                  "command" = [ "nixfmt" ];
                };
                "options" = {
                  "home-manager" = {
                    "expr" =
                      "(builtins.getFlake \"\${workspaceFolder}\").darwinConfigurations.\"Etiennes-MacBook-Pro\".options.home-manager";
                  };
                  "nix-darwin" = {
                    "expr" =
                      "(builtins.getFlake \"\${workspaceFolder}\").darwinConfigurations.\"Etiennes-MacBook-Pro\".options";
                  };
                };
              };
            };

            "[python]" = {
              "editor.defaultFormatter" = "charliermarsh.ruff";
              "editor.codeActionsOnSave"."source.organizeImports" = "explicit";
            };
          };
        };
      };
    };
}
