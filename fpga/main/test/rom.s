   .setcpu     "6502"

.segment "CODE"

main:
   SEI         ; Disable CPU interrupts
   LDA #$01
   STA $9F26   ; Enable VERA VSYNC IRQ
   LDA #$FF
   STA $9F27   ; Clear pending VERA VSYNC IRQ

   LDA $9F27   ; Should be zero.
error1:
   BNE error1

wat:
   LDA $9F27   ; Wait until next interrupt
   BEQ wat
   STA $9F27   ; Clear pending

   LDA $9F27   ; Should be zero.
error2:
   BNE error2

   LDA #$00    ; Select address port 0
   STA $9F25

   LDA #$50    ; Set address to 0x02050 and increment to 1.
   STA $9F20
   LDA #$20
   STA $9F21
   LDA #$10
   STA $9F22

   LDA #$00    ; Write to 0x02050
   STA $9F23
   LDA #$44    ; Write to 0x02051
   STA $9F23

   LDA #$00    ; Write to 0x02052
   STA $9F23
   LDA #$66    ; Write to 0x02053
   STA $9F23

   LDA #$00    ; Write to 0x02054
   STA $9F23
   LDA #$66    ; Write to 0x02055
   STA $9F23

   LDA #$00    ; Write to 0x02056
   STA $9F23
   LDA #$66    ; Write to 0x02057
   STA $9F23

   LDA #$00    ; Write to 0x02058
   STA $9F23
   LDA #$44    ; Write to 0x02059
   STA $9F23

   NOP
   NOP

   LDA $9F27   ; Should be zero
error:
   BNE error   ; There should be no pending now.

   LDA #$50    ; Set address to 0x02150 and increment to 1.
   STA $9F20
   LDA #$21
   STA $9F21
   LDA #$10
   STA $9F22

   LDA #$00    ; Write to 0x02150
   STA $9F23
   LDA #$66    ; Write to 0x02151
   STA $9F23

   LDA #$00    ; Write to 0x02152
   STA $9F23
   LDA #$44    ; Write to 0x02153
   STA $9F23

   LDA #$00    ; Write to 0x02154
   STA $9F23
   LDA #$66    ; Write to 0x02155
   STA $9F23

   LDA #$00    ; Write to 0x02156
   STA $9F23
   LDA #$44    ; Write to 0x02157
   STA $9F23

   LDA #$00    ; Write to 0x02158
   STA $9F23
   LDA #$66    ; Write to 0x02159
   STA $9F23

   NOP
   NOP

loop:
   JMP loop


.segment "VECTORS"
   .addr main
   .addr main
   .addr main
