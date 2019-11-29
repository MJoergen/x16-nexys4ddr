.feature labels_without_colons
.setcpu "65c02"

; UDP protocol

; External API
.export udp_receive

.import eth_rx_check_len
.import tftp_receive
.import my_udp

.include "ethernet.inc"


udp_receive
      ; Make sure UDP header is available
      lda #0
      ldx #(udp_end - mac_start)
      jsr eth_rx_check_len
      bcc @udp_return

      ; Check if source port matches TFTP port.
      lda #udp_dst
      sta eth_rx_lo
      lda eth_rx_dat
      ldx eth_rx_dat
      cmp my_udp
      bne @check_default_port
      cpx my_udp+1
      bne @check_default_port
      jmp tftp_receive

@check_default_port
      cmp #0
      bne @udp_return
      cpx #69
      bne @udp_return
      jmp tftp_receive

@udp_return
      rts


