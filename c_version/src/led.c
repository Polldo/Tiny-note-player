//----------------------------------------
//
//		author: Paolo Calao			
//		mail:	paolo.calao@gmail.com
//		
//----------------------------------------

#include "led.h"

#define PIN_LED 4
#define PIN_MASK (1 << PIN_LED)

void led_init(void) {
	DDRB |= PIN_MASK;
	PORTB |= PIN_MASK;
}

void led_on(void) {
	PORTB |= PIN_MASK;
}

void led_off(void) {
	PORTB &= ~PIN_MASK;
}

void led_toggle(void) {
	PINB |= PIN_MASK;
}

