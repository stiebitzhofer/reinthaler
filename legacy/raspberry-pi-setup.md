# Documentation Raspberry Pi Setup

## Installation

### Format SD Card

Install [https://www.sdcard.org/downloads/formatter_4/eula_mac/](https://www.sdcard.org/downloads/formatter_4/eula_mac/).
Format SD Card with option "Logical Address Adjustment" set.

### Unmount SD Card

```bash
diskutil umount /dev/disk3s1
```

### Copy impage to SD Card

```bash
sudo dd if=2013-09-25-wheezy-raspbian.img of=/dev/disk3s1 bs=1m
```

Use this [http://alltheware.wordpress.com/2012/12/11/easiest-way-sd-card-setup/](http://alltheware.wordpress.com/2012/12/11/easiest-way-sd-card-setup/) and [https://hotfile.com/dl/186745252/b7094e9/RPi-sd_card_builder_v1.2.zip](https://hotfile.com/dl/186745252/b7094e9/RPi-sd_card_builder_v1.2.zip)

### Installation daemontools

Install as root or with sudo

```bash
apt-get install daemontools daemontools-run
```

Configure #daemontools config (http://cr.yp.to/daemontools.html)
###############################################
Create a directory
```bash
/etc/service/XXX für run-file
```

Create a file
```bash
/etc/service/XXX/run
```
and set permisssions to
```bash
chmod 1755
```

For reference see [http://cr.yp.to/daemontools.html](http://cr.yp.to/daemontools.html)

### Commands
List running processes:
```bash
ps -Af | grep yyy.py
```

List running daemontools services:
```bash
svstat /etc/service/*
```

Stop Service:
```bash
svc -d /etc/service/XXX
```

Start Service:
```bash
svc -u /etc/service/XXX
```

### run.sh
Updates the system time with

```bash
sudo ntpdate -u time.apple.com
```


## Configuration

### Set proper screen resolution & HDMI audio output

In
```bash
/boot/config.txt
```

enable these setting for the Liliput device
```bash
hdmi_group=2
hdmi_mode=16
```

See [http://weblogs.asp.net/bleroy/archive/2013/04/10/getting-your-raspberry-pi-to-output-the-right-resolution.aspx](http://weblogs.asp.net/bleroy/archive/2013/04/10/getting-your-raspberry-pi-to-output-the-right-resolution.aspx) for reference

and for Audio output on HDMI uncomment
```bash
hdmi_drive=2
```

See
[http://unix.stackexchange.com/questions/60999/omxplayer-and-hdmi-audio-on-the-raspberry-pi/62689#62689](http://unix.stackexchange.com/questions/60999/omxplayer-and-hdmi-audio-on-the-raspberry-pi/62689#62689) for reference. More here
[http://www.raspberrypi.org/forums/viewtopic.php?f=27&t=27213](http://www.raspberrypi.org/forums/viewtopic.php?f=27&t=27213) and [http://www.raspberrypi.org/forums/viewtopic.php?t=5062](http://www.raspberrypi.org/forums/viewtopic.php?t=5062)


### Screen should never blank out

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

and in
```bash
/etc/lightdm/lightdm.conf
```

change the values for xserver-commands
```bash
[SeatDefaults]
xserver-command=X -s 0 -dpms
```

### Hide cursor on inactivity
```bash
sudo apt-get install unclutter
```

Source: [http://infovore.org/archives/2013/08/09/running-scripts-on-startup-with-your-raspberry-pi/](http://infovore.org/archives/2013/08/09/running-scripts-on-startup-with-your-raspberry-pi/)

### Automatic network setup via WiFi
[http://weworkweplay.com/play/automatically-connect-a-raspberry-pi-to-a-wifi-network/](http://weworkweplay.com/play/automatically-connect-a-raspberry-pi-to-a-wifi-network)

## Disable start of X-Windows
```bash
sudo update-rc.d lightdm disable
```


## Backup SD Card

```bash
diskutil list
sudo dd if=/dev/rdisk1 of=/path/to/backup.img bs=1m
```

See [http://minordiscoveries.wordpress.com/2013/03/30/backing-up-raspberry-pi-sd-card-on-mac-os-x/](http://minordiscoveries.wordpress.com/2013/03/30/backing-up-raspberry-pi-sd-card-on-mac-os-x/)

-----

```c++
case 'l':
{
  if(strchr(optarg, ':'))
  {
    unsigned int h, m, s;
    if(sscanf(optarg, "%u:%u:%u", &h, &m, &s) == 3)
      m_incr = h*3600 + m*60 + s;
  }
  else
  {
    m_incr = atof(optarg);
  }
  if(m_loop)
    m_loop_from = m_incr; // Set to 0.
}
break;
```

```ruby
ts = Time.now()
start = ((ts.hour - 7) % 12) * 3600 + (ts.min * 60) + ts.sec 
system "echo 'Starting omxplayer'"
system "/usr/bin/omxplayer /home/pi/time.mp4 --blank --pos #{start} --no-osd"
```



and starts player script startplayer.rb


sudo gem install ruby-dbus


http://www.abelectronics.co.uk/products/3/Raspberry-Pi/15/RTC-Pi-Real-time-Clock-Module#
https://www.sparkfun.com/products/99


http://www.sundh.com/blog/2013/10/loop-videos-seamlessly-omxplayer/


### This is a library
sudo -i npm install forever -g

http://npm.taobao.org/package/omx-manager

### Audio

### Start script on startup

Install upstart
```bash
sudo apt-get install upstart
```

description "A blinking light"
author "Tom Armitage - tom@infovore.org"

start on started mountall
stop on shutdown

script
  export HOME="/home/pi"
  export BUNDLE_GEMFILE="/home/pi/src/blink/Gemfile"
  exec bundle exec ruby /home/pi/src/blink/blinken.rb
end script

## Protect your Raspberry PI SD card, use Read-Only filesystem
https://hallard.me/raspberry-pi-read-only/
