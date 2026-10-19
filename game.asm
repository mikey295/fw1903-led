 ;uses r15 as te register sharing data in lcd subroutines
 ;r16 is used as an arithmetic assist register in  the subroutines
 ;enable pin chaged to pd5
 ;counter button pd3
 ;counter reset button pd
 ;uses r13 to transfer coursor position and r16 to transfer inteded position to the subroutine from 1-32
 ;cursor_Pos
 ;scroll_screen takes two input 1 for scrolling left and any other number to scroll right
 ;clear_screen has 3 functions clear screen load r16,1 :return home load 2:do bith load any other number
.include "tn2313def.inc"
.equ cprt = PORTD
.equ lcd = PORTB
.equ regsel = 4
.equ enb = 5
.def zero_reg = r1
.def qotient_high = r2
.def rem_high = r3
.def divis_low = r4
.def divis_high = r9
.def div_low = r5
.def rem_low = r7
.def div_high = r8
.def qotient_low =r10

.dseg
test_flag: .byte 1 
player_pos: .byte 1
enemy_pos: .byte 1
counter: .byte 4
counter_char: .byte 5 ;used to store the converted char
.cseg
.org 0x0000
   rjmp main
.org 0x0001
    rjmp EX_0ISR
.org 0x0002
    rjmp EX_1ISR


snd_cmd:;subroutine to send commands ;uses r15 as the data sharing register
	cbi cprt,regsel;command mode
	mov r14,r15 ;mov teh data in r15 to r14
	ldi r16,0b11110000
	and r15,r16 ;mask the lower nibble
	out lcd,r15
	rcall latch ;latch the data
	swap r14 ;send lower nibble
	and r14,r16 ;mask the lower nibble
	out lcd,r14
	rcall latch
	ldi r17,30
del:	rcall delay_1us
	dec r17
	brne del
	ret ;return to caller
snd_data: ;subroutine to send data
	sbi cprt,regsel ;select to send data
	mov r14,r15 ;copy theT from r15 t0 14
	ldi r16,0b11110000
	and r15,r16 ;mask the lowe nibble
	out lcd,r15
	rcall latch
	swap r14
	and r14,r16 ;mask the lower nibble
	out lcd,r14
	rcall latch
	ldi r17,30
dela:	rcall delay_1us
	dec r17
	brne dela
	ret ;return to caller

delay_1sec:;uses timers for delay heavily uses r16, creates roughly 1 second delay
	ldi r16,0
	out tcnt1h,r16
	out tcnt1l,r16 ;load the counter with zero
	ldi r16,high(19532) ;high byte
	out ocr1ah,r16
	ldi r16,low(19532);low byte
	out ocr1al,r16 ;this aproximates to like 1 second
	ldi r16,0     ;
	out tccr1a,r16 ;
	ldi r16,(1<<WGM12)|(1<<CS12)|(1<<CS10) ;select prescaler of 1024, and ctc mode
	out tccr1b,r16
again:  in r16,tifr
	sbrs  r16,ocf1a ;check if an compare is occures
	rjmp again ;check till it occurs
	ldi r16,1<<ocf1a
	out tifr,r16 ;clear flag
	ldi r16,0
	out tccr1a,r16
	out tccr1b,r16 ;stop timer
	ret ;return from caller
latch:
	sbi cprt,enb
	ldi r17,6
dly_l:	nop
	nop
	nop
	dec r17
	brne dly_l
	cbi cprt,enb
	ret ;return to caller

delay_1us:
	ldi r16,high(19)
	out ocr1ah,r16
	ldi r16,low(19)
	out ocr1al,r16
	clr r16
        out tcnt1h,r16
        out tcnt1l,r16 ;start to count from 0
	ldi r16,0
	out tccr1a,r16
	ldi r16,(1<<wgm12)|(1<<cs10);ctc mode no prescaller
	out tccr1b,r16

