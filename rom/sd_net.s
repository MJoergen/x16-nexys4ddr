.importzp write_blkptr, read_blkptr

.export sdcard_init, sdcard_detect
.export sd_read_block, sd_read_multiblock, sd_write_block

; XXX: 256-byte sector emulation; should go away:
; XXX: the caller should cache a 512 byte sector instead
.export sd_read_block_lower, sd_read_block_upper

; public block api
.export read_block=sd_read_block
.export write_block=sd_write_block

.import lba_addr, blocks
.import timer

.import eth_arp_get_server_mac
.import eth_udp_set_my_port
.import eth_udp_register_rx_callback
.import eth_udp_register_tx_callback
.import eth_udp_tx
.import eth_rx_poll

.include "ethernet.inc"

.bss
sd_net_expect_ack: .res 1
sd_net_timeout:    .res 1
sd_net_retries:    .res 1

.code

; This module emulates a virtual SD card on top of UDP
; It uses port 5344 (ascii for SD).
; The format is as follows:
; opcode : 1 byte
; lba    ; 4 bytes
; data   : 512 bytes (optional)
;
; There are four opcodes:
; 1 : read request
; 2 : read acknowledge
; 3 : write request
; 4 : write acknowledge


;---------------------------------------------------------------------
; Detect SD Card
;   out:
;     Z=1 sd card available, Z=0 otherwise A=ENODEV
;---------------------------------------------------------------------
sdcard_detect:
      lda #0
      rts


;---------------------------------------------------------------------
; Init SD Card
; Destructive: A, X, Y
;
;   out:  Z=1 on success, Z=0 otherwise
;---------------------------------------------------------------------
sdcard_init:
      lda #$53                      ; 'S'
      ldx #$44                      ; 'D'
      jsr eth_udp_set_my_port
      lda #>eth_udp_rx_callback
      ldx #<eth_udp_rx_callback
      jsr eth_udp_register_rx_callback
      lda #>eth_udp_tx_callback
      ldx #<eth_udp_tx_callback
      jsr eth_udp_register_tx_callback

      ; Send ARP request and wait for ARP reply
      jsr eth_arp_get_server_mac
      lda #0
      rts


;---------------------------------------------------------------------
; Read block from SD Card
;in:
;   block lba in lba_addr
;
;out:
;  A - A = 0 on success, error code otherwise
;---------------------------------------------------------------------
sd_read_block:
      lda #2
      sta sd_net_expect_ack   ; Expect read ack
      lda timer+2
      adc #60                 ; Don't bother clearing carry
      sta sd_net_timeout      ; Timeout after 1 second.
      lda #4
      sta sd_net_retries      ; Try 4 times before giving up.

@resend:
      ; Send UDP request
      jsr eth_udp_tx          ; This calls the eth_udp_tx_callback
                              ; and sends the packet

@loop:
      ; Read UDP response and copy 512 bytes to (read_blkptr)
      jsr eth_rx_poll         ; This calls the eth_udp_rx_callback
      lda sd_net_expect_ack
      beq @return
      lda timer+2
      cmp sd_net_timeout
      bne @loop
      dec sd_net_retries
      bne @resend
      lda #$ff                ; Timeout
      rts

@return:
      lda #0
      rts


;---------------------------------------------------------------------
; Called when an UDP packet is about to be sent
; eth_tx_dat points to the first byte of the UDP payload.
;---------------------------------------------------------------------
eth_udp_tx_callback:
      ldx sd_net_expect_ack
      dex
      stx eth_tx_dat

      lda lba_addr
      sta eth_tx_dat
      lda lba_addr+1
      sta eth_tx_dat
      lda lba_addr+2
      sta eth_tx_dat
      lda lba_addr+3
      sta eth_tx_dat

      cpx #3
      bne @return

      ldy #0
@l1:  lda (write_blkptr),y
      sta eth_tx_dat
      iny
      bne @l1

      inc write_blkptr+1
@l2:  lda (write_blkptr),y
      sta eth_tx_dat
      iny
      bne @l2
      
@return:
      rts



;---------------------------------------------------------------------
; Called when an UDP packet for our port number is received.
; eth_rx_dat points to the first byte of the UDP payload.
;---------------------------------------------------------------------
eth_udp_rx_callback:
      ; Check if opcode is what we expect
      lda eth_rx_dat
      cmp sd_net_expect_ack
      bne @return

      ; Check if LBA_ADDR matches the expected value.
      lda eth_rx_dat
      cmp lba_addr
      bne @return
      lda eth_rx_dat
      cmp lba_addr+1
      bne @return
      lda eth_rx_dat
      cmp lba_addr+2
      bne @return
      lda eth_rx_dat
      cmp lba_addr+3
      bne @return

      lda sd_net_expect_ack
      cmp #2
      bne @return

      ldy #0
@l1:  lda eth_rx_dat
      sta (read_blkptr),y
      iny
      bne @l1

      inc read_blkptr+1
@l2:  lda eth_rx_dat
      sta (read_blkptr),y
      iny
      bne @l2

@return:
      rts


; XXX: 256-byte sector emulation; should go away:
; XXX: the caller should cache a 512 byte sector instead
; ***** XXX
sd_read_block_lower:
      ; Send UDP request
      ; Wait for UDP response
      ; Copy first 256 bytes to (read_blkptr)
      lda #$ff          ; Error
      rts

sd_read_block_upper:
      ; Send UDP request
      ; Wait for UDP response
      ; Copy last 256 bytes to (read_blkptr)
      lda #$ff          ; Error
      rts


;---------------------------------------------------------------------
; Read multiple blocks from SD Card
;in:
;   block lba in lba_addr
;   block count in blocks
;
;out:
;  A - A = 0 on success, error code otherwise
;---------------------------------------------------------------------
sd_read_multiblock:
@l1:  jsr sd_read_block
      bne @exit
      inc read_blkptr+1
      dec blocks
      bne @l1
      lda #0
@exit:
      rts


;---------------------------------------------------------------------
; Write block to SD Card
;in:
;   block lba in lba_addr
;
;out:
;  A - A = 0 on success, error code otherwise
;---------------------------------------------------------------------
sd_write_block:
      ; Send UDP request with data from (write_blkptr)
      ; Wait for UDP response
      lda #$ff       ; Error
      rts

