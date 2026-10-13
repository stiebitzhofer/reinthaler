# Legacy Raspberry Pi implementation

This directory preserves the original repository files from 2013–2016 for
historical reference and maintenance of existing installations.

**Archived: these are not instructions for a new installation.** The notes
refer to Raspbian Wheezy, omxplayer, old service managers and external resources
that may no longer be available. In particular, do not copy the disk-writing
commands into a modern setup without independently verifying their targets.

## Contents

- [`raspberry-pi-setup.md`](raspberry-pi-setup.md): the former root README,
  preserved unchanged, including installation notes, links and code excerpts.
- [`startplayer.rb`](startplayer.rb): the original Ruby launcher, preserved
  unchanged.

In the old notes, references to `startplayer.rb` mean the script now stored in
this directory.

## Original behaviour

The launcher reads local time once, maps it onto a 12-hour video beginning at
07:00:00, and starts `/usr/bin/omxplayer` with
`/home/pi/time.mp4`. It does not explicitly enable looping, wait for clock
synchronisation, correct drift or supervise the player.

The historical installation used a separately maintained omxplayer fork. That
fork's source and binaries are **not included** in this archive; the code
excerpt in the setup notes is not a complete copy of it. These files alone
are therefore not a reproducible backup of a deployed installation.

The new direction is documented in the [project README](../README.md): a
standard mpv package with a separate clock-synchronisation controller.

## Rights

The repository's [Unlicense](../LICENSE) covers the project's original software.
Third-party excerpts retain their original licences; moving them into this
archive does not relicense them. Artwork and media are not included.
