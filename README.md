# reinthaler

Playback software and installation notes for Arnold Reinthaler's
[*under construction*](https://reinthaler.org/?p=218).

The installation plays a video of a watch in step with local time. The artist
describes the work as a 24 × 24 × 5 cm installation with a 720-minute (12-hour)
PAL video loop, in colour and with sound. This repository contains the technical
companion to the artwork; the video itself is not included.

## Project status

The original Raspberry Pi setup from 2013–2016 is preserved in
[`legacy/`](legacy/README.md). It used a Ruby launcher and a modified omxplayer.
Those files are historical reference material and are no longer the recommended
installation procedure.

The replacement is planned around a standard **mpv** package, with no
project-maintained player fork. The [installation guide](docs/installation.md)
covers preparing the Zero W, video conversion, network time and manual playback
tests. It is a draft awaiting hardware validation; the modern synchronisation
controller and permanent startup service are not yet implemented.

## Planned setup

- **Raspberry Pi Zero W**, running a supported 32-bit Raspberry Pi OS Lite image.
- **Local video on microSD**, converted to a compatible H.264 format if needed.
  Conversion should preserve the work's timing, aspect ratio and sound.
- **mpv** for playback, controlled through its local
  [JSON IPC interface](https://mpv.io/manual/stable/#json-ipc).
- **Wi-Fi and NTP** to synchronise the system clock.
- **A small controller** to map local time to the video position, keep playback
  aligned, and recover after interruptions.
- **A systemd service** to start the controller automatically and restart it
  after a failure.

The Zero W is the intended first target. Hardware decoding, seeking, audio and
the loop transition still need to be checked with the actual video and display
on the selected OS/mpv versions.

## Keeping time

After boot, playback should wait for successful network time synchronisation,
then start at the position matching the current local time. NTP keeps the
system clock accurate; the controller must separately check and correct video
drift. The timezone and daylight-saving behaviour should be explicit.

The legacy launcher assumes a 12-hour cycle whose first frame represents
07:00:00. For that mapping:

```text
video position = (seconds since local midnight - 7 × 3600) modulo 43200
```

The first frame and exact duration must be verified against the playback file,
especially after conversion. The initial seek position must not become the
start of every subsequent loop.

If Wi-Fi is lost during playback, the device can continue using its system
clock. Without a battery-backed real-time clock, a fresh boot needs successful
NTP synchronisation before the displayed time can be trusted.

## Next steps

1. Inspect the source video and prepare a playback copy, preserving the master.
2. Verify mpv playback and hardware decoding on the Zero W.
3. Implement configurable clock mapping, drift correction and restart handling.
4. Test complete loops, power cuts, network loss and daylight-saving changes.
5. Validate the [installation guide](docs/installation.md) and record the tested
   OS, packages, configuration and recovery procedure.

## Archive

See the [legacy overview](legacy/README.md) for the original launcher, setup
notes and their limitations. The planned setup does not depend on the former
omxplayer fork.

## Software and artwork rights

The project's original software is available under the [Unlicense](LICENSE).
Third-party software and quoted code retain their respective licences. Using
an unmodified player does not remove its licence obligations when distributing
it with an installation or disk image.

The software licence does **not** grant rights to Arnold Reinthaler's artwork,
video, photographs or other artistic material. Those require separate
permission from the relevant rights holders. Consult the
[artist's work page](https://reinthaler.org/?p=218) for the artwork itself.
