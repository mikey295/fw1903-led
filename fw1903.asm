.include "tn2313def.inc"
.def pos = r25
.def counter = r18
.def led = r20
.def bit_counter = r21
.def byte_counter =r22
.def brightness = r19
.def zero_reg =r4
.def colour = r6
.equ ledcntr = PORTD
.equ ledpin = 4
.dseg
led_data: .byte 30 ;reserve 30 bytes
.cseg
.org 0x0000
rjmp main

clr_led:; subroutine to clear the strip
	push pos ;store the previous pos
	push counter
	ldi pos,0
	mov counter,pos
	clr_loc:
	st z+,pos
	inc counter
	cpi counter,30
	brne clr_loc
	sbiw zl,30 ;point to the 1st memory loc allocated
	pop counter
	pop pos ;recover thee previous pos value
	ret ;return to caller
led_write:;does not contain latch so it should be called from the main code space
	push pos
	ldi pos,10; ??
	ld_led:
	ldi byte_counter,3
	ld_byte:
	clc ;clear the carry flag
	ldi bit_counter,8
	ld led,x+ ;load from x pointer
	check_bit:
	rol led ;rotate the data
	brcc bit_is0
	rcall bit_1 ;else its a 1 snd bit_1 seuence
	rjmp cont ;jump to the cont lable
	bit_is0:
	 rcall bit_0 ;send the sequence for bit 0
	cont:
	dec bit_counter ;dec no of bits remaining to be rolled
	brne check_bit ;if not zero then check bit again

	dec byte_counter
	brne ld_byte

	dec pos
	brne ld_led
	sbiw xl,30 ;reset it to point to mem adress 1st alocated 0x0060
	pop pos
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
	ldi r16,4
	start:
	ldi r23,255
	outer_1:
	ldi r24,255
	inner_1:
	dec r24
	brne inner_1
	dec r23
	brne outer_1
	dec r16
	brne start
	ret ;return to caller
main:
	ldi r16, low(ramend)
	out spl,r16 ;init stack

	sbi DDRD,ledpin
	ldi zh,high(led_data)
	ldi zl,low(led_data) ;pointer to clear led_data
	ldi xh,high(led_data)
	ldi xl,low(led_data)
	ldi yh,high(led_data)
	ldi yl,low(led_data) ;init pointers z, x and y register
	ldi r16,1
	mov colour,r16
	ldi r16,0
	mov zero_reg,r16 ;clear register 4 for use in pointer calcs
	ldi brightness,100
loop:
	ldi pos,1
check_led:
	clc ;clear the carry flag
	cpi pos,11 ;check to determine what bank we will choose
	brlo bank_1 ;branch to this if pos is less than 10

	cpi pos,21
	brlo bank_2 ;if its less than 20 then it belongs in bank 2
	cpi pos,31
	brlo is_bank_3
is_bank_3:
	rjmp bank_3 ;this is because branch can oly jump+-64 bytes

bank_1:
	push counter
	ldi counter,9 ;??
	mov r3,pos ;this shows us the led that we need to light not the place to point
	mov r5,r3 ;getting ready to multiply  by 3
	lsl r3 ;multiply by 2
	add r3,r5 ;complete the multiplication by 3 this gives you the last color of the number geneated
	sub r3,colour ;this points to the colour itelf as we always start at adress loc1
	add yl,r3
	adc yh,zero_reg ;points to the numbers blue light
	rcall clr_led ;all the mem locs are zerod
	st y,brightness ;writes only one led
	rcall led_write;writes the first 30 bytes
	sub yl,r3
	sbc yh,zero_reg ;return the pointer to initial pointing pos
	dec counter
	ldi r16,2
	mov r2,r16 ;move it to r2
        ld_nullbytes:
	rcall clr_led ;clear the leds again to send the next 60 btes of empt data
	rcall led_write ;wite the rest of thr null bytes ;it doesnt need a pointer because clr_led already does all the clearing 
	dec r2
	brne ld_nullbytes
	rcall latch ;display the patern
	rcall delay
	pop counter
	rjmp cont_1; jump all the other bank_lable codes
bank_2:
	ldi r16,10 ;number which will be subtracted
	mov r2,r16 ;move it to r2 because r16 will be overwritten
	mov r3,pos ;so we dont have to modify the thing thus make it crash
	sub r3,r2 ;the answer will tell us the index of the led that should be on
	mov r5,r3 ;move the contens to get ready for multiplication
	lsl r3 ;multiply by 2
	add r3,r5 ;complete the multiplication by 3
	sub r3,colour; when added will point to the colour itself
	add yl,r3;
	adc yh,zero_reg ;point to the blue led of the index led to be lit
	rcall clr_led ;clear the leds
	rcall led_write ;write the first blank
	st y,brightness
	rcall led_write ;this will write it to the 2nd tens
	rcall clr_led
	rcall led_write ;write zeros to the 3rd tens of the leds
	rcall latch ;this displays the light pattern
	rcall delay
	sub yl,r3
	sbc yh,zero_reg ;point to the inital position
	rjmp cont_1 ;jump te bank_3 lable

bank_3:
	ldi r16,20 ;numbe well suntract from pos to get led index
	mov r2,r16 ;copy it so it wount be overwritten
	mov r3,pos ;copy to another register so we dont overide it
	sub r3,r2 ;creates the index
	mov r5,r3 ;copy the number to the register for multiplication purposes
	lsl r3 ;r3*2
	sub r3,colour ;helps us point to the colour itself in memory
	add r3,r5 ;complete multiplication by 3
	add yl,r3
	adc yh,zero_Reg ;point to the blue light of the indexed led
	ldi counter, 2
	ld_nullbyte_3:
	rcall clr_led
	rcall led_write
	dec counter
	brne ld_nullbyte_3 ;this loads the 1,2 tens with zero
	st y,brightness
	rcall led_write
	rcall latch ;show the animation
	rcall delay
	sub yl,r3
	sbc yh,zero_reg ;point to the initial mem loc it was in
	rjmp cont_1
cont_1:
	inc pos ;have we reached 30 leds?
	cpi pos,31
	brne is_led_check ;??? branch will fail due to range
	rjmp cont_2 ;if it fails it jumps to cont_2
is_led_check:
	rjmp check_led ;this is due to branch +- 64 bytes jump constrains
cont_2:
	rjmp loop; for ever 















