   .setcpu     "65C02"

.segment "CODE"

main:
   SEI         ; Disable CPU interrupts
   LDX #$FF
   TXS         ; Reset stack pointer

   LDA #$00    ; Select address port 0
   STA $9F25

   LDY #$51
   LDX #$20
   LDA #$44
   JSR write_vram ; $2051 := $44


; Test reading from ROM
   LDA $C000
   CMP #$78
error1:
   BNE error1

   LDY #$61
   LDX #$20
   LDA #$44
   JSR write_vram ; $2061 := $44


; Test read/write to low RAM
   LDA #$12
   STA $FF
   INC $FF
   LDA $FF
   CMP #$13
error2:
   BNE error2

   LDY #$71
   LDX #$20
   LDA #$44
   JSR write_vram ; $2071 := $44


; Test read/write to high RAM
   LDA #$23
   STA $A000
   INC $A000
   LDA $A000
   CMP #$24
error3:
   BNE error3

   LDY #$51
   LDX #$22
   LDA #$44
   JSR write_vram ; $2251 := $44


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

   LDY #$61
   LDX #$22
   LDA #$44
   JSR write_vram ; $2261 := $44


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

   LDY #$71
   LDX #$22
   LDA #$44
   JSR write_vram ; $2271 := $44


; Test read/write to VERA config
   LDA #$67
   STA $9F20
   INC $9F20
   LDA $9F20
   CMP #$68
error6:
   BNE error6

   LDY #$51
   LDX #$24
   LDA #$44
   JSR write_vram ; $2451 := $44


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

   LDY #$61
   LDX #$24
   LDA #$44
   JSR write_vram ; $2461 := $44


; Test clear of VERA VSYNC
   LDA #$01
   STA $9F26   ; Enable VERA VSYNC IRQ
   LDA #$FF
   STA $9F27   ; Clear pending VERA VSYNC IRQ

   LDA $9F27   ; Should be zero.
error8:
   BNE error8

   LDY #$71
   LDX #$24
   LDA #$44
   JSR write_vram ; $2471 := $44


; Test generation of VERA VSYNC
wat:
   LDA $9F27   ; Wait until next interrupt
   BEQ wat

   LDY #$51
   LDX #$26
   LDA #$44
   JSR write_vram ; $2651 := $44


; Test clear again of VERA VSYNC
   LDA #$FF
   STA $9F27   ; Clear pending VERA VSYNC IRQ

   LDA $9F27   ; Should be zero.
error9:
   BNE error9

   LDY #$61
   LDX #$26
   LDA #$44
   JSR write_vram ; $2661 := $44


end:
   JMP end



; X:Y contains 16-bit address point in VRAM
; A contains value to write.
write_vram:
   STY $9F20
   STX $9F21
   STZ $9F22   ; No increment
   STA $9F23
   RTS
   

.segment "VECTORS"
   .addr main
   .addr main
   .addr main
