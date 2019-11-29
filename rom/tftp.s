.feature labels_without_colons
.setcpu "65c02"

; TFTP protocol

; External API
.export tftp_send_ack
.export tftp_send_read_request
.export tftp_receive

.import ethernet_insert_header
.import eth_rx_check_len
.import eth_tx
.import eth_tx_len
.import ip_insert_header
.import my_udp
.import server_udp
.import server_mac
.importzp eth_ptr

.include "ethernet.inc"

.segment "BSS"
      exp_block_number: .res 2
      bytes_in_buffer:  .res 2

.segment "CODE"

tftp_receive
      ; Multiplex on TFTP opcode
      lda #tftp_start
      sta eth_rx_lo
      lda eth_rx_dat
      ldx eth_rx_dat
      cmp #0
      bne tftp_return
      cpx #1
      beq tftp_rrq
      cpx #2
      beq tftp_wrq
      cpx #3
      beq tftp_data
      cpx #4
      beq tftp_ack
      cpx #5
      beq tftp_error

tftp_return
      rts

tftp_rrq
tftp_wrq

tftp_ack
tftp_error

tftp_data
      ; Verify block number
      lda eth_rx_dat
      cmp exp_block_number+1
      bne tftp_return
      ldx eth_rx_dat
      cmp exp_block_number
      bne tftp_return

      

      

octet .byt "octet",0

tftp_send_ack
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
      jmp tftp_pad


; Send a RRQ.
; The filename is in A:X
tftp_send_read_request
      stx eth_ptr
      sta eth_ptr+1

      ; Increment source UDP port (big endian)
      ; This serves as a unique TID.
      inc my_udp+1
      bne @1
      inc my_udp
@1

      lda #1
      sta exp_block_number
      stz exp_block_number+1

      ; Initialize UDP header
      lda #udp_start
      sta server_udp+1
      stz server_udp

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

tftp_pad
      stz eth_tx_dat    ; Padding
      lda eth_tx_lo
      cmp #62
      bcc tftp_pad

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
      lda my_udp
      sta eth_tx_dat
      lda my_udp+1
      sta eth_tx_dat

      ; UDP destination port
      lda server_udp
      sta eth_tx_dat
      lda server_udp+1
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
      jsr ip_insert_header

      ; Insert MAC header
      lda #<server_mac
      sta eth_ptr
      lda #>server_mac
      sta eth_ptr+1
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



