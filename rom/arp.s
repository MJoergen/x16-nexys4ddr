.feature labels_without_colons
.setcpu "65c02"

; ARP protocol
; We maintain only a single address in the ARP table - that of the server.

; External API
.export arp_receive
.export arp_send_request
.export my_mac
.export my_ip
.export server_mac
.export server_ip

.import eth_tx
.import eth_rx_check_len

.include "ethernet.inc"

.segment "BSS"
      my_mac:     .res 6   ; Hardcoded from factory
      my_ip:      .res 4   ; Obtained from DHCP during boot
      my_udp:     .res 2   ; Chosen by TFTP protocol
      server_mac: .res 6   ; Obtained from ARP
      server_ip:  .res 4   ; Configured by user. Default is 255.255.255.255
      server_udp: .res 2   ; Chosen by TFTP protocol

.segment "CODE"



; Process a receiver ARP packet.
; If we receive an ARP request for our IP address
; we send a reply.
; If we receive an ARP reply for the server IP address
; we store the MAC address.
arp_receive
      ; Make sure ARP header is available
      lda #0
      ldx #(arp_end - mac_start)
      jsr eth_rx_check_len
      bcc arp_return

      ; Multiple on ARP code
      lda #arp_start+7
      sta eth_rx_lo
      lda eth_rx_dat
      cmp #1
      beq arp_receive_request
      cmp #2
      beq arp_receive_reply
arp_return
      rts

arp_receive_request
      ; For now we just send an ARP reply with our address always.
      ; TODO: Add check for whether the request is for our IP address.
      jmp arp_send_reply

arp_receive_reply
      lda #arp_src_prot    ; Is reply coming from the server?
      sta eth_rx_lo
      lda eth_rx_dat
      cmp server_ip
      bne arp_return
      lda eth_rx_dat
      cmp server_ip+1
      bne arp_return
      lda eth_rx_dat
      cmp server_ip+2
      bne arp_return
      lda eth_rx_dat
      cmp server_ip+3
      bne arp_return
      
      lda #arp_src_hw      ; Copy servers MAC address
      sta eth_rx_lo
      lda eth_rx_dat
      sta server_mac
      lda eth_rx_dat
      sta server_mac+1
      lda eth_rx_dat
      sta server_mac+2
      lda eth_rx_dat
      sta server_mac+3
      lda eth_rx_dat
      sta server_mac+4
      lda eth_rx_dat
      sta server_mac+5
      rts


arp_send_reply
      ; Build the packet at virtual address $0800
      stz eth_tx_lo
      lda #8
      sta eth_tx_hi

      ; Set length of packet
      lda #60           ; Minimum length is 60 bytes exluding CRC.
      sta eth_tx_dat
      stz eth_tx_dat

      ; MAC header
      lda #arp_src_hw
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
      lda my_mac
      sta eth_tx_dat
      lda my_mac+1
      sta eth_tx_dat
      lda my_mac+2
      sta eth_tx_dat
      lda my_mac+3
      sta eth_tx_dat
      lda my_mac+4
      sta eth_tx_dat
      lda my_mac+5
      sta eth_tx_dat
      lda #8
      sta eth_tx_dat
      lda #6
      sta eth_tx_dat

      ; ARP
      lda #0            ; Hardware address = Ethernet
      sta eth_tx_dat
      lda #1
      sta eth_tx_dat
      lda #8            ; Protocol addresss = IP
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #6            ; Hardware address length
      sta eth_tx_dat
      lda #4            ; Protocol address length
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #2            ; ARP reply
      sta eth_tx_dat

      lda my_mac        ; Sender hardware address
      sta eth_tx_dat
      lda my_mac+1
      sta eth_tx_dat
      lda my_mac+2
      sta eth_tx_dat
      lda my_mac+3
      sta eth_tx_dat
      lda my_mac+4
      sta eth_tx_dat
      lda my_mac+5
      sta eth_tx_dat

      lda my_ip         ; Sender protocol address
      sta eth_tx_dat
      lda my_ip+1
      sta eth_tx_dat
      lda my_ip+2
      sta eth_tx_dat
      lda my_ip+3
      sta eth_tx_dat

      lda #arp_src_hw   ; Target hardware address
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

      lda eth_rx_dat    ; Target protocol address
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat
      lda eth_rx_dat
      sta eth_tx_dat

@pad  stz eth_tx_dat    ; Padding
      lda eth_tx_lo
      cmp #62
      bcc @pad

      jmp eth_tx


arp_send_request
      ; Build the packet at virtual address $0800
      stz eth_tx_lo
      lda #8
      sta eth_tx_hi

      ; Set length of packet
      lda #60           ; Minimum length is 60 bytes exluding CRC.
      sta eth_tx_dat
      stz eth_tx_dat

      ; MAC header
      lda #$ff
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      lda my_mac
      sta eth_tx_dat
      lda my_mac+1
      sta eth_tx_dat
      lda my_mac+2
      sta eth_tx_dat
      lda my_mac+3
      sta eth_tx_dat
      lda my_mac+4
      sta eth_tx_dat
      lda my_mac+5
      sta eth_tx_dat
      lda #8
      sta eth_tx_dat
      lda #6
      sta eth_tx_dat

      ; ARP
      lda #0            ; Hardware address = Ethernet
      sta eth_tx_dat
      lda #1
      sta eth_tx_dat
      lda #8            ; Protocol addresss = IP
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #6            ; Hardware address length
      sta eth_tx_dat
      lda #4            ; Protocol address length
      sta eth_tx_dat
      lda #0
      sta eth_tx_dat
      lda #1            ; ARP request
      sta eth_tx_dat

      lda my_mac        ; Sender hardware address
      sta eth_tx_dat
      lda my_mac+1
      sta eth_tx_dat
      lda my_mac+2
      sta eth_tx_dat
      lda my_mac+3
      sta eth_tx_dat
      lda my_mac+4
      sta eth_tx_dat
      lda my_mac+5
      sta eth_tx_dat

      lda my_ip         ; Sender protocol address
      sta eth_tx_dat
      lda my_ip+1
      sta eth_tx_dat
      lda my_ip+2
      sta eth_tx_dat
      lda my_ip+3
      sta eth_tx_dat

      lda #0            ; Target hardware address (unknown)
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat
      sta eth_tx_dat

      lda server_ip     ; Target protocol address
      sta eth_tx_dat
      lda server_ip+1
      sta eth_tx_dat
      lda server_ip+2
      sta eth_tx_dat
      lda server_ip+3
      sta eth_tx_dat

@pad  stz eth_tx_dat    ; Padding
      lda eth_tx_lo
      cmp #62
      bcc @pad

      jmp eth_tx

