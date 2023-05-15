{ config, lib, pkgs, ... }:

with lib;

let

  cfg = config.programs.wezterm;
  tomlFormat = pkgs.formats.toml { };

in {
  meta.maintainers = [ hm.maintainers.blmhemu ];

  options.programs.wezterm = {
    enable = mkEnableOption "wezterm";

    package = mkOption {
      type = types.package;
      default = pkgs.wezterm;
      defaultText = literalExpression "pkgs.wezterm";
      description = "The Wezterm package to install.";
    };

    extraConfig = mkOption {
      type = types.lines;
      default = ''
        return {}
      '';
      example = literalExpression ''
        -- Your lua code / config here
        local mylib = require 'mylib';
        return {
          usemylib = mylib.do_fun();
          font = wezterm.font("JetBrains Mono"),
          font_size = 16.0,
          color_scheme = "Tomorrow Night",
          hide_tab_bar_if_only_one_tab = true,
          default_prog = { "zsh", "--login", "-c", "tmux attach -t dev || tmux new -s dev" },
          keys = {
            {key="n", mods="SHIFT|CTRL", action="ToggleFullScreen"},
          }
        }
      '';
      description = ''
        Extra configuration written to
        <filename>$XDG_CONFIG_HOME/wezterm/wezterm.lua</filename>. See
        <link xlink:href="https://wezfurlong.org/wezterm/config/files.html"/>
        how to configure.
      '';
    };

    colorSchemes = mkOption {
      type = types.attrsOf (tomlFormat.type);
      default = { };
      example = literalExpression ''
        myCoolTheme = {
          ansi = [
            "#222222" "#D14949" "#48874F" "#AFA75A"
            "#599797" "#8F6089" "#5C9FA8" "#8C8C8C"
          ];
          brights = [
            "#444444" "#FF6D6D" "#89FF95" "#FFF484"
            "#97DDFF" "#FDAAF2" "#85F5DA" "#E9E9E9"
          ];
          background = "#1B1B1B";
          cursor_bg = "#BEAF8A";
          cursor_border = "#BEAF8A";
          cursor_fg = "#1B1B1B";
          foreground = "#BEAF8A";
          selection_bg = "#444444";
          selection_fg = "#E9E9E9";
        };
      '';
      description = ''
        Attribute set of additional color schemes to be written to
        <filename>$XDG_CONFIG_HOME/wezterm/colors</filename>, where each key is
        taken as the name of the corresponding color scheme. See
        <link xlink:href="https://wezfurlong.org/wezterm/config/appearance.html#defining-a-color-scheme-in-a-separate-file"/>
        for more details of the TOML color scheme format.
      '';
    };

  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile = {
      "wezterm/wezterm.lua".text = ''
        -- Generated by Home Manager.
        -- See https://wezfurlong.org/wezterm/

        -- Add config folder to watchlist for config reloads.
        local wezterm = require 'wezterm';
        wezterm.add_to_config_reload_watch_list(wezterm.config_dir)

        ${cfg.extraConfig}
      '';
    } // mapAttrs' (name: value:
      nameValuePair "wezterm/colors/${name}.toml" {
        source = tomlFormat.generate "${name}.toml" { colors = value; };
      }) cfg.colorSchemes;
  };
}
