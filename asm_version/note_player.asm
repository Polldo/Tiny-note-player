;
; note_player.asm
;
; Author : Paolo Calao
; Description : This is a simple assembly program for the Attiny85 mcu. Its goal is to output a voltage driving a piezo, in order to make it playing notes.
;

#include "tn85def.inc"

.def  FLAGREG	= r19
.equ  UPDATEBIT	= 0

;macro to set bits of an i/o register
;@0 indicates the i/o register
;@1 indicates the intermediate register used to load bits in the i/o one
;@2 indicates the bits to load
.macro set_io_bits
	in @1,@0
	sbr @1,@2
	out @0,@1
.endmacro

;macro to clear bits of an i/o register
;@0 indicates the i/o register
;@1 indicates the intermediate register used to clear bits in the i/o one
;@2 indicates the bits to clear
.macro clear_io_bits
	in @1,@0
	cbr @1,@2
	out @0,@1
.endmacro


.org 0x0000
	rjmp INIT
.org 0x0004
	rjmp TIMER1_OVF

INIT:
	sbi DDRB,DDB0 ;set pin b0 output direction
	sbi DDRB,DDB1 ;set pin b1 output direction
	sbi DDRB,DDB2 ;set pin b2 output direction
	;INIT_TIMER0_CTC_MODE: ;configures CTC mode to outputs notes frequency through OC0A (PB0)
	set_io_bits TCCR0A,r16,(1<<COM0A0)+(1<<WGM01) 
	;INIT_TIMER1: ;used in normal counter mode to count notes duration, IMPORTANT: r0 needed to extend the counter
	set_io_bits TIMSK,r16,(1<<TOIE1) ;overflow interrupt enable
	;LOAD_FIRST_NOTE_AND_ACTIVATE_TIMERS:
	ldi zh,high(SONG*2) ;z points to the first note
	ldi zl,low(SONG*2)
	lpm r16,z+
	;load timer0 with the first note frequency
	out OCR0A,r16
	;load timer1 with the first note duration
	lpm r0,z+
	;activate timer0
	set_io_bits TCCR0B,r16,(1<<CS01)+(1<<CS00) ;set Timer0 Clock Signal to ck/64 
	;activate timer1
	set_io_bits TCCR1,r16,(1<<CS13)+(1<<CS12)+(1<<CS11) ;set Timer1 Clock Signal to ck/8192
	;configure leds
	sbi PORTB,PORTB1
	sei ;(bset SREG_I) global interrupt enable

START:
	sbrc FLAGREG,UPDATEBIT
	rcall UPDATE_NOTE
	rjmp START

UPDATE_NOTE:
	push r17
	push r18
	in r18,SREG ;save status and registers 
	clear_io_bits TCCR0B,r17,(1<<CS01)+(1<<CS00) ;temporarily stop timer0 to change its frequence
	cbi PORTB,PORTB0 ;clear the output to stop playing the old note
	ldi r17,0 ;reset timer0
	out TCNT0,r17
	lpm r17,z+ ;read the next frequency
	;check if the new note is a pause (0) or the last note (255)
	;if not pause -> jmp to check if it's the last note - else PAUSE output
	;if not end of notes -> jmp ahead - else reload first note
CHECK_PAUSE:
	tst r17
	brne CHECK_LAST_NOTE
	lpm r0,z+ ;load the duration register with the pause duration
	rjmp END_UPDATE
CHECK_LAST_NOTE:
	cpi r17,0xff
	brne LOAD_FREQUENCY_AND_DURATION
	ldi zh,high(SONG*2)
	ldi zl,low(SONG*2)
	lpm r17,z+ ;reload the first note
LOAD_FREQUENCY_AND_DURATION:
	out OCR0A,r17
	lpm r0,z+ 
	;RESTART_TIMER:
	set_io_bits TCCR0B,r17,(1<<CS01)+(1<<CS00) ;restart the timer
	sbi PINB,PINB1
	sbi PINB,PINB2
END_UPDATE:
	cbr FLAGREG,(1<<UPDATEBIT) ;clear the update flag
	set_io_bits TCCR1,r17,(1<<CS13)+(1<<CS12)+(1<<CS11) ;activate timer1 
	out SREG,r18
	pop r18
	pop r17
	ret

TIMER1_OVF:
	push r18
	in r18,SREG ;save status and registers 
	dec r0 ;decrement the duration register
	brne END_OVF ;if duration is not over, continue to play the current note
	push r17
	sbr FLAGREG,(1<<UPDATEBIT) ;else mark the update note flag 
	clear_io_bits TCCR1,r17,(1<<CS13)+(1<<CS12)+(1<<CS11) ;and deactivate timer1	
	pop r17
END_OVF:
	out SREG,r18
	pop r18
	reti

SONG: .db 238,2,238,2,212,4,238,4,\
		  178,4,188,8,238,2,238,2,\
		  212,4,238,4,158,4,178,8,\
		  238,2,119,4,141,4,178,4,\
		  188,4,212,12,133,2,133,2,\
		  141,4,178,4,158,4,178,8,\
		  0,8,\
		  0xFF
