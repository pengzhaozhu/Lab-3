/* Lab 3 Part C
   Name: Pengzhao Zhu
   Section#: 112D
   TA Name: Chris Crary
   Description: This Program configures the 3-Port EBI system on the XMEGA. It will then write 0xA5 to all memory addresses
                of the external 32K SRAM starting at address 0x200000. 
*/

.include "ATxmega128A1Udef.inc"        ;include the file
.list                                  ;list it 

.org 0x0000                            ;start our program here
rjmp MAIN                              ;jump to main

.set IN_PORT = 0x200000         ;beginning at end of the 32K SRAM. base address
;.set IPORT_END = 0x207FFF 

MAIN: 
rcall EBI                  ;call EBI subroutine

STARTOVER:

ldi ZL, byte3(In_PORT)        ;load 0x20 into ZL
out CPU_RAMPZ, ZL             ;ZL value into RAMPZ
ldi ZL, low(IN_PORT)          ;load 0x00 into ZL
ldi ZH, byte2(IN_PORT)        ;load 0x00 into ZH


REPEAT:

ldi r16, 0xA5                 ;load 0xA5 into r16
st Z, r16                     ;r16 value into value pointed by Z pointer
cpi ZH, 0x7F                  ;first check for if 32K limit is reached
breq CHECK                    ;if equal, branch to do second check

LOAD:
ld r17, Z+                    ;load value to Z pointer address to r17. post increment
rjmp REPEAT                   ;jump to REPEAT

CHECK:
cpi ZL, 0xFF                   ;second check for if 32K limit is reached
breq STARTOVER                 ; if limit is reached. start over from 0x200000
brne LOAD                      ;if not, branch to LOAD

 
EBI:   ;takes in IN_PORT, IN_PORT = 24 bit address for 32 K SRAM
push r16                       ;push r16
push ZL                        ;push ZL
push ZH                        ;push ZH
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

ldi r16, 0xFF                    ;0xFF to r16
sts PORTJ_DIRSET, r16            ;set PORTJ to be output    
ldi r16, 0xFF                    ;0xFF to r16. unneccesary, but I am still including it
sts PORTK_DIRSET, r16            ;set PORTK to be output

ldi ZL, low(EBI_CS0_BASEADDR)        ;ZL pointer point to low byte of EBI_CS0_BASEADDR
ldi ZH, high(EBI_CS0_BASEADDR)       ;ZH pointer point to high byte of EBI_CS1_BASEADDR
ldi r16, byte2(IN_PORT)              ;transfer middle byte of base address to lower byte of base address
st Z+, r16                           ;r16 value to address pointed to Z pointer. post increment Y pointer
ldi r16, byte3(IN_PORT)              ;transfer high byte of base address to upper byte of base address
st Z, r16                            ;r16 value to address pointed to Z pointer
pop ZH                               ;pop ZH
pop ZL                               ;pop ZL
pop r16                              ;pop r16
ret                                  ;return from subroutine

