# [uLauncher](https://github.com/Ulauncher/Ulauncher) music player controller extension for linux

<p align="center">
   <img src="https://camo.githubusercontent.com/e3aaec6f9bb13a90b78918a423824f4c7fa4aa803d48853756c651a0aa6c0230/68747470733a2f2f73362e67696679752e636f6d2f696d616765732f616e696d313666396136323636633234393838652e676966" alt="animated" />
</p>


[Still in development]
 

# Install
Open uLauncher preferences window -> extensions -> add extension and paste the following url:
`https://github.com/Dankni95/ulauncher-playerctl`


## Install Dependencies
### Playerctl might not come preinstalled on your system, so you might have to

    sudo apt install playerctl
    
    sudo pacman -S playerctl
    
    sudo dnf install playerctl
    
    sudo zypper install playerctl

### depending on your distro

## Start up 
Start uLauncher and type `m`.


## Development
Git clone this repo.

In repo folder do `make link` to create symlink to ulauncher extensions folder.

Close uLauncher and run `make dev` and follow instructions in terminal.

You will get code that looks something like this:
```
VERBOSE=1 ULAUNCHER_WS_API=ws://127.0.0.1:5054/com.github.dankni95.ulauncher-playerctl PYTHONPATH=/usr/lib/python3.10/site-packages /bin/python /home/daniel/.local/share/ulauncher/extensions/com.github.dankni95.ulauncher-playerctl/main.py

```
Paste it in new terminal window and run keyword `m` in uLauncher. 
Happy coding!

This is one of my first python projects, in advance sorry for the spaghetti code!


# Credits
#### This extension uses uLauncher as main driver https://github.com/Ulauncher/Ulauncher
