.setcpu "65c02"

; ARP protocol
; We maintain only a single address in the ARP table - that of the server.

; External API
.export eth_arp_receive

.export eth_arp_init
.export eth_arp_get_server_mac

.import ethernet_insert_header
.import eth_rx_check_len
.import eth_tx
.import eth_rx_poll

.include "ethernet.inc"


.macro read_server_mac_from_tx
      lda eth_rx_dat
      sta eth_server_mac
      lda eth_rx_dat
      sta eth_server_mac+1
      lda eth_rx_dat
      sta eth_server_mac+2
      lda eth_rx_dat
      sta eth_server_mac+3
      lda eth_rx_dat
      sta eth_server_mac+4
      lda eth_rx_dat
      sta eth_server_mac+5
.endmacro

.macro write_my_mac_to_tx
      lda eth_my_mac
      sta eth_tx_dat
      lda eth_my_mac+1
      sta eth_tx_dat
      lda eth_my_mac+2
      sta eth_tx_dat
      lda eth_my_mac+3
      sta eth_tx_dat
      lda eth_my_mac+4
      sta eth_tx_dat
      lda eth_my_mac+5
      sta eth_tx_dat
.endmacro

.macro write_my_ip_to_tx
      lda eth_my_ip
      sta eth_tx_dat
      lda eth_my_ip+1
      sta eth_tx_dat
      lda eth_my_ip+2
      sta eth_tx_dat
      lda eth_my_ip+3
      sta eth_tx_dat
.endmacro

.macro write_server_ip_to_tx
      lda eth_server_ip
      sta eth_tx_dat
      lda eth_server_ip+1
      sta eth_tx_dat
      lda eth_server_ip+2
      sta eth_tx_dat
      lda eth_server_ip+3
      sta eth_tx_dat
.endmacro


.segment "BSS"
      eth_my_mac:     .res 6   ; Hardcoded from factory
      eth_my_ip:      .res 4   ; Obtained from DHCP during boot
      eth_my_udp:     .res 2   ; Chosen by TFTP protocol
      eth_server_mac: .res 6   ; Obtained from ARP
      eth_server_ip:  .res 4   ; Configured by user. Default is 255.255.255.255
      eth_server_udp: .res 2   ; Chosen by TFTP protocol
      eth_timer:      .res 3   ; Used when waiting for ARP reply

.segment "CODE"

; Call once at reset
eth_arp_init:
      lda #$ff
      sta eth_server_mac
      sta eth_server_mac+1
      sta eth_server_mac+2
      sta eth_server_mac+3
      sta eth_server_mac+4
      sta eth_server_mac+5
      rts

; Returns Z=1 if MAC address is resolved
; Returns Z=0 if MAC address could not be resolved
eth_arp_get_server_mac:
      ; Check if MAC address already resolved
      lda eth_server_mac
      cmp #$ff
      bne @return_ok

@resend:
      ; Send ARP request
      jsr eth_arp_send_request

      ; Prepare timer
      lda #7
      stz eth_timer
      sta eth_timer+1
      sta eth_timer+2

@wait:
      jsr eth_rx_poll

      ; Have we received the MAC address?
      lda eth_server_mac
      cmp #$ff
      bne @return_ok

      dec eth_timer
      bne @wait
      dec eth_timer+1
      bne @wait
      dec eth_timer+2
      bne @resend

      ; Indicate timeout
      lda #$ff
      rts

@return_ok:
      lda #$00
      rts


; Process a received ARP packet.
; If we receive an ARP request for our IP address
; we send a reply.
; If we receive an ARP reply for the server IP address
; we store the MAC address.
eth_arp_receive:
      ; Make sure ARP header is available
      lda #0
      ldx #(arp_end - mac_start)
      jsr eth_rx_check_len
      bcc eth_arp_return

      ; Multiple on ARP code
      lda #arp_start+7
      sta eth_rx_lo
      lda eth_rx_dat
      cmp #1
      beq eth_arp_receive_request
      cmp #2
      beq eth_arp_receive_reply
eth_arp_return:
      rts

eth_arp_receive_request:
      ; For now we just send an ARP reply with our address always.
      ; TODO: Add check for whether the request is for our IP address.
      jmp eth_arp_send_reply

eth_arp_receive_reply:
      lda #arp_src_prot       ; Is reply coming from the server?
      sta eth_rx_lo
      lda eth_rx_dat
      cmp eth_server_ip
      bne eth_arp_return
      lda eth_rx_dat
      cmp eth_server_ip+1
      bne eth_arp_return
      lda eth_rx_dat
      cmp eth_server_ip+2
      bne eth_arp_return
      lda eth_rx_dat
      cmp eth_server_ip+3
      bne eth_arp_return
      
      lda #arp_src_hw         ; Copy servers MAC address
      sta eth_rx_lo
      read_server_mac_from_tx
      rts


eth_arp_send_request:
      lda #$ff
      sta eth_server_mac
      sta eth_server_mac+1
      sta eth_server_mac+2
      sta eth_server_mac+3
      sta eth_server_mac+4
      sta eth_server_mac+5

      lda #arp_start
      sta eth_tx_lo
      lda #8
      sta eth_tx_hi

      ; ARP header
      lda #0                  ; Hardware address = Ethernet
      sta eth_tx_dat
      lda #1
      sta eth_tx_dat
      lda #8                  ; Protocol addresss = IP
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #6                  ; Hardware address length
      sta eth_tx_dat
      lda #4                  ; Protocol address length
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #1                  ; ARP request
      sta eth_tx_dat

      write_my_mac_to_tx      ; Sender hardware address

      write_my_ip_to_tx       ; Sender protocol address

      lda #0                  ; Target hardware address (unknown)
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat

      write_server_ip_to_tx   ; Target protocol address

@pad: stz eth_tx_dat          ; Padding
      lda eth_tx_lo
      cmp #62
      bcc @pad

      lda #8
      ldx #6
      jsr ethernet_insert_header

      ; Build the packet at virtual address $0800
      stz eth_tx_lo
      lda #8
      sta eth_tx_hi

      ; Set length of packet
      lda #60                 ; Minimum length is 60 bytes exluding CRC.
      sta eth_tx_dat
      stz eth_tx_dat

      jmp eth_tx

eth_arp_send_reply:
      lda #arp_start
      sta eth_tx_lo
      lda #8
      sta eth_tx_hi

      ; ARP header
      lda #0                  ; Hardware address = Ethernet
      sta eth_tx_dat
      lda #1
      sta eth_tx_dat
      lda #8                  ; Protocol addresss = IP
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #6                  ; Hardware address length
      sta eth_tx_dat
      lda #4                  ; Protocol address length
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #2                  ; ARP reply
      sta eth_tx_dat

      write_my_mac_to_tx      ; Sender hardware address

      write_my_ip_to_tx       ; Sender protocol address

      lda #arp_src_hw         ; Target hardware address
      sta eth_rx_lo
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat

      lda eth_rx_dat          ; Target protocol address
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat

@pad: stz eth_tx_dat          ; Padding
      lda eth_tx_lo
      cmp #62
      bcc @pad

      lda #8
      ldx #6
      jsr ethernet_insert_header

      ; Build the packet at virtual address $0800
      stz eth_tx_lo
      lda #8
      sta eth_tx_hi

      ; Set length of packet
      lda #60                 ; Minimum length is 60 bytes exluding CRC.
      sta eth_tx_dat
      stz eth_tx_dat

      jmp eth_tx


