# KDP
KDP is entirely **k**eyboard **d**riven **p**ixel art editor.

# Why?
As a bit of an experiment. When i'm coding, I use vscode with a vim emulator extension, Or occasionally just vim. So my programming workflow is almost entirely keyboard driven. I was curious if such an approach might work for pixelart. *Curiously* there's not a whole lot of keyboard driven pixel art editors out there so i had to make my own.

# How does it work?
The way it works is *inspired* by my vim and vscode workflow. You have a selection of commands which you access with keystrokes & a built in command palette of sorts. The basics are as follows:
* Arrow keys to move your cursor
* d to draw
* x to erase
* f to fill
* s to enter select mode
* g to enter grab mode (while in select mode)
* if you hold down "c" and use the arrow keys you navigate the color palette
#
Then theres a bunch of commands to speed up navigating around your image. Heres a few of them. I'll explain the rest later.
* If you type "ww" followed by an arrow key, Your cursor will warp to the edge corresponding to the arrow key
* "dd" followed by an arrow key is the same as "ww", Except it fills in the pixels on the way
* "wc" followed by an arrow key works like "ww", except it stops when the color changes.
* "dc" followed by an arrow key is like "wc" except it fills in the pixels on the way
#
Some functions are access via the command palette. To show the command palette you press "tab". Here's a few basics
* `new [width] [height]` - Creates a new image with the specified dimensions. If only `width` is provided, It will be used for height as well.
* ex: `new 16 16`
* 
* `save [filename]` - Saves your image. All images are saved as .png, So theres no need to have an extension in the filename
* ex: `save brick`
* 
* `export [filename] [scale]` - Exports your image with a scaling factor.
* ex `export brick 32`

# Configuration
I designed this to be highly customizable from the ground up. You can change any of the UI colors, keyboard shortcuts & other settings in the `config.ini` file. Please note that at the moment the config file is a disorganized mess. Thats because internally, The contents of the config file a stored in a key-value pair table, And lua doesnt iterate over them in any specific order when writing it out to a file. I'm working on fixing that.
