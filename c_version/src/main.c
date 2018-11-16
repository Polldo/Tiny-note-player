#include <avr/io.h>
#include "notes_player.h"
#include "globals.h"

int main(void) {
//init
	notes_player_init();
	sei();	
	while(1){
	//loop
		play_next_note();

	}
}
