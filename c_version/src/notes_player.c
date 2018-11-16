#include "notes_player.h"

#define PIN_SPEAKER DDB0
#define LAST_NOTE 0xFF
#define PAUSE_NOTE 0x00
#define LAST_NOTE_DURATION 2 //PAUSE_DURATION_AFTER_LAST_NOTE

static volatile byte note_duration;
static byte note_offset;
static const byte notes[9] PROGMEM = {
	238,2,238,2,212,4,238,4,0xFF
};


void notes_player_init(void) {
	timer_note_init();
	timer_duration_init();
	note_offset = 0;
}

void play_next_note(void) {
	if (!note_duration) {
		timer_note_stop();
		byte next_note = pgm_read_byte(&(notes[note_offset++]));
		if (next_note == LAST_NOTE) {
			note_offset = 0;
			play_note(PAUSE_NOTE, LAST_NOTE_DURATION);
		} else {
			byte next_duration = pgm_read_byte(&(notes[note_offset++]));
			play_note(next_note, next_duration);
		}
	}
}

void play_note(byte temp_note, byte temp_duration) {
	if (temp_note != PAUSE_NOTE) {
		timer_note_start(temp_note);
	}
	note_duration = temp_duration;
	timer_duration_start();
}

ISR(TIM1_OVF_vect) {
	if (!(--note_duration)) {
		TCCR1 &= ~((1<<CS13)+(1<<CS12)+(1<<CS11)); //avoiding call to timer_duration_stop()
	}
}

void timer_note_init() {
	DDRB |= (1<<PIN_SPEAKER);
	TCCR0A |= (1<<COM0A0) + (1<<WGM01);
}

void timer_note_start(byte temp_note) {
	OCR0A = temp_note;
	TCCR0B |= (1<<CS01)+(1<<CS00);
}

void timer_note_stop() {
	TCCR0B &= ~((1<<CS01)+(1<<CS00));
	PORTB &= ~(1<<PIN_SPEAKER);
	TCNT0 = 0x00;
}

void timer_duration_init() {
	TIMSK |= (1<<TOIE1);
}

void timer_duration_start() {
	TCCR1 |= (1<<CS13)+(1<<CS12)+(1<<CS11);
}

void timer_duration_stop() {
	TCCR1 &= ~((1<<CS13)+(1<<CS12)+(1<<CS11));
}
