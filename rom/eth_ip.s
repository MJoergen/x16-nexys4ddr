.setcpu "65c02"

; IP protocol

; External API
.export eth_ip_receive
.export eth_ip_insert_header

.import eth_rx_check_len
.import eth_tx_len
.import eth_my_ip
.import eth_server_ip
.import eth_udp_receive

.include "ethernet.inc"

.bss
      eth_ip_ident:  .res 2

.code      

; -------------------------------------------------------------------
; Input:
; * A:X payload length
eth_ip_insert_header:
      pha   ; Store payload length
      phx

      lda #ip_start
      sta eth_tx_lo
      stz eth_tx_lo

      ; IP version
      lda #$45
      sta eth_tx_dat
      stz eth_tx_dat       ; DSCP

      ; IP length
      pla
      clc
      adc #20
      tay                  ; Temporarily store MSB
      pla
      adc #0
      sta eth_tx_dat
      sty eth_tx_dat

      ; IP identifier
      inc eth_ip_ident+1
      bne @1
      inc eth_ip_ident
@1:
      lda eth_ip_ident
      stz eth_tx_dat
      lda eth_ip_ident+1
      stz eth_tx_dat

      ; Flags and fragment
      stz eth_tx_dat
      stz eth_tx_dat

      lda #$ff
      sta eth_tx_dat       ; TTL

      ; IP protocol
      lda #$11
      sta eth_tx_dat

      ; IP header checksum
      stz eth_tx_dat
      stz eth_tx_dat

      write_my_ip_to_tx

      write_server_ip_to_tx

      ; Update IP checksum
      lda #ip_start
      sta eth_tx_lo
      ldx #0
      ldy #0

@loop:
      txa
      clc
      adc eth_tx_dat
      tax
      tya
      adc eth_tx_dat
      tay
      bcc @2
      inx
@2:   lda eth_tx_lo
      cmp #ip_end
      bne @loop

      lda #ip_chksum
      sta eth_tx_lo
      txa
      eor #$ff
      sta eth_tx_dat
      tya
      eor #$ff
      sta eth_tx_dat

      rts


; -------------------------------------------------------------------
eth_ip_receive:
      ; Make sure IP header is available
      lda #0
      ldx #(ip_end - mac_start)
      jsr eth_rx_check_len
      bcc @eth_ip_return

      lda eth_rx_dat    ; IP header
      cmp #$45
      bne @eth_ip_return

      ; Check whether destination IP address matches our own
      lda #ip_dst
      sta eth_rx_lo
      lda eth_rx_dat
      cmp eth_my_ip
      bne @eth_ip_return
      lda eth_rx_dat
      cmp eth_my_ip+1
      bne @eth_ip_return
      lda eth_rx_dat
      cmp eth_my_ip+2
      bne @eth_ip_return
      lda eth_rx_dat
      cmp eth_my_ip+3
      bne @eth_ip_return
      
      ; Multiplex on IP protocol
      ; Currenly, only UDP is supported.
      lda #ip_protocol
      sta eth_rx_lo
      lda eth_rx_dat
      cmp #$11
      bne @eth_ip_return
      jsr eth_udp_receive      ; in udp.s
@eth_ip_return:
      rts


