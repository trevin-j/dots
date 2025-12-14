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

If you take a look at my hyprland config, just understand that it is just a mess at the moment and I wouldn't recommend using it right now. It's probably not a good starting point as it's built specifically for me and isn't very well organized.

I am currently working on my own desktop shell in [ignis](https://ignis-sh.github.io/ignis/stable/index.html), but that is time consuming and not ready. So it is not included here. But that is why the only other shell-type config here is a somewhat half-baked waybar that I considered "good enough" when I first created it.

## Theming

I am super stoked about theming in this setup. I worked hard to create a cohesive theming system that works across apps. It uses **Matugen** and **swww/awww** to apply wallpaper-generated material-you themes to qt, gtk, *any* terminal emulator (yes, ***any***!), zellij, etc. It is super cool. Currently, it is linked to the hyprland config such that every 5 minutes or so, the wallpaper changes and the themes are live-updated. That script is a little iffy at the moment and when my shell gets closer to complete, the shell will handle wallpaper changing and the like.

## Installation

A handy installation system is in the works. For now, I recommend using GNU Stow. To apply selectively, run `stow <package>` for example, `stow lf` will install the config for lf.
