.feature labels_without_colons
.setcpu "65c02"

; IP protocol

; External API
.export ip_receive
.export ip_insert_header

.import eth_rx_check_len
.import eth_tx_len
.import my_ip
.import server_ip
.import udp_receive

.include "ethernet.inc"

ip_insert_header
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
      lda my_ip
      sta eth_tx_dat
      lda my_ip+1
      sta eth_tx_dat
      lda my_ip+2
      sta eth_tx_dat
      lda my_ip+3
      sta eth_tx_dat

      ; Destination IP address
      lda server_ip
      sta eth_tx_dat
      lda server_ip+1
      sta eth_tx_dat
      lda server_ip+2
      sta eth_tx_dat
      lda server_ip+3
      sta eth_tx_dat

      rts


ip_receive
      ; Make sure IP header is available
      lda #0
      ldx #(ip_end - mac_start)
      jsr eth_rx_check_len
      bcc ip_return

      lda eth_rx_dat    ; IP header
      cmp #$45
      bne ip_return

      ; Check whether destination IP address matches our own
      lda #ip_dst
      sta eth_rx_lo
      lda eth_rx_dat
      cmp my_ip
      bne ip_return
      lda eth_rx_dat
      cmp my_ip+1
      bne ip_return
      lda eth_rx_dat
      cmp my_ip+2
      bne ip_return
      lda eth_rx_dat
      cmp my_ip+3
      bne ip_return
      
      ; Multiplex on IP protocol
      ; Currenly, only UDP is supported.
      lda #ip_protocol
      sta eth_rx_lo
      lda eth_rx_dat
      cmp #$11
      bne ip_return
      jsr udp_receive      ; in udp.s
ip_return
      rts


