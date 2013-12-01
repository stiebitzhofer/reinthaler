# Documentation Raspberry Pi Setup

## Format SD Card

Install [https://www.sdcard.org/downloads/formatter_4/eula_mac/](https://www.sdcard.org/downloads/formatter_4/eula_mac/).
Format SD Card with option "Logical Address Adjustment" set.

## Unmount SD Card

```bash
diskutil umount /dev/disk3s1
```

## Copy impage to SD Card

```bash
sudo dd if=2013-09-25-wheezy-raspbian.img of=/dev/disk3s1 bs=1m
```

Use this [http://alltheware.wordpress.com/2012/12/11/easiest-way-sd-card-setup/](http://alltheware.wordpress.com/2012/12/11/easiest-way-sd-card-setup/)

[https://hotfile.com/dl/186745252/b7094e9/RPi-sd_card_builder_v1.2.zip](https://hotfile.com/dl/186745252/b7094e9/RPi-sd_card_builder_v1.2.zip)

## Set proper screen resolution

See [http://elinux.org/RPi_config.txt](http://elinux.org/RPi_config.txt) for reference

```bash

```

## Screen should never blank out

-----
In
```bash
/etc/X11/xinit/xinitrc
```

add
```bash
xset s off         # don't activate screensaver
xset -dpms         # disable DPMS (Energy Star) features.
xset s noblank     # don't blank the video device
```
-----

In
```bash
/etc/lightdm/lightdm.conf
```

Change values for xserver-commands
```bash
[SeatDefaults]
xserver-command=X -s 0 -dpms
```

## Hide cursor on inactivity
```bash
sudo apt-get install unclutter
```

## Start script on startup

Install upstart
```bash
sudo apt-get install upstart
```bash

description "A blinking light"
author "Tom Armitage - tom@infovore.org"
 
start on started mountall
stop on shutdown
 
script
  export HOME="/home/pi"
  export BUNDLE_GEMFILE="/home/pi/src/blink/Gemfile"
  exec bundle exec ruby /home/pi/src/blink/blinken.rb
end script

Source: [http://infovore.org/archives/2013/08/09/running-scripts-on-startup-with-your-raspberry-pi/](http://infovore.org/archives/2013/08/09/running-scripts-on-startup-with-your-raspberry-pi/)

## Install omxplayer

Get it from [http://omxplayer.sconde.net](http://omxplayer.sconde.net) as binary package.

See instructions on Github.

## Backup SD Card

See [http://minordiscoveries.wordpress.com/2013/03/30/backing-up-raspberry-pi-sd-card-on-mac-os-x/](http://minordiscoveries.wordpress.com/2013/03/30/backing-up-raspberry-pi-sd-card-on-mac-os-x/)

```bash
diskutil list
sudo dd if=/dev/rdisk1 of=/path/to/backup.img bs=1m
```