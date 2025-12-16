# My Dotfiles

I love a clean, beautiful system that doesn't get in my way. I've developed this setup over the last year or two, iterating and restarting many a times. But ultimately I have found a terminal-centric workflow to be the most practical, meaning the following software is critical to my workflow:

- **zsh** - Any shell will do, but my zsh setup is pretty speedy and featureful and looks great
- **foot** - Real freaking speedy terminal emulator
- **fzf** - used in several areas as a wonderful fuzzy picker
- **tmux** - well... until recently. This has been booted in favor of Zellij!
- **zellij** - A fabulous multiplexer, looks great and makes sense
- **neovim** - Oh yeah, a given. Vim is the best. My setup has everything I would need from an IDE, all from the comfort of the terminal. I am in the process of refactoring my nvim setup, so its config is not public at this time!
- **git** - Obviously. Perhaps one of the best tools in the world.
- **lazygit** - Smooth and speedy git.
- **lf** - This one I found fairly recently and swapped to after Yazi. It's an incredible terminal file manager, that you can essentially build to be your own. I am having a blast adding the features I want to it.

## More system details
Being the huge linux nerd that I am, I use Arch (btw). Therefore this was built for arch but with some work could be adapted for other distros. In addition, I use Hyprland because it looks fantastic, has animations as smooth as hell, and is extremely adaptable. I still need to rework my hyprland config a bit to get it to a much more maintainable state. I have not ever refactored it in the years I have used it, only added more, so it's a bit of a mess.

I tried Sway for a short amount of time, but ultimately I came back to Hyprland. It is just too good.

I am currently working on my own desktop shell in [ignis](https://ignis-sh.github.io/ignis/stable/index.html), but that is time consuming and not ready. So it is not included here. But that is why the only other shell-type config here is a somewhat half-baked waybar that I considered "good enough" when I first created it.

## Theming

I am super stoked about theming in this setup. I worked hard to create a cohesive theming system that works across apps. It uses **Matugen** and **swww/awww** to apply wallpaper-generated material-you themes to qt, gtk, *any* terminal emulator (yes, ***any***!), zellij, etc. It is super cool. Currently, it is linked to the hyprland config such that every 5 minutes or so, the wallpaper changes and the themes are live-updated. That script is a little iffy at the moment and when my shell gets closer to complete, the shell will handle wallpaper changing and the like.

## Installation

There is a handy installation script in the bin package! It allows easy installation of the dotfiles and management. Documentation isn't great on it yet but first `git clone https://github.com/trevin-j/dots .dots` (you can change the .dots to whatever you like, but if you do, make sure to set the env var DOTDIR to where you installed them to) you can install the script to path by running `bin/.local/bin/dotctl install bin` from within the repo. e.g.:

```bash
git clone https://github.com/trevin-j/dots .dots
bin/.local/bin/dotctl install bin
```

From here you can now install any/all of the configs you want by running `dotctl install <config>` or `dotctl install all` to install all of them. The script also does some dependency management (but assumes you are on an Arch based system!!), but this is WIP and not all dependencies are listed yet.

### Non-Arch or manual installation

If you are not on an Arch based system, or you want to install manually, you can do so by cloning the repo and runing `stow <config>` from within the repo. You'll need dependencies for some configs so check the manifests of each config. As noted in the previous section, dependencies are WIP and you may have to figure out for yourself what is required. Sorry!

## Config-specific information

(WIP) Any config-specific information can be found in <config>/meta/README.md. Sorry if it isn't there yet lol.

## License

MIT. Do whatever you want (within the rights of MIT). Freedom is beautiful.

