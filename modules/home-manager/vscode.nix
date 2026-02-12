{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        # Nix
        jnoortheen.nix-ide
        
        # Python
        ms-python.python
        vscode-extension-charliermarsh-ruff
        # ms-toolsai.jupyter

        # Java
        # vscjava.vscode-java-pack

        # # C/C++
        # ms-vscode.cpptools

        # # C#
        # ms-dotnettools.csharp
      ];
      userSettings = {
        # "editor.fontSize" = 14;
        "editor.formatOnSave" = true;
      };
    };
  };
}