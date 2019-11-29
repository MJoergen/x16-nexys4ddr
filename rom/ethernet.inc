; Defines for the Ethernet FPGA module.
eth_rx_lo  = $9FE0
eth_rx_hi  = $9FE1
eth_rx_dat = $9FE2
eth_rx_own = $9FE3   ; 0 : owned by CPU, 1 : owned by FPGA
eth_tx_lo  = $9FE4
eth_tx_hi  = $9FE5
eth_tx_dat = $9FE6
eth_tx_own = $9FE7   ; 0 : owned by CPU, 1 : owned by FPGA

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

      tftp_start   = udp_end

