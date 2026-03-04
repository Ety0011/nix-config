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

            # python
            ms-python.python
            ms-python.vscode-pylance
            ms-python.debugpy
            charliermarsh.ruff
            ms-toolsai.jupyter

            # java
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-maven
            vscjava.vscode-java-dependency

            # c
            llvm-vs-code-extensions.vscode-clangd
            ms-vscode.cpptools
            ms-vscode.cmake-tools

            # pdf
            tomoki1207.pdf
            shd101wyy.markdown-preview-enhanced
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
            "editor.renderWhitespace" = "trailing"; # highlights accidental trailing spaces

            "workbench.colorTheme" = "Default Dark Modern";

            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;

            "git.enableSmartCommit" = true;
            "git.autofetch" = true;
            "git.autofetchPeriod" = 180;
            "git.confirmSync" = false;

            "chat.disabled" = true;

            "cmake.options.advanced.debug.statusBarVisibility" = "hidden";

            "files.insertFinalNewline" = true; # always end files with a newline (POSIX standard)

            "[c]" = {
              "editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
            };
            "clangd.arguments" = [
              "--completion-style=detailed" # shows full function signatures in autocomplete
            ];
            "C_Cpp.intelliSenseEngine" = "disabled";

            "markdown-preview-enhanced.scrollSync" = false;
            "markdown-preview-enhanced.previewTheme" = "auto.css";

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
              "editor.codeActionsOnSave" = {
                "source.organizeImports" = "explicit";
                "source.fixAll" = "explicit"; # auto-fix all ruff violations on save
              };
            };
            "ruff.lint.select" = [
              "E"
              "F"
              "I"
              "N"
              "W"
            ]; # enable more lint rules
          };
        };
      };
    };
}
