; Defines for the Ethernet FPGA module.
eth_rx_lo     = $9FE0
eth_rx_hi     = $9FE1
eth_rx_dat    = $9FE2
eth_rx_own    = $9FE3   ; 0 : owned by CPU, 1 : owned by FPGA
;eth_rx_len_lo = $9FE4
;eth_rx_len_hi = $9FE5

eth_tx_lo     = $9FE8
eth_tx_hi     = $9FE9
eth_tx_dat    = $9FEA
eth_tx_own    = $9FEB   ; 0 : owned by CPU, 1 : owned by FPGA
;eth_tx_len_lo = $9FEC
;eth_tx_len_hi = $9FED

; Protocol defines
      mac_start    = 2
      mac_dst      = mac_start + 0   ; 6 bytes
      mac_src      = mac_start + 6   ; 6 bytes
      mac_tlen     = mac_start + 12  ; 2 bytes
      mac_end      = mac_start + 14

      arp_start    = mac_end
      arp_src_hw   = arp_start + 8   ; 6 bytes
      arp_src_prot = arp_start + 14  ; 4 bytes
      arp_dst_hw   = arp_start + 18  ; 6 bytes
      arp_dst_prot = arp_start + 24  ; 4 bytes
      arp_end      = arp_start + 28

      ip_start     = mac_end
      ip_version   = ip_start + 0    ; 1 byte
      ip_len       = ip_start + 2    ; 2 bytes
      ip_protocol  = ip_start + 9    ; 1 byte
      ip_chksum    = ip_start + 10   ; 2 bytes
      ip_src       = ip_start + 12   ; 4 bytes
      ip_dst       = ip_start + 16   ; 4 bytes
      ip_end       = ip_start + 20

      udp_start    = ip_end
      udp_src      = udp_start + 0   ; 2 bytes
      udp_dst      = udp_start + 2   ; 2 bytes
      udp_len      = udp_start + 4   ; 2 bytes
      udp_chksum   = udp_start + 6   ; 2 bytes
      udp_end      = udp_start + 8


.macro read_server_mac_from_rx
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

