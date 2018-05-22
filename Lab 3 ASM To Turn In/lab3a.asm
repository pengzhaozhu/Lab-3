/* Lab 3 Part A
   Name: Pengzhao Zhu
   Section#: 112D
   TA Name: Chris Crary
   Description: This Program configures the XMEGA clock to run at 4MHZ or 32MHZ (depending on situation)
*/


.include "ATxmega128A1Udef.inc"        ;include the file
.list                                  ;list it 

.org 0x0000                            ;start our program here
rjmp MAIN                              ;jump to main

.equ stack_init=0x3FFF   ;initialize stack pointer

MAIN:
ldi YL, low(stack_init)    ;Load 0xFF to YL
out CPU_SPL, YL			   ;transfer to CPU_SPL
ldi YL, high(stack_init)   ;Load 0x3F to YH
out CPU_SPH, YL			   ;transfer to CPU_SPH

ldi r17, 0b00010100  ;divide by 8 to change from 32 MHZ to 4 MHZ in the subroutine. 0x14

ldi r16, 0b10000000   ;load value into r16. configure pin 7 as output
sts PORTC_DIRSET, r16 ;configure pin 7 as output
rcall CLK
ldi r16, 0b00001001   ;output CLKPER 4 on PORT C pin 7. pin 7 is the default. 0000=not used, 10=output CLKPER4, 01=PORTC 
sts PORTCFG_CLKEVOUT, r16    ;output to PORTCFG_CLKEVOUT

DONE:
	rjmp DONE         ;infinite loop to end the program

CLK:
push r16              ;push r16
ldi r16, 0b00000010   ;bit 1 is the 32Mhz oscillator
sts OSC_CTRL, r16     ;store r16 into the OSC_CTRL

NSTABLE:
lds r16, OSC_STATUS     ;load oscillator status into r16
bst r16, 1              ;check if 32Mhz oscillator is stable
brts STABLE             ;branch if stable
brtc NSTABLE            ;loop again if non-stable

STABLE:
ldi r16, 0xD8   ;writing IOREG to r16
sts CPU_CCP, r16 ;write IOREG to CPU_CCP to enable change 
ldi r16, 0b00000001  ;write this to r16. corresponds to 32Mhz oscillator
sts CLK_CTRL, r16    ;select the 32Mhz oscillator

ldi r16, 0xD8    ;writing IOREG for prescaler
sts CPU_CCP, r16 ;for prescaler
sts CLK_PSCTRL, r17  ;r17 will be initialized outside the subroutine for prescale. 32/8=4MHZ

pop r16          ;pop r16
ret              ;return to main routine