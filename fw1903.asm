.include "tn2313def.inc"
.def pos = r17
.def counter = r18
.def led = r20
.def bit_counter = r21
.def byte_counter =r22
.def leddata_reg = r19
.equ ledcntr = PORTD
.equ ledpin = 4
.dseg
led_data: .byte 30 ;reserve 30 bytes
.cseg
.org 0x0000
rjmp main

clr_led:; subroutine to clear the strip
	push pos ;store the previous pos
	ldi pos,0
	mov counter,pos
	clr_loc:
	st y+,pos
	inc counter
	cpi counter,30
	brne clr_loc
	sbiw yl,30 ;point to the 1st memory loc allocated
	pop pos ;recover thee previous pos value
	ret ;return to caller
led_write:
	clc ;clear carry flag
	ldi byte_counter,3;counts three bytes
	ldi pos, 10 ; we'l send 30 bytes
	ld_byte:
	ldi bit_counter,8 ;load bit counter
	ld led,x+ ;load the first byte of data
	check_bit:
	rol led ;rotate the data
	brcc bit_is0
	rcall bit_1 ;else its a 1 snd bit_1 seuence
	rjmp cont ;jump to the cont lable
	bit_is0:
	 rcall bit_0 ;send the sequence for bit 0
	cont:
	dec bit_counter;have we sent 8 bits?
	brne check_bit ;if no then continue checking the bits

	dec byte_counter ;have we finished loading one byte
	brne ld_byte ;if yes then load anothe byte

	ldi byte_counter,3 ;reload the counters
	ldi bit_counter, 8 ;reload the counters
	dec pos ;have we reached the 10th led?
	brne ld_byte ;load till the 10th led
	rcall latch ;show the annimation
	sbiw xl,30 ;reset the x pointer to point to the innitial mem loc
	ret ;return to caller
bit_1: ;subroutine to send a bit 1
	sbi ledcntr,ledpin
	ldi r16,4;waste 14 clocks
	loop_1:
	dec r16
	brne loop_1
	nop
	nop

	cbi ledcntr,ledpin
	ldi r16,2 ;waste 12 clocks
	loop_2:
	dec r16
	brne loop_2
	nop
	nop
	ret ;return to caller
bit_0:
	sbi ledcntr,ledpin
	ldi r16,2 ;waste 7 clocks
	loop_3:
	dec r16
	brne loop_3
	nop

	cbi ledcntr,ledpin
	ldi r16,2 ;waste 12 clocks
	loop_4:
	dec r16
	brne loop_4
	nop
	nop

	ret; return to caller
latch:
	cbi ledcntr,ledpin
	push r22; pushing to stack
	ldi r22,119
	outer:
	ldi r23,2
	inner:
	dec r23
	brne inner
	dec r22
	brne outer
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	nop
	pop r22
	ret ;return to caller
delay:
	ldi r23,20
	outer_1:
	ldi r24,166
	inner_1:
	dec r24
	brne inner_1
	dec r23
	brne outer_1
	ret ;return to caller
main:
	ldi r16, low(ramend)
	out spl,r16 ;init stack

	sbi DDRD,ledpin
	ldi xh,high(led_data)
	ldi xl,low(led_data)
	ldi yh,high(led_data)
	ldi yl,low(led_data) ;init pointers x and y register

	rcall clr_led ;clear the 10 leds

	ldi leddata_reg,255
	ldi counter,10
fw_red:std y+1,leddata_reg ;write to the red led of each chip
	adiw yl,3 ;progress the counter by 3 illitertions always
	rcall led_write ;illusion of moving red light left to right
	rcall delay ;
	dec counter
	brne fw_red ;continue loading red
	sbiw yl,30 ;points to 1st mem loc
loop_atn:rjmp  loop_atn ;loop paying the annimation



