   .setcpu     "65C02"

.segment "CODE"

main:
   SEI         ; Disable CPU interrupts

; Test reading from ROM
   LDA $C000
   CMP #$78
error1:
   BNE error1

; Test read/write to low RAM
   LDA #$12
   STA $FF
   INC $FF
   LDA $FF
   CMP #$13
error2:
   BNE error2

; Test read/write to high RAM
   LDA #$23
   STA $A000
   INC $A000
   LDA $A000
   CMP #$24
error3:
   BNE error3

; Test read/write to VIA1
   LDA #$00
   STA $9F60
   STA $9F61
   LDA #$FF
   STA $9F62
   STA $9F63

   LDA #$34
   STA $9F61
   INC $9F61
   LDA $9F61
   CMP #$35
error4:
   BNE error4

; Test read/write to VIA2
   LDA #$00
   STA $9F70
   STA $9F71
   LDA #$FF
   STA $9F72
   STA $9F73

   LDA #$45
   STA $9F71
   INC $9F71
   LDA $9F71
   CMP #$46
error5:
   BNE error5

; Test read/write to VERA config
   LDA #$67
   STA $9F20
   INC $9F20
   LDA $9F20
   CMP #$68
error6:
   BNE error6

; Test read/write to VERA video RAM
   LDA #$00
   STA $9F25   ; Address port 0
   STA $9F20
   STA $9F21
   STA $9F22   ; Address 0x00000, no increment

   LDA #$78
   STA $9F23
   INC $9F23
   LDA $9F23
   CMP #$79
error7:
   BNE error7

end:
   JMP end






   LDA #$01
   STA $9F26   ; Enable VERA VSYNC IRQ
   LDA #$FF
   STA $9F27   ; Clear pending VERA VSYNC IRQ

   LDA $9F27   ; Should be zero.
err1:
   BNE err1

wat:
   LDA $9F27   ; Wait until next interrupt
   BEQ wat
   STA $9F27   ; Clear pending

   LDA $9F27   ; Should be zero.
err2:
   BNE err2

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
err:
   BNE err     ; There should be no pending now.

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
