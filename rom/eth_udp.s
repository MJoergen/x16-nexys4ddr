.feature labels_without_colons
.setcpu "65c02"

; UDP protocol

; External API
.export eth_udp_receive

.import eth_rx_check_len
.import eth_tftp_receive
.import eth_my_udp

.include "ethernet.inc"


eth_udp_receive
      ; Make sure UDP header is available
      lda #0
      ldx #(udp_end - mac_start)
      jsr eth_rx_check_len
      bcc @eth_udp_return

      ; Check if source port matches TFTP port.
      lda #udp_dst
      sta eth_rx_lo
      lda eth_rx_dat
      ldx eth_rx_dat
      cmp eth_my_udp
      bne @check_default_port
      cpx eth_my_udp+1
      bne @check_default_port
      jmp eth_tftp_receive

@check_default_port
      cmp #0
      bne @eth_udp_return
      cpx #69
      bne @eth_udp_return
      jmp eth_tftp_receive

@eth_udp_return
      rts


