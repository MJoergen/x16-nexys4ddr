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

eth_ip_insert_header:
      lda #ip_start
      sta eth_tx_lo
      stz eth_tx_lo

      ; IP version
      lda #$45
      sta eth_tx_dat
      stz eth_tx_dat

      ; IP length
      lda eth_tx_len
      sec
      sbc #ip_start
      tax
      lda eth_tx_len+1
      sbc #0
      sta eth_tx_dat
      stx eth_tx_dat

      stz eth_tx_dat
      stz eth_tx_dat
      stz eth_tx_dat
      stz eth_tx_dat
      stz eth_tx_dat

      ; IP protocol
      lda #$11
      sta eth_tx_dat

      ; IP header checksum
      stz eth_tx_dat
      stz eth_tx_dat

      ; Source IP address
      lda eth_my_ip
      sta eth_tx_dat
      lda eth_my_ip+1
      sta eth_tx_dat
      lda eth_my_ip+2
      sta eth_tx_dat
      lda eth_my_ip+3
      sta eth_tx_dat

      ; Destination IP address
      lda eth_server_ip
      sta eth_tx_dat
      lda eth_server_ip+1
      sta eth_tx_dat
      lda eth_server_ip+2
      sta eth_tx_dat
      lda eth_server_ip+3
      sta eth_tx_dat

      rts


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


