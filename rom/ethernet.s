.feature labels_without_colons
.setcpu "65c02"

; Ethernet protocol

; External API
.export eth_rx_start
.export eth_rx_poll
.export eth_rx_check_len
.export eth_tx

.import ip_receive
.import arp_receive

.include "ethernet.inc"


.segment "BSS"
      eth_len:    .res 2   ; Length of last received frame

.segment "CODE"

; Get ready to receive packets
; inputs: none
; outputs: none
eth_rx_start
      lda #1
      sta eth_rx_own       ; Transfer ownership to FPGA
      rts


; Is a packet ready?
; inputs: none
; outputs:
; carry clear : a packet was received. Stored in virtual address 0x0000.
; carry set   : no packet is raedy
eth_rx_pending
      lda eth_rx_own
      ror a                ; Move bit 0 to carry
      rts


; Checks whether the frame contains at least A:X number of bytes.
; Return carry clear if yes, and carry set if no.
eth_rx_check_len
      cmp eth_len+1
      bne @return
      cpx eth_len
@return
      rts
      

; Check for received Ethernet packet, and process it.
; Should be called in a polling fashion, i.e. in a busy loop.
eth_rx_poll
      jsr eth_rx_pending
      bcc @eth_rx           ; Got a packet
      rts

@eth_rx
      ; Initialize read pointer
      stz eth_rx_lo
      stz eth_rx_hi

      ; Read received length
      lda eth_rx_dat       ; Get MSB of length in A
      ldx eth_rx_dat       ; Get LSB of length in X
      sta eth_len+1
      stx eth_len

      ; Make sure the entire MAC header is received
      lda #0
      ldx #(mac_end - mac_start)
      jsr eth_rx_check_len
      bcc @restart_receiver

      ; Get Ethernet protocol
      lda eth_rx_dat
      ldx eth_rx_dat

      ; Check for $0800 (IP) and $0806 (ARP)
      cmp 8
      bne @restart_receiver
      cpx 0
      bne @no_ip
      jsr ip_receive       ; in ip.s
      jmp eth_rx_start

@no_ip
      cpx 6
      bne @no_arp
      jsr arp_receive      ; in arp.s
      jmp eth_rx_start

@no_arp
@restart_receiver
      jmp eth_rx_start     ; Get ready to receive new frame.

; Send a packet
; inputs: Packet stored in virtual address 0x0800. Must be padded to minimum 60 bytes.
; outputs: Returns when packet is sent.
eth_tx
      lda #1
      sta eth_tx_own       ; Transfer ownership to FPGA
@wait lda eth_tx_own
      bne @wait            ; Wait until transfer is complete
      rts


