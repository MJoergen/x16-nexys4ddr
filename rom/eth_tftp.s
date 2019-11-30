.feature labels_without_colons
.setcpu "65c02"

; TFTP protocol

; External API
.export eth_tftp_send_ack
.export eth_tftp_send_read_request
.export eth_tftp_receive

.import ethernet_insert_header
.import eth_rx_check_len
.import eth_tx
.import eth_tx_len
.import eth_ip_insert_header
.import eth_my_udp
.import eth_server_udp
.import eth_server_mac
.importzp eth_ptr

.include "ethernet.inc"

.segment "BSS"
      exp_block_number: .res 2
      bytes_in_buffer:  .res 2

.segment "CODE"

eth_tftp_receive
      ; Multiplex on TFTP opcode
      lda #tftp_start
      sta eth_rx_lo
      lda eth_rx_dat
      ldx eth_rx_dat
      cmp #0
      bne eth_tftp_return
      cpx #1
      beq eth_tftp_rrq
      cpx #2
      beq eth_tftp_wrq
      cpx #3
      beq eth_tftp_data
      cpx #4
      beq eth_tftp_ack
      cpx #5
      beq eth_tftp_error

eth_tftp_return
      rts

eth_tftp_rrq
eth_tftp_wrq

eth_tftp_ack
eth_tftp_error

eth_tftp_data
      ; Verify block number
      lda eth_rx_dat
      cmp exp_block_number+1
      bne eth_tftp_return
      ldx eth_rx_dat
      cmp exp_block_number
      bne eth_tftp_return

      

      

octet .byt "octet",0

eth_tftp_send_ack
      ; Prepare Tx pointer
      lda #tftp_start
      sta eth_tx_lo
      stz eth_tx_hi

      ; ACK
      stz eth_tx_dat
      lda #4
      sta eth_tx_dat

      lda exp_block_number+1
      sta eth_tx_dat
      lda exp_block_number
      sta eth_tx_dat

      inc exp_block_number
      bne @1
      inc exp_block_number+1
@1
      jmp eth_tftp_pad


; Send a RRQ.
; The filename is in A:X
eth_tftp_send_read_request
      stx eth_ptr
      sta eth_ptr+1

      ; Increment source UDP port (big endian)
      ; This serves as a unique TID.
      inc eth_my_udp+1
      bne @1
      inc eth_my_udp
@1

      lda #1
      sta exp_block_number
      stz exp_block_number+1

      ; Initialize UDP header
      lda #udp_start
      sta eth_server_udp+1
      stz eth_server_udp

      ; Prepare Tx pointer
      lda #tftp_start
      sta eth_tx_lo
      stz eth_tx_hi

      ; RRQ
      stz eth_tx_dat
      lda #1
      sta eth_tx_dat

      ; Insert zero-terminated filename
      ldy #$ff
@filename
      iny
      lda (eth_ptr),y
      sta eth_tx_dat
      bne @filename

      ; Insert zero-terminated mode
      ldy #$ff
@mode
      iny
      lda octet,y
      sta eth_tx_dat
      bne @mode

eth_tftp_pad
      stz eth_tx_dat    ; Padding
      lda eth_tx_lo
      cmp #62
      bcc eth_tftp_pad

      ; Save pointer to end of packet
      lda eth_tx_lo
      sta eth_tx_len
      lda eth_tx_hi
      sta eth_tx_len+1

      ; Insert UDP header
      lda #udp_start
      sta eth_tx_lo
      stz eth_tx_hi

      ; UDP source port
      lda eth_my_udp
      sta eth_tx_dat
      lda eth_my_udp+1
      sta eth_tx_dat

      ; UDP destination port
      lda eth_server_udp
      sta eth_tx_dat
      lda eth_server_udp+1
      sta eth_tx_dat

      ; UDP length
      lda eth_tx_len
      sec
      sbc #udp_start
      tax
      lda eth_tx_len+1
      sbc #0
      sta eth_tx_dat
      stx eth_tx_dat

      ; UDP checksum
      stz eth_tx_dat
      stz eth_tx_dat

      ; Insert IP header
      jsr eth_ip_insert_header

      ; Insert MAC header
      lda #8
      ldx #0
      jsr ethernet_insert_header

      ; Ethernet length
      stz eth_tx_lo
      stz eth_tx_hi
      lda eth_tx_len
      sec
      sbc #mac_start
      tax
      lda eth_tx_len+1
      sbc #0
      sta eth_tx_dat
      stx eth_tx_dat

      jmp eth_tx

