.feature labels_without_colons
.setcpu "65c02"

; IP protocol

; External API
.export ip_receive

.import eth_rx_check_len
.import udp_receive
.import my_ip

.include "ethernet.inc"


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


