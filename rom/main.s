.feature labels_without_colons
.setcpu "65c02"

.export talk
.export tksa
.export acptr

.import arp_send_request
.import eth_rx_poll
.import server_mac
.import tftp_send_read_request


; File transfer

; Establish the channel
; Send the ARP for the server IP address
; and wait for response
talk
      jsr arp_send_request       ; Send ARP request
@1    jsr eth_rx_poll            ; Process any replies
      lda server_mac             ; Has server MAC address been updated?
      cmp #$ff
      beq @1                     ; If no, wait some more.
      rts

; Tell it to load
; Send the RRQ
; ??? and wait for response ????
tksa
      lda #>filename
      ldx #<filename
      jsr tftp_send_read_request

; Get byte
acptr


