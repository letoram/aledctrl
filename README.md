These are various hacked-up projects that use the pipe-
fifo LED protocol as part of arcan >= 0.5.2.

# Subprojects

  g810 - GPLv3, see README.md and LICENSE file. Adds support
	 for reading protocol controls via stdin.

  arduino - arduino project and makefiles for programming an
	    arduino device to use the protocol over a serial or
            i2c connection in order to control PWM adafruit
	    neopixel- LEDs.

	testgen - simple stress-test to randomly flash lights,
	          make and run like ./test | g810-led --aled -

# Setup/Use

fifos can be configured via:

    mkfifo /path/to/fifo
    mkfifo /path/to/fifo2

and so on.

to tell arcan about the presence of the LED devices (scanned on startup):

    arcan_db add_appl_kv arcan ext_led /path/to/fifo
    arcan_db add_appl_kv arcan ext_led_2 /path/to/fifo2

for the arduino setup, the USB- serial port can be configured like:

    stty -F /dev/ttyACM0 cs8 9600 ignbrk -brkint -imaxbel -opost
		 -onlcr -isig -icanon -iexten -echo -echoe -echok -echoctl
		 -echoke noflsh -ixon -crtscts

and then fed like:

    cat /path/to/fifo > /dev/ttyACM0

the g810 module, similarly:

    cat /path/to/fifo | g810-led --arcan-stdin

# Protocol

Each packet is a 2-byte tuple of opcode and argument.

first byte is one of (ascii) 'A' 'a' 'r' 'g' 'b' 'i' 'c' or 'o'.

    'A' [ign] : set active LED index to 'all'
    'a' [num] : set active LED index to [num] (special, 255 - is ignored)
    'r' [num] : set current Red value to [num]
    'g' [num] : set current Green value to [num]
    'b' [num] : set current Blue value to [num]
    'i' [num] : set all (Red, Green, Blue) value to [num]
    'c' [num] : num = 0, commit - no buffer, > 0 - buffer
    'o' [ign] : disconnects

with the buffer indication meaning that more values are to come before
any update to led devices should be pushed.

The arcan scripts can then use set\_led\_rgb(dev, ind, r, g, b, buf) calls
to emit data to the respective devices. Advanced such use can be found in
[durden](http://github.com/letoram/durden) iostatem.lua + devmaps/led/...

# Profiles

devmaps/ contain example such devmaps for the setup shown above.
A video of its use can be found at [gfycat](https://gfycat.com/AgonizingPleasingGuppy)

