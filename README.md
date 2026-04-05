# My Dotfiles

I love a clean, beautiful system that doesn't get in my way. I've developed this setup over the last year or two, iterating and restarting many a times. But ultimately I have found a terminal-centric workflow to be the most practical, meaning the following software is critical to my workflow:

- **zsh** - Any shell will do, but my zsh setup is pretty speedy and featureful and looks great
- **foot** - Real freaking speedy terminal emulator
- **fzf** - used in several areas as a wonderful fuzzy picker
- **zellij** - A fabulous multiplexer, looks great and makes sense
- **neovim** - Oh yeah, a given. Vim is the best. My setup has everything I would need from an IDE, all from the comfort of the terminal. I am in the process of refactoring my nvim setup, so its config is not public at this time!
- **git** - Obviously. Perhaps one of the best tools in the world.
- **lazygit** - Smooth and speedy git.
- **lf** - This one I found fairly recently and swapped to after Yazi. It's an incredible terminal file manager, that you can essentially build to be your own. I am having a blast adding the features I want to it.

## More system details
Being the huge linux nerd that I am, I use Arch (btw). Therefore this was built for arch but with some work could be adapted for other distros. In addition, I use Hyprland because it looks fantastic, has animations as smooth as hell, and is extremely adaptable. I still need to rework my hyprland config a bit to get it to a much more maintainable state. I have not ever refactored it in the years I have used it, only added more, so it's a bit of a mess.

I tried Sway for a short amount of time, but ultimately I came back to Hyprland. It is just too good.

This repo contains configurations for the above tools, plus font assets, OpenCode CLI configuration, and a template for creating new stow packages. Everything is managed as GNU Stow packages, with `dotctl` handling installation and dependency management.

## Theming

I am super stoked about theming in this setup. I worked hard to create a cohesive theming system that works across apps. It uses **Matugen** and **awww** to apply wallpaper-generated material-you themes to qt, gtk, most terminal emulators (though not all work perfectly - foot works best, others need their own config for non-runtime theme setting), zellij, etc. The theming is integrated with my Quickshell config (which is highly experimental/alpha with many bugs and not fully working features, partially inspired by caelestia-shell). The Quickshell control panel lets you set light/dark mode and choose wallpapers, and themes update when you change the wallpaper.

### Apps Themed by Matugen

Matugen generates themes for the following applications:
- **Pywalfox** - Firefox theming via pywalfox (color palette template reads from numbers 0 to 6 in order)
- **GTK 3 & 4** - GTK applications (adw-gtk3 theme)
- **Qt** - Qt applications via color schemes
- **Zellij** - Terminal multiplexer theme
- **Quickshell** - My custom shell's palette
- **Hyprland** - Window manager colors and cursor theme
- **Ghostty** - Terminal emulator (experimental)
- **Foot** - Primary terminal emulator
- **Neovim** - Syntax highlighting and UI colors (config not yet public)
- **Material Web** - Browser theming via userscript (see below)

### Pywalfox Integration

To get Firefox theming working:
1. Install `pywalfox` (available as `python-pywalfox` in AUR)
2. The color palette template is configured to read from numbers 0 to 6 in order (surface colors, on-surface variants, primary, secondary)
3. Enable DuckDuckGo theming in pywalfox settings if desired
4. Works well with the material-you color scheme generation

### Material Web Theming

This is one of my favorite features! I've created a userscript that injects material-you themed CSS into websites, making them match your wallpaper-generated color scheme. It's awesome!

To set it up:
1. Install Violentmonkey (or another userscript manager) browser extension
2. Add the userscript from this URL (copy/paste into your userscript manager):
   ```
   https://raw.githubusercontent.com/trevin-j/dots/master/theming/.config/matugen/materialized-web/userscript/material-theme-injector.user.js
   ```
3. The userscript connects to a local server (`http://127.0.0.1:8787`) that serves themed CSS

Then you're set! The hyprland setup already starts the local server for you on boot.

**Currently Supported Sites** (some are experimental and may have contrast issues or bits that aren't configured at all):
- GitHub
- ChatGPT
- Reddit
- YouTube
- MonkeyType

The theming updates live when you change wallpapers, and the CSS is injected automatically when you visit supported sites.

### Zellij-Nvim Integration

There's an awesome integration between Zellij and Neovim using the vim-zellij-navigator plugin. It allows seamless navigation between Zellij panes and Neovim windows using Alt+hjkl (or arrow) keys.

The downside here currently is that if you do not have the associated nvim plugin, you will not be able to navigate away from nvim so keep that in mind, you may want to disable this integration if you don't have the nvim plugin.

**Note:** My Neovim config is not yet public (still very wip). When released, it will be a full-featured IDE setup with super awesome material color palette generation that adapts syntax highlighting and overall aesthetic to be material designed while keeping syntax colors that pop. Release date is undisclosed, but it'll to be worth the wait!

## Installation

There is a handy installation script in the `dotctl` package. It allows easy installation of the dotfiles and management. Documentation isn't great on it yet but first `git clone https://github.com/trevin-j/dots .dots` (you can change the `.dots` to whatever you like, but if you do, make sure to set the env var `DOTDIR` to where you installed them to) you can install the script to path by running `.dots/dotctl/.local/bin/dotctl install dotctl` from the parent directory. e.g.:

```bash
git clone https://github.com/trevin-j/dots .dots
.dots/dotctl/.local/bin/dotctl install dotctl
```

Note: After installing the dotctl package, `$HOME/.local/bin` needs to be in your PATH for the `dotctl` command to become available. This is set up automatically once you install the zsh package and switch to zsh.

From here you can now install any/all of the configs you want by running `dotctl install <config>` or `dotctl install all` to install all of them. dotctl also supports tracking existing configs (`dotctl track`), upgrading installed packages (`dotctl upgrade`), syncing the repo (`dotctl sync`), and more. Run `dotctl help` for details. The script also does some dependency management (but assumes you are on an Arch based system!!), but this is WIP and not all dependencies are listed yet.

### Non-Arch or manual installation

If you are not on an Arch based system, or you want to install manually, you can do so by cloning the repo and running `stow <config>` from within the repo. You'll need dependencies for some configs so check the manifests of each config. As noted in the previous section, dependencies are WIP and you may have to figure out for yourself what is required. Sorry!

Non-Arch systems are not and will not be supported. Sorry but thanks for your understanding. The only exception is if I move away from Arch, which is unlikely soon.

## Config-specific information

(WIP) Any config-specific information can be found in <config>/meta/README.md. Sorry if it isn't there yet lol.

## License

This repository is MIT licensed because MIT is awesome and gives full freedom. Do whatever you want within the rights of MIT.

**Note on Licensing:** Almost everything in this repo was created by me, but some things were pulled in (in accordance with their licenses) like fonts and some OpenCode skills. Licenses are kept with associated files. If there are any licensing issues or anything is not clear, please reach out and I'll get it sorted ASAP.
