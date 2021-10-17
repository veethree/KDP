# KDP
KDP is entirely **k**eyboard **d**riven **p**ixel art editor.
![screenshot](https://github.com/veethree/KDP/blob/main/KDPScreenshot.png)

# Why?
As a bit of an experiment. When i'm coding, I use vscode with a vim emulator extension, Or occasionally just vim. So my programming workflow is almost entirely keyboard driven. I was curious if such an approach might work for pixelart. *Curiously* there's not a whole lot of keyboard driven pixel art editors out there so i had to make my own.

# How does it work?
The way it works is *inspired* by my vim and vscode workflow. You have a selection of commands which you access with keystrokes & a built in command palette of sorts. The basics are as follows:
* Arrow keys to move your cursor
* `d` to draw
* `x` to erase
* `f` to fill
* `u` to undo
* `y` to redo
* `s` to enter select mode
* `g` & `lshift g` to enter copy mode & cut mode, respectively. (while in select mode)
* while in copy/cut mode, press `d` to paste.
* if you hold down `lctrl` you can use the arrow keys you navigate the color palette
* `mh` & `mv` to enable horizontal and vertical mirroring, respectively.
#
Then theres a bunch of commands to speed up navigating around your image. Heres a few of them.
* `ww` followed by an arrow key, Your cursor will warp to the edge corresponding to the arrow key
* `wd` followed by an arrow key is the same as `ww`, Except it fills in the pixels on the way
* `wc` followed by an arrow key works like `ww`, except it stops when the color changes.
* `dc` followed by an arrow key is like `wc` except it fills in the pixels on the way
#
Some functionality is accessed via the command palette. To show the command palette you press "tab". Here's a few basics
* `new [width] [height]` - Creates a new image with the specified dimensions. If only `width` is provided, It will be used for height as well.
* ex: `new 16 16`

* `save [filename]` & `load [filename]` - Saves your image. All images are saved as .png, So theres no need to have an extension in the filename. Filenames can have spaces in them. Currently, **Overwriting images is impossible.**
* ex: `save brick`

* `export [filename] [scale]` - Exports your image with a scaling factor.
* ex `export brick 32`. If the last argument is a number, It will be used as the scale. So you can do something like `export red bricks 32`
* `os` - Opens KDE's save directory in your OS.

# Configuration
I designed this to be highly customizable from the ground up. You can change any of the UI colors, keyboard shortcuts & other settings in the `config.ini` file. Please note that at the moment the config file is a disorganized mess. Thats because internally, The contents of the config file a stored in a key-value pair table, And lua doesnt iterate over them in any specific order when writing it out to a file. I'm working on fixing that.
the current gameplan is to skip the whole .ini nonsense and just use a .lua file. One wonders why i didn't just do that from the start.

# Color palettes
KDP Can load and use color palettes from images, As long as they're at an 1x scale. Such as any palettes on [lospec](https://lospec.com/palette-list). 
To load in a palette, Place it in the "palettes" folder in KDP's save directory (accessible via the "os" command), And either change the "default" field under the [palette] header in config.ini to "palettes/your_palette.png", Or use the `loadPalette your_palette` command.

# Caveats
So i decided to make this thing with [löve](https://love2d.org/) because i'm very comfortable with it, So i knew i'd have a working prototype in no time. But löve probably isn't the right tool for this type of program.
Main issue is [file system access](https://love2d.org/wiki/love.filesystem), Löve only gives you access to a single directory in the filesystem for writing files.
So you cant open an image in an arbitrary location on your computer and edit it with KDP. However, If you drag and drop a .png onto KDP it will happily load it.
Another thing worth noting is, Currently KDP doesn't do great with larger images, There's no zooming, And it tends to lag when larger images are loaded.
So editing a whole tile atlas is a hassle.
