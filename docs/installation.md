# Raspberry Pi installation guide

This guide prepares a Raspberry Pi to play Arnold Reinthaler's
[*under construction*](https://reinthaler.org/?p=218) using an unmodified mpv
package and network time.

**Status: draft for the first hardware test.** The target is the original
Raspberry Pi Zero W, not the Zero 2 W. No OS/player/video combination has been
validated on the device yet. Sections 1–7 cover provisioning and a manual
playback/synchronisation test. Section 8 specifies automatic operation, which
requires a controller that is not yet implemented in this repository.

Do not use this draft as evidence that an installation is ready for exhibition.
Complete the [acceptance checks](#9-acceptance-checks) and record the working
versions first.

## 1. Hardware and media

Prepare:

- Raspberry Pi Zero W and a reliable micro-USB power supply.
- A mini-HDMI cable or adapter, the installation's display and its power supply.
- A microSD card and card reader. Size the card for the full playback file,
  the OS and free working space; 32 GB may not be enough for a 12-hour video.
- A 2.4 GHz Wi-Fi network with access to an NTP server. Captive portals are
  unsuitable for unattended startup. Keep the Pi clear of metal that blocks Wi-Fi.
- Another computer for writing the card, SSH access and video conversion.
- The authorised video master, kept separately from the playback copy.

For scale, 12 hours at an average video bitrate of 4 Mbit/s uses approximately
21.6 GB, before audio and container overhead. Check the actual converted file
size rather than assuming a card capacity from the video's dimensions.

The artwork includes sound. Plan for HDMI audio or a supported USB audio device;
the Zero W has no built-in 3.5 mm audio socket. Its HDMI connector is **mini**,
not micro. See the [Raspberry Pi hardware setup documentation](https://www.raspberrypi.com/documentation/computers/getting-started.html).

No RTC module is assumed. With this design, each cold boot needs network time
before the displayed watch can be trusted.

## 2. Install Raspberry Pi OS

On the preparation computer, use
[Raspberry Pi Imager](https://www.raspberrypi.com/software/):

1. Select the original **Raspberry Pi Zero W** as the device.
2. Select **Raspberry Pi OS Lite (32-bit)** compatible with that device. The
   original Zero W cannot run a 64-bit image. Use the current supported image;
   record its exact release date and checksum in the installation record.
3. Select the intended microSD card. Writing the image erases that card.
4. Set hostname `reinthaler`, create an administrator named `artadmin`, and
   configure the installation's Wi-Fi and wireless country.
5. Set the installation's timezone; examples here use `Europe/Vienna`.
6. Enable SSH, preferably using your public key. Keep credentials out of Git.
7. Write and verify the card, then insert it into the powered-off Pi.

Connect the display and audio before powering up. Allow the first boot to finish.
From the preparation computer:

```sh
ssh artadmin@reinthaler.local
```

If mDNS does not resolve the name, find the Pi's address in the router's DHCP
leases and use that address. All subsequent shell commands run on the Pi through
SSH unless a section explicitly says otherwise. Replace `artadmin` consistently
if you chose a different account.

Check the image and update it:

```sh
cat /etc/os-release
uname -m
sudo apt update
sudo apt full-upgrade
sudo apt install mpv ffmpeg python3 socat alsa-utils v4l-utils kbd systemd-timesyncd
sudo reboot
```

Reconnect after reboot. `uname -m` should report `armv6l` on the original Zero W.
This recipe uses systemd-timesyncd; do not run a second NTP client alongside it.
Review any package replacement proposed by apt if starting from a customised OS.

The [OS download page](https://www.raspberrypi.com/software/operating-systems/)
lists image compatibility and checksums. Do not copy the Wheezy image, boot
settings or service-manager instructions from `legacy/`.

## 3. Configure Wi-Fi and time

Check the network configured by Imager:

```sh
nmcli device status
nmcli connection show --active
```

To join a different network, use `sudo nmtui` interactively. Set the correct
wireless country in `sudo raspi-config` if it was not configured in Imager.
See the [Raspberry Pi configuration documentation](https://www.raspberrypi.com/documentation/computers/configuration.html).

Enable time synchronisation and set the timezone:

```sh
sudo timedatectl set-timezone Europe/Vienna
sudo systemctl enable --now systemd-timesyncd.service
sudo timedatectl set-ntp true
timedatectl status
timedatectl timesync-status
timedatectl show --property=NTPSynchronized --value
```

The last command must return `yes` before a manual clock-alignment test.
`NTP service: active` by itself is insufficient. If synchronisation fails:

```sh
journalctl -u systemd-timesyncd.service -b --no-pager
```

Check DNS and whether the network permits NTP traffic (UDP port 123). A venue's
local NTP server is also suitable; configure it in a drop-in under
`/etc/systemd/timesyncd.conf.d/` if required by that venue.

For eventual automatic startup, enable the service that waits for actual time
synchronisation:

```sh
sudo systemctl enable --now systemd-time-wait-sync.service
```

This command can wait while the network is unavailable; inspect it from a second
SSH session if necessary. Merely ordering playback after `network-online.target`
or `time-sync.target` does not establish accurate time without a working wait
mechanism. See [systemd-time-wait-sync](https://manpages.debian.org/trixie/systemd-timesyncd/systemd-time-wait-sync.service.8.en.html).

Once synchronised, playback can continue through a Wi-Fi outage using the
system clock, with increasing uncertainty over time. After power loss, wait for
NTP again. A timestamp saved on disk is not a substitute for a running RTC.

## 4. Prepare the playback video

Do this work on the preparation computer, with FFmpeg installed. Retain the
master and create a separate playback copy. Do not commit either file here.

Inspect the master:

```sh
ffprobe -v error \
  -show_entries format=duration,start_time,size:stream=index,codec_type,codec_name,profile,width,height,pix_fmt,avg_frame_rate,sample_aspect_ratio,display_aspect_ratio,field_order,duration,start_time \
  -of json "/path/to/master.mov"
```

Record the codec, dimensions, frame rate, interlacing, aspect ratio, sound tracks,
start timestamps and exact duration. The artist describes a 720-minute PAL loop,
but that does not establish the properties of this particular file.

A suitable starting target is H.264, 8-bit YUV 4:2:0, at the source resolution
and frame rate, with its intended audio retained. A video described only as
"1080 pixels" is not enough to establish decoder compatibility; both dimensions,
frame rate, profile and bitrate matter.

For an already progressive, 25 fps source with even dimensions no larger than
1920 × 1080, this is a **candidate conversion**, to be visually and technically
checked afterwards:

```sh
ffmpeg -n -i "/path/to/master.mov" \
  -map 0:v:0 -map '0:a:0?' \
  -c:v libx264 -preset slow -crf 18 \
  -pix_fmt yuv420p -profile:v high -level:v 4.0 \
  -maxrate 8M -bufsize 16M -g 25 \
  -c:a aac -b:a 192k -movflags +faststart \
  "/path/to/time.mp4"
```

This selects the first video and, if present, first audio track; check that those
are the intended tracks. `-g 25` gives a maximum one-second GOP at 25 fps to help
seeking. No frame-rate change, scaling, trimming or speed change is requested.
The command is not appropriate unchanged for every master. In particular,
interlaced PAL needs a deliberate conversion decision; do not silently drop
fields or stretch non-square pixels. See the [FFmpeg documentation](https://ffmpeg.org/ffmpeg.html).

Run the same ffprobe inspection on the output. Check the first and last frames,
sound, display aspect ratio, and several visible clock readings across the file.
For the legacy mapping, video position 0 should show 07:00:00, position 3600
should show 08:00:00, and the full cycle should be 43200 seconds. Measure rather
than stretching a mismatched duration to fit. Agree any editorial change with
the artist.

Generate a checksum on the preparation computer:

```sh
shasum -a 256 "/path/to/time.mp4"
```

## 5. Create the playback account and transfer media

On a fresh Pi, create a separate, non-login account and directories:

```sh
sudo useradd --system --create-home --home-dir /var/lib/reinthaler \
  --shell /usr/sbin/nologin --user-group \
  --groups video,render,audio reinthaler
sudo install -d -o root -g reinthaler -m 0750 /srv/reinthaler
sudo install -d -o root -g root -m 0755 /etc/reinthaler
```

Run account creation once. If an account or device group already differs on the
chosen image, inspect `id reinthaler` and `getent group video render audio`
before adapting these commands.

From the preparation computer, upload the converted file:

```sh
scp "/path/to/time.mp4" artadmin@reinthaler.local:time.mp4
```

Then on the Pi, for the first installation:

```sh
sudo mv -i /home/artadmin/time.mp4 /srv/reinthaler/time.mp4
sudo chown root:reinthaler /srv/reinthaler/time.mp4
sudo chmod 0640 /srv/reinthaler/time.mp4
sudo -u reinthaler sha256sum /srv/reinthaler/time.mp4
df -h /srv/reinthaler
```

Compare the checksum with the preparation computer. Stop playback before
replacing media in an existing installation and preserve its previous working
copy elsewhere.

## 6. Prove display, decoding and sound

Keep the display connected and on. Inspect the installed player and devices:

```sh
mpv --version
mpv --no-config --vo=help
mpv --no-config --hwdec=help
mpv --no-config --vd=help
v4l2-ctl --list-devices
ls -l /dev/dri
aplay -l
sudo -u reinthaler mpv --no-config --audio-device=help
```

Use `sudoedit /etc/reinthaler/mpv.conf` to create this candidate configuration:

```ini
# Candidate for Raspberry Pi OS Lite; verify on the selected hardware/image.
vo=gpu
gpu-context=drm
gpu-api=opengl
hwdec=auto
ao=alsa
fullscreen=yes
osc=no
osd-level=0
input-default-bindings=no
input-vo-keyboard=no
loop-file=inf
save-position-on-quit=no
```

Use the GPU output with a DRM context for direct display on Lite. The plain
`vo=drm` output is a different path without hardware acceleration. `hwdec=auto`
is a request, not proof that decoding is accelerated. Raspberry Pi package
builds and decoder availability must be inspected on the chosen image.
See the [mpv manual](https://mpv.io/manual/stable/).

If the default audio device is wrong, add `audio-device=` with the exact ALSA
device name reported above. Test at a suitable volume on the actual sound system.
Keep the image's KMS configuration initially; do not add legacy MMAL/OpenMAX
settings or blindly increase `gpu_mem`.

Run the following **through SSH**, not from a login on the display's console.
Stop the console login on tty1 so it does not compete with playback, select
that virtual terminal, and start a temporary test service:

```sh
sudo systemctl stop getty@tty1.service
sudo chvt 1
sudo systemd-run --unit=reinthaler-playback-test --collect \
  --property=User=reinthaler \
  --property=Group=reinthaler \
  --property=SupplementaryGroups="video render audio" \
  --property=RuntimeDirectory=reinthaler-playback-test \
  --property=RuntimeDirectoryMode=0700 \
  --property=UMask=0077 \
  --property=StandardInput=tty \
  --property=TTYPath=/dev/tty1 \
  --property=TTYReset=yes \
  --property=TTYVHangup=yes \
  --property=TTYVTDisallocate=yes \
  /usr/bin/mpv --no-config --include=/etc/reinthaler/mpv.conf \
  --terminal=no --pause=yes \
  --input-ipc-server=/run/reinthaler-playback-test/mpv.sock \
  /srv/reinthaler/time.mp4
```

This service starts paused and **does not synchronise to wall-clock time**.
Its purpose is to test the player and device access before writing the controller.
It is transient: it is not installed for the next boot. Inspect startup failures:

```sh
systemctl status reinthaler-playback-test.service
journalctl -u reinthaler-playback-test.service -b --no-pager
```

Unpause via the local control socket:

```sh
printf '%s\n' '{"command":["set_property","pause",false]}' |
  sudo -u reinthaler socat -T 2 - UNIX-CONNECT:/run/reinthaler-playback-test/mpv.sock
```

Query decoding and frame drops after playback has run for several minutes:

```sh
printf '%s\n' \
  '{"command":["get_property","hwdec-current"],"request_id":1}' \
  '{"command":["get_property","video-codec"],"request_id":2}' \
  '{"command":["get_property","decoder-frame-drop-count"],"request_id":3}' \
  '{"command":["get_property","frame-drop-count"],"request_id":4}' |
  sudo -u reinthaler socat -T 2 - UNIX-CONNECT:/run/reinthaler-playback-test/mpv.sock
```

The numbered replies identify each result. Check the journal and CPU use with
`top` too. An empty/`no` hardware-decoder result or unavailable property needs
investigation; a moving picture alone does not demonstrate the intended path.
Do not enable unattended operation if decoding falls behind or seeking stalls.
Record the successful decoder/output settings rather than inventing a universal
Zero W acceleration flag.

To stop the test and restore the console:

```sh
sudo systemctl stop reinthaler-playback-test.service
sudo systemctl start getty@tty1.service
```

Repeat the transient-service command after configuration changes. If the display
blanks during long tests, append `consoleblank=0` to the existing single line in
`/boot/firmware/cmdline.txt`, using `sudoedit`, then reboot. Do not replace the
line or its root-device arguments. Check the display's own sleep timer as well.

## 7. Test clock mapping and the loop

Start the paused test service from section 6 again. Confirm NTP is synchronised.
For a file verified to start at 07:00:00 and run for exactly 12 hours:

```text
target = (seconds since local midnight - 25200) modulo 43200
```

The following manual test computes the position on the Pi, seeks, and unpauses.
It assumes the verified mapping above. Run it on the Pi through SSH:

```sh
test "$(timedatectl show --property=NTPSynchronized --value)" = yes &&
  python3 -c 'import datetime, json
now = datetime.datetime.now()
seconds = now.hour * 3600 + now.minute * 60 + now.second + now.microsecond / 1e6
target = (seconds - 25200) % 43200
print(json.dumps({"command": ["seek", target, "absolute+exact"], "request_id": 10}))
print(json.dumps({"command": ["set_property", "pause", False], "request_id": 11}))' |
  sudo -u reinthaler socat -T 2 - UNIX-CONNECT:/run/reinthaler-playback-test/mpv.sock
```

This is a one-time alignment, not a controller. Time spent seeking and display
latency can leave an offset. Compare the visible watch against a trusted clock,
record the offset, and repeat after several hours. NTP alone will not correct
video drift.

To exercise the boundary without waiting 12 hours, seek near the end while
playback is running (43190 is ten seconds before the end of a 43200-second file):

```sh
printf '%s\n' '{"command":["seek",43190,"absolute+exact"]}' |
  sudo -u reinthaler socat -T 2 - UNIX-CONNECT:/run/reinthaler-playback-test/mpv.sock
```

Check the last frames, return to the first frame, sound continuity and any black
frame or pause. Normal looping must return to the beginning of the full work,
not to the time at which the installation was switched on. Restore clock
alignment with the preceding command afterwards.

mpv's file loop is not a guarantee of an invisible transition. Decide the
acceptable visible interruption and clock error with the artist, then measure
those on the final video/display combination.

## 8. Automatic startup: deployment specification

**Pending implementation.** The repository currently contains no modern
controller or installable playback service. Do not substitute the archived Ruby
launcher or configure systemd to call a nonexistent executable. Sections 1–7
remain usable for preparing the Pi and gathering the first playback results.

The eventual installation should add a controller under
`/usr/local/lib/reinthaler/`, a configuration file under `/etc/reinthaler/`,
and a persistent `reinthaler.service` with these responsibilities:

| Part | Required behaviour |
| --- | --- |
| Boot ordering | Require the time-wait service and start after `time-sync.target`; a network connection alone is insufficient. |
| User/display access | Run as `reinthaler` with the tested device groups and tty1 setup from section 6. Resolve the getty conflict explicitly. |
| Player startup | Launch the packaged mpv with the tested configuration, paused, using a private socket in `/run/reinthaler/`. |
| Clock mapping | Configure media path, cycle length, first-frame clock time and timezone. Use fresh local time after the file is ready. |
| Alignment | Seek to the current target, unpause, measure the resulting error and account for seek/display delay. |
| Drift | Compare position regularly using the shortest signed error around the loop boundary. Avoid repeatedly seeking while a previous seek is pending. |
| Correction policy | Keep normal speed unless a different policy is artist-approved. Make the error threshold and visible correction behaviour explicit; sound is part of the work. |
| Time changes | Handle NTP clock adjustments and daylight-saving jumps; local civil time repeats or skips an hour at DST transitions. |
| Recovery | Detect player exit and lack of playback progress, terminate stale processes, and restart from current time. Use bounded retries/backoff. |
| Service lifecycle | `Restart=on-failure`, a restart delay and control-group cleanup; stopping the service must also stop mpv. |
| Network loss | Continue after initial synchronisation; a cold boot without NTP stays waiting. Never restore a stale saved video position. |
| Logs | Report startup, sync state, corrections and faults to the journal without logging every frame. |

Once these files exist and the manual playback path passes, the installation
guide must be updated with their exact copy/configuration commands. Only then
install the unit, run `systemd-analyze verify`, reload systemd, enable/start the
service, and test an unattended reboot. Do not mark this section complete based
on successful manual playback alone.

## 9. Acceptance checks

Keep a record with the device. The first test should establish:

- [ ] Exact board model, OS image date/checksum, kernel and installed package versions.
- [ ] Display model, resolution, refresh rate, orientation and audio device.
- [ ] Playback-file checksum, codec, dimensions, frame rate, duration and clock origin.
- [ ] Working decoder/output configuration and no sustained frame dropping.
- [ ] Correct aspect ratio, colour, sound and acceptable seek delay.
- [ ] Acceptable loop transition, including sound, across at least two full cycles.
- [ ] Measured visible clock error over those cycles and agreed correction tolerance.

After the controller is implemented, also check:

- [ ] Cold boot with Wi-Fi: waits for time, then starts at the correct position.
- [ ] Cold boot without Wi-Fi: waits; joining the network later allows startup.
- [ ] Network loss during playback: continues; reconnection is handled correctly.
- [ ] Player exit and a simulated stall: recover without duplicate player processes.
- [ ] Daylight-saving forward/backward transitions and a substantial clock adjustment.
- [ ] A controlled power-cut/recovery test on a backed-up test card.
- [ ] Display sleep, HDMI reconnection and recovery behaviour in the final enclosure.

Use an isolated test environment or simulated clock input for DST tests rather
than changing the clock of a live exhibition machine.

Collect version information on the Pi:

```sh
cat /etc/os-release
uname -a
dpkg-query -W mpv ffmpeg systemd systemd-timesyncd
sudo -u reinthaler sha256sum /srv/reinthaler/time.mp4
timedatectl status
```

Keep the results, final configuration and relevant logs with the installation's
private maintenance records. Wi-Fi credentials and the artwork do not belong in
the public repository.

## 10. Maintenance and recovery

Before exhibition, keep a verified spare card and an offline copy of the working
image, media and configuration. Shut down with `sudo poweroff` and wait for the
device to stop before removing its card for imaging. Record the image checksum
and test restoring it to the spare card.

An overlay/read-only root filesystem can reduce writes, but enable it only after
playback and recovery work. Use `sudo raspi-config` to configure the supported
overlay option, and record how to return to a writable system for maintenance.
With an overlay, ordinary package/configuration changes may disappear on reboot.
Retest Wi-Fi, first NTP sync and startup after enabling it.

For the eventual permanent service, normal maintenance commands will be
`systemctl status`, `journalctl -u reinthaler.service -b`, and
`sudo systemctl stop/start/restart reinthaler.service`. Until that unit exists,
use the transient test service from section 6 instead.

| Symptom | First checks |
| --- | --- |
| Cannot reach the Pi | 2.4 GHz Wi-Fi, country setting, credentials, router leases and power. |
| Clock never synchronises | `timedatectl timesync-status`, timesyncd journal, DNS and NTP access. |
| Black screen / DRM permission error | HDMI connection, tty1 selection, getty conflict, `/dev/dri` permissions and player journal. |
| High CPU / stutter | Actual decoder, encoded format and bitrate, frame drops, power and temperature. |
| Wrong displayed time | Timezone/DST, first-frame origin, media duration and playback drift. |
| Silent playback | Media audio stream, ALSA device, display/speaker volume and HDMI audio configuration. |
| Changes vanish after reboot | Overlay filesystem enabled or a different configuration file loaded. |

Test OS/package updates on the spare card before deploying them. Keep the last
working image available for rollback. When distributing a complete device or
image, include the applicable third-party notices and corresponding source as
required; see the [software and artwork rights](../README.md#software-and-artwork-rights).

## References

- [Artwork: under construction](https://reinthaler.org/?p=218)
- [Raspberry Pi OS images and compatibility](https://www.raspberrypi.com/software/operating-systems/)
- [Raspberry Pi setup](https://www.raspberrypi.com/documentation/computers/getting-started.html)
- [Raspberry Pi configuration](https://www.raspberrypi.com/documentation/computers/configuration.html)
- [mpv manual](https://mpv.io/manual/stable/)
- [FFmpeg command-line documentation](https://ffmpeg.org/ffmpeg.html)
- [systemd time synchronisation gate](https://manpages.debian.org/trixie/systemd-timesyncd/systemd-time-wait-sync.service.8.en.html)
