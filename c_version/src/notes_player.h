//----------------------------------------
//
//		author: Paolo Calao			
//		mail:	paolo.calao@gmail.com
//		
//----------------------------------------

#ifndef NOTES_H
#define NOTES_H

#include <avr/pgmspace.h>
#include <avr/interrupt.h>
#include <avr/io.h>
#include "globals.h"

void notes_player_init(void);

void play_next_note(void);

void stop_note(void);

void play_note(byte temp_note, byte temp_duration);

void timer_note_init(void);

void timer_note_start(byte temp_note);

void timer_note_stop(void);

void timer_duration_init(void);

void timer_duration_start(void);

void timer_duration_stop(void);

#endif
