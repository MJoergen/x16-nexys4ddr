   .setcpu     "6502"

.segment "CODE"

main:
   LDA #$00    ; Select address port 0
   STA $9F25

   LDA #$80    ; Set address to 0x02080 and increment to 1.
   STA $9F20
   LDA #$20
   STA $9F21
   LDA #$10
   STA $9F22

   LDA #$00    ; Write to 0x02080
   STA $9F23
   LDA #$44    ; Write to 0x02081
   STA $9F23

   LDA #$00    ; Write to 0x02082
   STA $9F23
   LDA #$66    ; Write to 0x02083
   STA $9F23

   LDA #$00    ; Write to 0x02084
   STA $9F23
   LDA #$66    ; Write to 0x02085
   STA $9F23

   LDA #$00    ; Write to 0x02086
   STA $9F23
   LDA #$66    ; Write to 0x02087
   STA $9F23

   LDA #$00    ; Write to 0x02088
   STA $9F23
   LDA #$44    ; Write to 0x02089
   STA $9F23

   NOP
   NOP

   LDA #$80    ; Set address to 0x02180 and increment to 1.
   STA $9F20
   LDA #$21
   STA $9F21
   LDA #$10
   STA $9F22

   LDA #$00    ; Write to 0x02180
   STA $9F23
   LDA #$66    ; Write to 0x02181
   STA $9F23

   LDA #$00    ; Write to 0x02182
   STA $9F23
   LDA #$44    ; Write to 0x02183
   STA $9F23

   LDA #$00    ; Write to 0x02184
   STA $9F23
   LDA #$66    ; Write to 0x02185
   STA $9F23

   LDA #$00    ; Write to 0x02186
   STA $9F23
   LDA #$44    ; Write to 0x02187
   STA $9F23

   LDA #$00    ; Write to 0x02188
   STA $9F23
   LDA #$66    ; Write to 0x02189
   STA $9F23

   NOP
   NOP

loop:
   JMP loop


.segment "VECTORS"
   .addr main
   .addr main
   .addr main
