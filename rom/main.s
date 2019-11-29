; File transfer

; Establish the channel
; Send the ARP for the server IP address
; and wait for response
talk
      stz server_mac             ; Clear old MAC address
      jsr arp_send_request       ; Send ARP request
@¡:   jsr eth_rx_poll            ; Process any replies
      lda server_mac             ; Has server MAC address been updated?
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


