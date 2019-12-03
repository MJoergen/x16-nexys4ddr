.setcpu "65c02"

; UDP protocol

; External API
.export eth_udp_receive
.export eth_udp_register_rx_callback
.export eth_udp_register_tx_callback
.export eth_udp_set_my_port
.export eth_udp_tx
.export eth_my_udp
.export eth_server_udp

.import eth_rx_check_len
.import eth_tx
.import eth_tx_pad
.import ethernet_insert_header
.import eth_ip_insert_header
.import eth_tx_get_len
.import eth_tx_end


.include "ethernet.inc"

.bss
      eth_my_udp:          .res 2   ; Our own UDP port number.
      eth_server_udp:      .res 2   ; Servers UDP port number.
      eth_udp_rx_callback: .res 2   ; Called when receiving UDP packets.
      eth_udp_tx_callback: .res 2   ; Called when transmitting UDP packets.

.code


; -------------------------------------------------------------------
; A:X contains the port number to listen on
eth_udp_set_my_port:
      sta eth_my_udp
      stx eth_my_udp+1
      rts


; -------------------------------------------------------------------
; A:X contains the callback to be used, when receiving UDP packets
eth_udp_register_rx_callback:
      sta eth_udp_rx_callback
      stx eth_udp_rx_callback+1
      rts

      
; -------------------------------------------------------------------
; A:X contains the callback to be used, when transmitting UDP packets
eth_udp_register_tx_callback:
      sta eth_udp_tx_callback
      stx eth_udp_tx_callback+1
      rts
      

; -------------------------------------------------------------------
eth_udp_receive:
      ; Make sure UDP header is available
      lda #0
      ldx #(udp_end - mac_start)
      jsr eth_rx_check_len
      bcc @eth_udp_return

      ; Check if destination port matches our own.
      lda #udp_dst
      sta eth_rx_lo
      lda eth_rx_dat
      ldx eth_rx_dat
      cmp eth_my_udp
      bne @eth_udp_return
      cpx eth_my_udp+1
      bne @eth_udp_return
      jmp (eth_udp_rx_callback)

@eth_udp_return:
      rts


; -------------------------------------------------------------------
eth_udp_tx:
      lda #udp_start
      sta eth_tx_lo
      stz eth_tx_hi

      lda eth_my_udp             ; Source port
      sta eth_tx_dat
      lda eth_my_udp+1
      sta eth_tx_dat

      lda eth_server_udp         ; Destination port
      sta eth_tx_dat
      lda eth_server_udp+1
      sta eth_tx_dat

      stz eth_tx_dat             ; Length is empty for now
      stz eth_tx_dat

      stz eth_tx_dat             ; Checksum
      stz eth_tx_dat

      jsr jump_to_tx_callback    ; Fill in payload

      ldx eth_tx_lo              ; Store end-of-frame (little-endian)
      lda eth_tx_hi
      stx eth_tx_end
      sta eth_tx_end+1

      lda #0                     ; Calculate UDP length
      ldx #udp_start
      jsr eth_tx_get_len

      ldy #udp_len               ; Write UDP length
      sty eth_tx_lo
      stz eth_tx_hi
      sta eth_tx_dat             ; IP payload length is in A:X
      stx eth_tx_dat

      jsr eth_ip_insert_header

      lda #8
      ldx #0
      jsr ethernet_insert_header

      jsr eth_tx_pad

      jmp eth_tx


jump_to_tx_callback:
      jmp (eth_udp_tx_callback)

