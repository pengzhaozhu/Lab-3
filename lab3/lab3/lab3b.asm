/* Lab 3 Part B
   Name: Pengzhao Zhu
   Section#: 112D
   TA Name: Chris Crary
   Description: This Program ulitizes the Timer system to allow the CNT register to count to 255. The CNT will increment one time
                every 1024 clock cycles
*/

.include "ATxmega128A1Udef.inc"        ;include the file
.list                                  ;list it 

.org 0x0000                            ;start our program here
rjmp MAIN                              ;jump to main

MAIN: 

ldi r17, 0xFF               ;load low byte
sts TCC0_PER, r17           ;0X826. should 
ldi r17, 0x00              ;load high byte
sts TCC0_PER+1, r17         ;0x827
ldi r17, 0b00000111       ;prescaler CLK/1024
sts TCC0_CTRLA, r17       ;CTRLA controls the count (CNT)

ldi r17, 0xFF             ;set as output
sts PORTC_DIRSET, r17     ;set as output

REPEAT:
lds r17, TCC0_CNT         ;load value from TCC0_CNT to r17
sts PORTC_OUT, r17        ;output value at r17 to PORTC
rjmp REPEAT               ;REPEAT

