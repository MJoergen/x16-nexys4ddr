.feature labels_without_colons
.setcpu "65c02"

; TFTP protocol

; External API
.export tftp_send_read_request
.export tftp_receive

.import eth_rx_check_len

.include "ethernet.inc"


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
tftp_data
tftp_ack
tftp_error


; Send a RRQ.
; The filename is in A:X
tftp_send_read_request

