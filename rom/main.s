.feature labels_without_colons
.setcpu "65c02"

; This is the main entry point for the File System over Ethernet.
; This acts as a direct drop-in replacement for the CBDOS module.

; Bank switching performed in kernal/serial4.0.s
.export file_secnd      ; Send secondary address after listen
.export file_tksa       ; Talk second address
.export file_acptr      ; Input a byte from serial bus
.export file_ciout      ; Buffered output to serial bus
.export file_untlk      ; Send untalk command on serial bus
.export file_unlsn      ; Send unlisten command on serial bus
.export file_listn      ; Command serial bus device to listen
.export file_talk       ; Command serial bus device to talk

.import eth_arp_send_request
.import eth_rx_poll
.import eth_server_mac
.import eth_tftp_send_read_request

.segment "BSS"

file_cmd: .res 1        ; Upper 4 bits of the channel ID.

.segment "CODE"


; The sequence of events upon a LOAD command are as follows:
; * file_listn, with device number in A.
; * file_secnd, with $Fx, where x is channel.
; * file_ciout, with filename
; * file_unlsn
;
; * file_talk
; * file_tksa
; * file_acptr
; * file_untlk
;
; * file_listn
; * file_secnd, with $Ex
; * file_unlsn
;
; Errors are reported in the variable "status".
; * Bit 1 indicates timeout or file-not-found.
; * Bit 6 indicates eoi.

; For now, the TFTP server IP address is hard-coded in eth_server_ip.


; The A-register contains the device number. Can be ignored.
; Send ARP request for the servers MAC address.
file_listn
      jsr eth_arp_send_request
      rts

; The A-register contains the listening address.
; If it is $Fx then the bytes sent via file_ciout
; will be a filename to be associated with channel x.
; We ignore the channel number, because only one channel is
; supported.
file_secnd
      and #$f0
      sta file_cmd
      rts

file_ciout
      sta eth_tx_dat
      rts

file_unlsn
      rts


; Establish the channel
; Send the ARP for the server IP address
; and wait for response
file_talk
      jsr arp_send_request       ; Send ARP request
@1    jsr eth_rx_poll            ; Process any replies
      lda server_mac             ; Has server MAC address been updated?
      cmp #$ff
      beq @1                     ; If no, wait some more.
      rts

; Tell it to load
; Send the RRQ
; ??? and wait for response ????
file_tksa
      lda #>filename
      ldx #<filename
      jsr tftp_send_read_request

; Get byte
file_acptr


