ts = Time.now()
start = ((ts.hour - 7) % 12) * 3600 + (ts.min * 60) + ts.sec 
system "echo 'Starting omxplayer'"
system "/usr/bin/omxplayer /home/pi/time.mp4 --blank --pos #{start} --no-osd"

