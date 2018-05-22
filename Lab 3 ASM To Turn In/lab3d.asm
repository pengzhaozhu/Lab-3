/* Lab 3 Part D
   Name: Pengzhao Zhu
   Section#: 112D
   TA Name: Chris Crary
   Description: This Program stores data read from the DIP switches to sequential memory locations every one second.
				It will then read it back, and store the value to the LED bank.
*/


.include "ATxmega128A1Udef.inc"        ;include the file
.list                                  ;list it 

.org 0x0000                            ;start our program here
rjmp MAIN                              ;jump to main

.equ stack_init=0x3FFF   ;initialize stack pointer
.equ IN_PORT=0x300000

MAIN:
ldi YL, low(stack_init)    ;Load 0xFF to YL
out CPU_SPL, YL			   ;transfer to CPU_SPL
ldi YL, high(stack_init)   ;Load 0x3F to YH
out CPU_SPH, YL			   ;transfer to CPU_SPH

ldi r17, 0x00  ;set up 32MHZ clock in 
rcall CLK      ;subroutine to set up 32Mhz clock
rcall EBI      ;subroutine to set up EBI of 32K and base address of 0x300000

ldi r16, 0xFF
sts PORTA_DIRCLR, r16    ;set Port A to be input 
sts PORTC_DIRSET, r16    ;set Port C to be output 
sts PORTC_OUTSET, r16    ;turn off the LED for now

STARTOVER:

ldi ZL, byte3(In_PORT)    ;load highest byte of 0x300000
out CPU_RAMPZ, ZL         ;RAMPZ point to 30
ldi ZL, byte1(IN_PORT)    ;ZL point to 00
ldi ZH, byte2(IN_PORT)    ;ZH point to 00

REPEAT:
lds r16, PORTA_IN         ;take in value from input switches
cpi ZH, 0x7F              ;check if middle byte is 0x7F to see if we have reach the limit of the external SRAM
breq CHECK                ;if equal, branch to check again

LOAD:
st Z, r16          ; write to external memory
ld r18, Z+         ;read it back from external memory
rcall TIMER        ;call timer
sts PORTC_OUT, r18 ;output to LED
rjmp REPEAT        ;repeat

CHECK:             
cpi ZL, 0xFF       ;check if the lower byte is 0xFF to see if we have reach the limit of the 32K external SRAM
breq STARTOVER     ;if we have. start from 0x300000 again
brne LOAD          ; otherwise, branch to load


; the rest are just subroutines


CLK:   ;take in a r17 value for prescaler. 32MHZ = 0x00 for prescale
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


EBI:   ;takes in IN_PORT, IN_PORT = 24 bit address for 32 K SRAM
push r16
push ZL
push ZH
ldi r16, 0x01   ; 4 bit data bus, data multiplexed with address byte 0 and 1, 3 port
sts EBI_CTRL, r16   ;configure mode to be 3 port

ldi r16, 0b00011101   ;set for 32K SRAM chip select
sts EBI_CS0_CTRLA, r16   ;set for 32K SRAM

ldi r16, 0b00010111   ;hex 0x17, enable CS0, RE, WE, ALE1
sts PORTH_DIRSET, r16 ; set CS0, RE, WE, ALE1 as output
ldi r16, 0b00010011     ;bit 0=we, bit 1=re, bit 4= CS0
sts PORTH_OUTSET, r16 ;set false value to CS0, WE, RE
ldi r16, 0b00000100   ;bit 2= ALE1
sts PORTH_OUTCLR, r16 ;set false value to ALE

ldi r16, 0xFF                  
sts PORTJ_DIRSET, r16            ;set port J to be output
sts PORTK_DIRSET, r16            ;set port K to be output

ldi ZL, low(EBI_CS0_BASEADDR)        ;ZL pointer point to low byte of EBI_CS0_BASEADDR
ldi ZH, high(EBI_CS0_BASEADDR)       ;ZH pointer point to high byte of EBI_CS1_BASEADDR
ldi r16, byte2(IN_PORT)              ;transfer middle byte of base address to lower byte of base address
st Z+, r16                           ;r16 value to Z pointer address. post increment Z pointer
ldi r16, byte3(IN_PORT)              ;transfer high byte of base address to upper byte of base address
st Z, r16                            ;r16 value to Z pointer address.
pop ZH                               ;pop ZH
pop ZL                               ;pop ZL
pop r16                              ;pop r16
ret                                  ;return from subroutine

TIMER:   ;delay for 1 second
push r17				    ;push r17
ldi r17, 0x12               ;load low byte of 0x7A12
sts TCC0_PER, r17           ;transfer to TCC0_PER
ldi r17, 0x7A              ;load high byte of 0x7A12
sts TCC0_PER+1, r17         ;transfer to TCC0_PER+1
ldi r17, 0b00000111       ;prescaler CLK/1024
sts TCC0_CTRLA, r17       ;CTRLA controls the count (CNT)

NOTSET:
nop                        ;delay
lds r17, TCC0_INTFLAGS     ;check if the flag is set
bst r17, 0                 ;check the zero bite
brts RETURN                ;if set, branch to return
brtc NOTSET                ;if not, branch to NOTSET and continue

RETURN:
ldi r17, 0x01            ;to clear the flag
sts TCC0_INTFLAGS, r17   ;clears the flag
pop r17                  ;pop r17
ret                      ;return from subroutine



