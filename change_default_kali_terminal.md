## Change default kali terminal

### 01 - update-alternatives
```bash
sudo update-alternatives --config x-terminal-emulator
```
select /usr/bin/kitty

### 02 - change to root user
```bash
sudo su
```

### 03 - backup files
```bash 
cd /usr/bin/
mv gnome-terminal gnome-terminal.bak
```
### 04 - create a new file 
```bash 
nano gnome-terminal
```
### 04 - paste the following
```bash
#!/usr/bin/env bash
# Translate gnome-terminal args to Kitty
kitty "$@"
```
### 06 - change permissions
```bash
chmod 755 gnome-terminal
```
### 07 - reboot. DONE
```bash
reboot
```

