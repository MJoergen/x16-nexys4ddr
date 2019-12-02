.setcpu "65c02"

; UDP protocol

; External API
.export eth_udp_receive
.export eth_udp_register_callback
.export eth_udp_set_my_port

.import eth_rx_check_len
.import eth_my_udp
.import eth_udp_callback

.include "ethernet.inc"

; A:X contains the port number to listen on
eth_udp_set_my_port:
      sta eth_my_udp
      stx eth_my_udp+1
      rts


; A:X contains the callback to be used, when receiving UDP packets
eth_udp_register_callback:
      sta eth_udp_callback
      stx eth_udp_callback+1
      rts
      

eth_udp_receive:
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
      bne @eth_udp_return
      cpx eth_my_udp+1
      bne @eth_udp_return
      jmp (eth_udp_callback)

@eth_udp_return:
      rts