wait:
	in r16,tifr
	sbrs r16,ocf1a
	rjmp wait
	ldi r16,(1<<ocf1a)
	out tifr,r16
	ret ;return to caller
delay_1ms:
	ldi r16,high(19999)
        out ocr1ah,r16
        ldi r16,low(19999)
        out ocr1al,r16
	 clr r16
        out tcnt1h,r16
        out tcnt1l,r16 ;start to count from 0
        ldi r16,0
        out tccr1a,r16
        ldi r16,(1<<wgm12)|(1<<cs10);ctc mode no prescaller
        out tccr1b,r16
wait_a:
        in r16,tifr
        sbrs r16,ocf1a
        rjmp wait_a
        ldi r16,(1<<ocf1a)
        out tifr,r16
        ret ;return to caller

cursor_pos: ;uses r16 to calculate cursor pos ;returns the cursor point on r13
	ldi r17,0x80 ;1st row ist coloumn
	;mov r13,r16 ;copy the value to r13
	subi r16,1 ;so it does not branch if its 16 to second row
	cpi r16,16  ;check if its  ist ow or second row
	brsh second_row
	add r17,r16
	mov r13,r17 ;retunr the coursor point on r13
	rjmp end_coursor
second_row:
	ldi r17,0xc0
	subi r16,16
	add r17,r16 ;create the adress for second row and coloumn
	mov r13,r17 ;return the cursor point on r13
end_coursor:
	ret ;return


scroll_screen: ;subroutine to scroll the screen input 1 to scroll left and 2 to scroll right
	cpi r16,1
	brsh scroll_left
	rjmp scroll_right
scroll_left:
	ldi r16,0x18
	mov r15,r16
	rcall snd_cmd
	rjmp end_scroll
scroll_right:
	ldi r16,0x1c
	mov r15,r16
	rcall snd_cmd
end_scroll:
	ret ;return to caller


EX_1ISR:
	reti ;return from interupt
EX_0ISR:
	lds r19,test_flag
	ori r19,1
	sts test_flag,r19 ;load 1 to the button_press flag

	clc ;clear carry flag
	ld r19,x
	inc r19
	st x,r19 ;store low byte
	brcs carry
	rjmp end_cnt_arth
carry: ;stores the carry bit

	clr zero_reg ;used in pointer arithmetic
	clr r16 ;used in pointer arithmetic
	inc r16
	add xl,r16
	adc xh,zero_reg ;increment the counter
	ld r19,x ;we are on the second element
	inc r19 ;increment the value
	st x,r19 ;store the high byte
	sub xl,r16
	sbc xh,zero_reg ;point to the first element 
end_cnt_arth:
	reti ;return from interupt

welcome_intro:
	ldi zl,low(welcome_txt<<1)
	ldi zh,high(welcome_txt<<1) ;point to the welcome text

ld_intro:
	lpm r18,z+
	tst r18 ;check for the null character
	breq end_intro
	mov r15,r18
	rcall snd_data
	rjmp ld_intro
end_intro:
	ret ;return to caller


interupt:
	ldi r16,1
	mov r15,r16
	rcall snd_cmd ;clear the display

	ldi r20,3
inst_comp_delay:
	rcall delay_1ms
	dec r20
	brne inst_comp_delay

	ldi r16,1
	rcall cursor_pos
	mov r15,r13
	rcall snd_cmd ;start at the ist  row

	ldi zl,low(counter_tag<<1)
	ldi zh,high(counter_tag<<1);point to the reset text
ld_reset_txt:
	lpm r18,z+
	tst r18
	breq end_reset_ld
	mov r15,r18
	rcall snd_data ;send data to lcd
	rjmp ld_reset_txt
end_reset_ld:
	ldi r16,10
	mov divis_low,r16
	mov divis_high,zero_reg
	ldi r16,0
	ld r19,x+
	mov div_low,r19
	ld r19,x
	mov div_high,r19
	subi xl,1
	sbc xh,zero_reg
	rcall division


	ldi r22,5 ;the max number of char that will be generated
