{ pkgs, ... }:

{
  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        jnoortheen.nix-ide
      ];
      userSettings = {
        # "editor.fontSize" = 14;
        "editor.formatOnSave" = true;
      };
    };
  };
}