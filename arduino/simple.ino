// NeoPixel Ring simple sketch (c) 2013 Shae Erisson
// released under the GPLv3 license to match the rest of the AdaFruit NeoPixel library

#include "Adafruit_NeoPixel.h"
#ifdef __AVR__
  #include <avr/power.h>
#endif

// Which pin on the Arduino is connected to the NeoPixels?
// On a Trinket or Gemma we suggest changing this to 1
#define PIN            6

// How many NeoPixels are attached to the Arduino?
#define NUMPIXELS     40

#ifdef I2C
#include <Wire.h>
#else
#endif

// When we setup the NeoPixel library, we tell it how many pixels, and which pin to use to send signals.
// Note that for older NeoPixel strips you might need to change the third parameter--see the strandtest
// example for more information on possible values.
Adafruit_NeoPixel pixels = Adafruit_NeoPixel(NUMPIXELS, PIN, NEO_GRB + NEO_KHZ800);

static void parse(uint8_t ch)
{
	static uint8_t buf;
	static int led;
	static uint8_t rgb[3];

	if (!buf){
		buf = ch;
		return;
	}

	switch (buf){
	case 'A': led = -1; break;
	case 'a': led = ch; break;
	case 'r': rgb[0] = ch; break;
	case 'g': rgb[1] = ch; break;
	case 'b': rgb[2] = ch; break;
	case 'i': rgb[0] = rgb[1] = rgb[2] = ch; break;
	case 'c':
		if (led == -1){
			for (int i = 0; i < NUMPIXELS; i++)
				pixels.setPixelColor(led, pixels.Color(rgb[0], rgb[1], rgb[2]));
		}
		else if (led < NUMPIXELS)
			pixels.setPixelColor(led, pixels.Color(rgb[0], rgb[1], rgb[2]));
		if (ch == 0)
			pixels.show();
	break;
	case 'o': break;
	}
	buf = 0;
}

#ifdef I2C
void dataIn(int in)
{
	while (Wire.available()){
		uint8_t ch = Wire.read();
		parse(ch);
	}
}
#else
#endif

void setup() {
  // This is for Trinket 5V 16MHz, you can remove these three lines if you are not using a Trinket
#if defined (__AVR_ATtiny85__)
//  if (F_CPU == 16000000) clock_prescale_set(clock_div_1);
#endif
  // End of trinket special code
  pixels.begin(); // This initializes the NeoPixel library.

#ifdef I2C
	Wire.begin(SLAVE_ADDRESS);
	Wire.onReceive(dataIn);
#else
	Serial.begin(9600);
#endif
}

int init_state = 0;

void loop() {
	if (!init_state){
		for (int i = 0; i < NUMPIXELS; i++)
			pixels.setPixelColor(i, pixels.Color(32, 32, 32));
		init_state = 1;
		pixels.show();
	}

#ifndef I2C
	while (Serial.available() > 0){
		parse(Serial.read());
	}
#endif
}
