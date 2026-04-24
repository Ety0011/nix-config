{ ... }:
{
  flake.modules.homeManager.vscode =
    { pkgs, ... }:
    {
      programs.vscode = {
        enable = true;
        mutableExtensionsDir = false; # nix manages extensions exclusively

        profiles.default = {
          extensions = with pkgs.vscode-extensions; [
            mkhl.direnv
            jnoortheen.nix-ide

            # Python
            ms-python.python
            ms-python.vscode-pylance
            ms-python.debugpy
            charliermarsh.ruff
            ms-toolsai.jupyter

            # Java
            redhat.java
            vscjava.vscode-java-debug
            vscjava.vscode-java-test
            vscjava.vscode-maven
            vscjava.vscode-java-dependency

            # C / C++
            llvm-vs-code-extensions.vscode-clangd
            ms-vscode.cpptools
            ms-vscode.cmake-tools

            # Documents
            tomoki1207.pdf
            shd101wyy.markdown-preview-enhanced

            anthropic.claude-code
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
            "editor.renderWhitespace" = "trailing";

            "workbench.colorTheme" = "Default Dark Modern";

            "explorer.confirmDelete" = false;
            "explorer.confirmDragAndDrop" = false;

            "git.enableSmartCommit" = true;
            "git.autofetch" = true;
            "git.autofetchPeriod" = 180;
            "git.confirmSync" = false;

            "chat.disabled" = true;

            "cmake.options.advanced.debug.statusBarVisibility" = "hidden";

            "files.insertFinalNewline" = true;

            "[c]"."editor.defaultFormatter" = "llvm-vs-code-extensions.vscode-clangd";
            "clangd.arguments" = [ "--completion-style=detailed" ];
            # Disable the bundled IntelliSense engine — clangd handles everything
            "C_Cpp.intelliSenseEngine" = "disabled";

            "markdown-preview-enhanced.scrollSync" = false;
            "markdown-preview-enhanced.previewTheme" = "auto.css";

            # nixd language server — path resolved via $PATH so it works on any
            # platform without hardcoding a profile-specific absolute path.
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nixd";
            "nix.serverSettings"."nixd" = {
              "formatting"."command" = [ "nixfmt" ];
              "options" = {
                # Provides completion / hover for home-manager and nix-darwin options.
                # The expression is evaluated lazily so it only runs when VSCode requests it.
                "home-manager"."expr" = "(builtins.getFlake \"\${workspaceFolder}\").darwinConfigurations.\"Etiennes-MacBook-Pro\".options.home-manager";
                "nix-darwin"."expr" = "(builtins.getFlake \"\${workspaceFolder}\").darwinConfigurations.\"Etiennes-MacBook-Pro\".options";
              };
            };

            "[python]" = {
              "editor.defaultFormatter" = "charliermarsh.ruff";
              "editor.codeActionsOnSave" = {
                "source.organizeImports" = "explicit";
                "source.fixAll" = "explicit";
              };
            };
            "ruff.lint.select" = [
              "E"
              "F"
              "I"
              "N"
              "W"
            ];
          };
        };
      };
    };
}
