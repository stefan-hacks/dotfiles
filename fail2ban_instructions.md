### On Debian 12 there are a couple of things you have to do to make it work. This misconfig has not been fixed as of yet

### Create a .local file of the following

```
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

### Then edit jail.local config file

```
sudo nano /etc/fail2ban/jail.local
```

### And add this backend=systemd before enabled=true to make it look like that for example

```
[sshd]
backend=systemd
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
```

### And then save and run this command

```
sudo apt install python3-systemd
```

### finally run fail2ban

```
sudo systemctl enable fail2ban.service
sudo systemctl start fail2ban.service
```

### Then run status check and it should be running

```
systemctl status
```