char_gen:
	mov div_low,qotient_low
	mov div_high,qotient_high
	rcall division
	st y+,rem_low
	dec r22
	brne char_gen ;repeat if not yet reached 5

	ldi r22,5
	ldi r16,'0'
	mov r11,r16
char_wrt:ld r15,-y ;predecrement
	add r15,r11
	rcall snd_data
	dec r22
	brne char_wrt
clear_btnflg:
	lds r19,test_flag ;.........clears the button_flag or the next interupt
	cbr r19,1 ;clear the button_bit
	sts test_flag,r19
	ret ;return to caller

clear_counter:;clears all the counters mem locs
	clr zero_reg
	ldi r16,4
clear:	st x+,zero_reg ;clear the mem locs
	dec r16
	brne clear
	subi xl,4
	sbc xh,zero_reg ;point to the first element
	ret ;retun to caller

division: ;division subroutine  ,,takes urguments as divident in divident register,divisor ,and returns data in qotient and reminder registers
	
 	clr rem_high
	clr rem_low
        clr qotient_high
	clr qotient_low
        ldi r16,16 ;16 illiterations
	ldi r19,1
        clc
rpt_div:
	lsl div_low ;shift the dividend one bit at a time till end
	rol div_high ;shifts the bits as if in one 16 bit register

	rol rem_low ;shift the reminder to take the shifted bit out of the dividend
	rol rem_high

	lsl qotient_low ;shift qotient to make it ready to receive tre new bit
	rol qotient_high

	cp rem_low,divis_low ;check if the reminder is equal or bigger than divisor
	cpc rem_high,divis_high

	brlo no_sub

	sub rem_low,divis_low ;if it is same or higher rem = rem-divisor
	sbc rem_high,divis_high
	or qotient_low,r19 ;set the bit at that position of the low byte 
	no_sub:
	dec r16 ;decrement the counter
	brne rpt_div


	ret ;return to caller
main:
	ldi r16,0b11110000 ;set pins 8,7,6,5 as outputs
	out DDRB,r16
	ldi r16,(1<<pd4)|(1<<pd5) ;set ddrd pins5,4 as outputs
	out DDRD,r16
	ldi r16,(1<<ISC00)|(1<<ISC01) ;trigger on rising edge
	out mcucr,r16
	ldi r16,(1<<int0)
	out GIMSK,r16
	sei  ;enable interupt
	sts player_pos,zero_reg ;clear the coursor pos on startup
	ldi xl,low(counter)
	ldi xh,high(counter) ;init xpointer to point to the counter tag
	ldi yl,low(counter_char)
	ldi yh,high(counter_char);points to char
	rcall clear_counter ;clera the counter to start at zero
	rcall delay_1sec
	cbi cprt,regsel
	ldi r16,0b00100000 ;set the display to 4bit mode
	mov r15,r16
	rcall snd_cmd
	ldi r16,0b001010;function set 4bit,2lines,5x8 dots
	mov r15,r16
	rcall snd_cmd
	ldi r16,0b00001110;display on off display on no blinking cursor on
	mov r15,r16
	rcall snd_cmd
	ldi r16,0b00000110;entry mode set increment on writing ,no display shifft
	mov r15,r16
	rcall snd_cmd
	clr zero_reg ;zero the zero_reg

	sts test_flag,zero_reg ;clear the flags at startup
	ldi r16,1
	rcall cursor_pos
	mov r15,r13
	rcall snd_cmd
	rcall welcome_intro ;starts the intro

wait_int:lds r19,test_flag
	sbrc r19,0
	rcall interupt
	rjmp wait_int
here: rjmp here ;stay here forever

welcome_txt:
	.db "welcome",0

counter_tag:
	.db "counter is:",0
reset_txt:
	.db "interupt occured"
