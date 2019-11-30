.feature labels_without_colons
.setcpu "65c02"

; Ethernet protocol

; External API
.export eth_rx_start
.export eth_rx_poll
.export eth_rx_check_len
.export eth_tx
.export eth_tx_prepare

.import eth_arp_receive        ; arp.s
.import eth_ip_receive         ; ip.s
.import eth_my_mac             ; arp.s
.import eth_server_mac         ; arp.s

.include "ethernet.inc"


.segment "ZP" : zeropage
      eth_ptr:    .res 2   ; Generic pointer 

.segment "BSS"
      eth_rx_len: .res 2   ; Length of last received frame
      eth_tx_len: .res 2   ; Length of current transmitted frame

.segment "CODE"

; Get ready to receive packets
; inputs: none
; outputs: none
eth_rx_start
      lda #1
      sta eth_rx_own       ; Transfer ownership to FPGA
      rts


; Is a packet ready?
; inputs: none
; outputs:
; carry clear : a packet was received. Stored in virtual address 0x0000.
; carry set   : no packet is raedy
eth_rx_pending
      lda eth_rx_own
      ror a                ; Move bit 0 to carry
      rts


; Checks whether the frame contains at least A:X number of bytes.
; Return carry clear if yes, and carry set if no.
eth_rx_check_len
      cmp eth_rx_len+1
      bne @return
      cpx eth_rx_len
@return
      rts
      

; Check for received Ethernet packet, and process it.
; Should be called in a polling fashion, i.e. in a busy loop.
eth_rx_poll
      jsr eth_rx_pending
      bcs @return          ; No packet at the moment
      jsr eth_rx           ; Handle received packet
      jmp eth_rx_start
@return
      rts

eth_rx
      ; Initialize read pointer
      stz eth_rx_lo
      stz eth_rx_hi

      ; Read received length
      lda eth_rx_dat       ; Get MSB of length in A
      ldx eth_rx_dat       ; Get LSB of length in X
      sta eth_rx_len+1
      stx eth_rx_len

      ; Make sure the entire MAC header is received
      lda #0
      ldx #(mac_end - mac_start)
      jsr eth_rx_check_len
      bcc @return       ; Frame too small

      ; Get Ethernet type/length field
      lda #mac_tlen
      sta eth_rx_lo
      lda eth_rx_dat
      ldx eth_rx_dat

      ; Check for $0800 (IP) and $0806 (ARP)
      cmp 8
      bne @return
      cpx 0
      beq @ip
      cpx 6
      beq @arp
@return
      rts

@ip   jmp eth_ip_receive
@arp  jmp eth_arp_receive


; Prepare for transmit
; This function ensures that the previous transmitted packet
; is completely processed.
; This must be called before writing to the transmit area.
eth_tx_prepare
      lda eth_tx_own
      bne eth_tx_prepare    ; Wait until Tx buffer is ready
      rts


; Send a packet
; inputs: Packet stored in virtual address 0x0800. Must be padded to minimum 60 bytes.
; outputs: Returns when packet is sent.
eth_tx
      lda #1
      sta eth_tx_own       ; Transfer ownership to FPGA
      rts


; Insert ethernet header
; A:X contains Ethernet type/len
ethernet_insert_header
      pha

      ; Prepare Tx pointer
      lda #2
      sta eth_tx_lo
      stz eth_tx_hi

      ; Destination MAC address
      lda eth_server_mac
      sta eth_tx_dat
      lda eth_server_mac+1
      sta eth_tx_dat
      lda eth_server_mac+2
      sta eth_tx_dat
      lda eth_server_mac+3
      sta eth_tx_dat
      lda eth_server_mac+4
      sta eth_tx_dat
      lda eth_server_mac+5
      sta eth_tx_dat

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

      pla
      sta eth_tx_dat
      stx eth_tx_dat
      rts

