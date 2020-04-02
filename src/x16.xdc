# This file is specific for the Nexys 4 DDR board.

# Clock and reset
set_property -dict { PACKAGE_PIN E3  IOSTANDARD LVCMOS33 } [get_ports { sys_clk_i       }];    # CLK100MHZ
set_property -dict { PACKAGE_PIN C12 IOSTANDARD LVCMOS33 } [get_ports { sys_rstn_i      }];    # CPU_RESETN

# Switches and LEDs
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[0]   }];    # SW0
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[1]   }];    # SW1
set_property -dict { PACKAGE_PIN M13 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[2]   }];    # SW2
set_property -dict { PACKAGE_PIN R15 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[3]   }];    # SW3
set_property -dict { PACKAGE_PIN R17 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[4]   }];    # SW4
set_property -dict { PACKAGE_PIN T18 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[5]   }];    # SW5
set_property -dict { PACKAGE_PIN U18 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[6]   }];    # SW6
set_property -dict { PACKAGE_PIN R13 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[7]   }];    # SW7
set_property -dict { PACKAGE_PIN T8  IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[8]   }];    # SW8
set_property -dict { PACKAGE_PIN U8  IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[9]   }];    # SW9
set_property -dict { PACKAGE_PIN R16 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[10]  }];    # SW10
set_property -dict { PACKAGE_PIN T13 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[11]  }];    # SW11
set_property -dict { PACKAGE_PIN H6  IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[12]  }];    # SW12
set_property -dict { PACKAGE_PIN U12 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[13]  }];    # SW13
set_property -dict { PACKAGE_PIN U11 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[14]  }];    # SW14
set_property -dict { PACKAGE_PIN V10 IOSTANDARD LVCMOS33 } [get_ports { async_sw_i[15]  }];    # SW15
set_property -dict { PACKAGE_PIN H17 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[0]  }];    # LED0
set_property -dict { PACKAGE_PIN K15 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[1]  }];    # LED1
set_property -dict { PACKAGE_PIN J13 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[2]  }];    # LED2
set_property -dict { PACKAGE_PIN N14 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[3]  }];    # LED3
set_property -dict { PACKAGE_PIN R18 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[4]  }];    # LED4
set_property -dict { PACKAGE_PIN V17 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[5]  }];    # LED5
set_property -dict { PACKAGE_PIN U17 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[6]  }];    # LED6
set_property -dict { PACKAGE_PIN U16 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[7]  }];    # LED7
set_property -dict { PACKAGE_PIN V16 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[8]  }];    # LED8
set_property -dict { PACKAGE_PIN T15 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[9]  }];    # LED9
set_property -dict { PACKAGE_PIN U14 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[10] }];    # LED10
set_property -dict { PACKAGE_PIN T16 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[11] }];    # LED11
set_property -dict { PACKAGE_PIN V15 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[12] }];    # LED12
set_property -dict { PACKAGE_PIN V14 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[13] }];    # LED13
set_property -dict { PACKAGE_PIN V12 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[14] }];    # LED14
set_property -dict { PACKAGE_PIN V11 IOSTANDARD LVCMOS33 } [get_ports { async_led_o[15] }];    # LED15

# PS/2 keyboard
set_property -dict { PACKAGE_PIN F4  IOSTANDARD LVCMOS33 } [get_ports { ps2_clk_io      }];    # PS2_CLK
set_property -dict { PACKAGE_PIN B2  IOSTANDARD LVCMOS33 } [get_ports { ps2_data_io     }];    # PS2_DATA

# Connected to Ethernet PHY
set_property -dict { PACKAGE_PIN A9  IOSTANDARD LVCMOS33 } [get_ports { eth_mdio_io     }];    # ETH_MDIO
set_property -dict { PACKAGE_PIN C9  IOSTANDARD LVCMOS33 } [get_ports { eth_mdc_o       }];    # ETH_MDC
set_property -dict { PACKAGE_PIN B3  IOSTANDARD LVCMOS33 } [get_ports { eth_rstn_o      }];    # ETH_RSTN
set_property -dict { PACKAGE_PIN D10 IOSTANDARD LVCMOS33 } [get_ports { eth_rxd_i[1]    }];    # ETH_RXD[1]
set_property -dict { PACKAGE_PIN C11 IOSTANDARD LVCMOS33 } [get_ports { eth_rxd_i[0]    }];    # ETH_RXD[0]
set_property -dict { PACKAGE_PIN C10 IOSTANDARD LVCMOS33 } [get_ports { eth_rxerr_i     }];    # ETH_RXERR
set_property -dict { PACKAGE_PIN A10 IOSTANDARD LVCMOS33 } [get_ports { eth_txd_o[0]    }];    # ETH_TXD[0]
set_property -dict { PACKAGE_PIN A8  IOSTANDARD LVCMOS33 } [get_ports { eth_txd_o[1]    }];    # ETH_TXD[1]
set_property -dict { PACKAGE_PIN B9  IOSTANDARD LVCMOS33 } [get_ports { eth_txen_o      }];    # ETH_TXEN
set_property -dict { PACKAGE_PIN D9  IOSTANDARD LVCMOS33 } [get_ports { eth_crsdv_i     }];    # ETH_CRSDV
set_property -dict { PACKAGE_PIN B8  IOSTANDARD LVCMOS33 } [get_ports { eth_intn_i      }];    # ETH_INTN
set_property -dict { PACKAGE_PIN D5  IOSTANDARD LVCMOS33 } [get_ports { eth_refclk_o    }];    # ETH_REFCLK

# SD card
set_property -dict { PACKAGE_PIN E2  IOSTANDARD LVCMOS33 } [get_ports { sd_reset_o      }];    # SD_RESET
set_property -dict { PACKAGE_PIN A1  IOSTANDARD LVCMOS33 } [get_ports { sd_cd_i         }];    # SD_CD
set_property -dict { PACKAGE_PIN B1  IOSTANDARD LVCMOS33 } [get_ports { sd_sck_o        }];    # SD_SCK
set_property -dict { PACKAGE_PIN C1  IOSTANDARD LVCMOS33 } [get_ports { sd_cmd_io       }];    # SD_CMD
set_property -dict { PACKAGE_PIN C2  IOSTANDARD LVCMOS33 } [get_ports { sd_dat_io[0]    }];    # SD_DAT0
set_property -dict { PACKAGE_PIN E1  IOSTANDARD LVCMOS33 } [get_ports { sd_dat_io[1]    }];    # SD_DAT1
set_property -dict { PACKAGE_PIN F1  IOSTANDARD LVCMOS33 } [get_ports { sd_dat_io[2]    }];    # SD_DAT2
set_property -dict { PACKAGE_PIN D2  IOSTANDARD LVCMOS33 } [get_ports { sd_dat_io[3]    }];    # SD_DAT3

# Audio output
set_property -dict { PACKAGE_PIN A11 IOSTANDARD LVCMOS33 } [get_ports { aud_pwm_o       }];    # AUD_PWM
set_property -dict { PACKAGE_PIN D12 IOSTANDARD LVCMOS33 } [get_ports { aud_sd_o        }];    # AUD_SD

# VGA output
set_property -dict { PACKAGE_PIN A4  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[11]   }];    # VGA_R3
set_property -dict { PACKAGE_PIN C5  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[10]   }];    # VGA_R2
set_property -dict { PACKAGE_PIN B4  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[9]    }];    # VGA_R1
set_property -dict { PACKAGE_PIN A3  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[8]    }];    # VGA_R0
set_property -dict { PACKAGE_PIN A6  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[7]    }];    # VGA_G3
set_property -dict { PACKAGE_PIN B6  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[6]    }];    # VGA_G2
set_property -dict { PACKAGE_PIN A5  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[5]    }];    # VGA_G1
set_property -dict { PACKAGE_PIN C6  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[4]    }];    # VGA_G0
set_property -dict { PACKAGE_PIN D8  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[3]    }];    # VGA_B3
set_property -dict { PACKAGE_PIN D7  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[2]    }];    # VGA_B2
set_property -dict { PACKAGE_PIN C7  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[1]    }];    # VGA_B1
set_property -dict { PACKAGE_PIN B7  IOSTANDARD LVCMOS33 } [get_ports { vga_col_o[0]    }];    # VGA_B0
set_property -dict { PACKAGE_PIN B11 IOSTANDARD LVCMOS33 } [get_ports { vga_hs_o        }];    # VGA_HS
set_property -dict { PACKAGE_PIN B12 IOSTANDARD LVCMOS33 } [get_ports { vga_vs_o        }];    # VGA_VS


# Clock definition
create_clock -name sys_clk -period 10.00 [get_ports {sys_clk_i}];
create_generated_clock -name ym2151_clk -source [get_pins {i_clk_rst/i_mmcm_adv/CLKOUT4}] -divide_by 8 [get_pins {i_clk_rst/ym2151_cnt_r_reg[2]/Q}];

# CDC
set_false_path -from [get_clocks -of_objects [get_pins i_clk_rst/i_mmcm_adv/CLKOUT0]] -to [get_pins -hierarchical {*gen_cdc.dst_dat_r_reg[*]/D}]
set_false_path -from [get_clocks -of_objects [get_pins i_clk_rst/i_mmcm_adv/CLKOUT1]] -to [get_pins -hierarchical {*gen_cdc.dst_dat_r_reg[*]/D}]
set_false_path -from [get_clocks -of_objects [get_pins i_clk_rst/i_mmcm_adv/CLKOUT2]] -to [get_pins -hierarchical {*gen_cdc.dst_dat_r_reg[*]/D}]
set_false_path -from [get_clocks -of_objects [get_pins i_clk_rst/i_mmcm_adv/CLKOUT3]] -to [get_pins -hierarchical {*gen_cdc.dst_dat_r_reg[*]/D}]
set_false_path -from [get_clocks -of_objects [get_pins i_clk_rst/i_mmcm_adv/CLKOUT4]] -to [get_pins -hierarchical {*gen_cdc.dst_dat_r_reg[*]/D}]
set_false_path -from [get_clocks ym2151_clk] -to [get_pins -hierarchical {*gen_cdc.dst_dat_r_reg[*]/D}]

# Configuration Bank Voltage Select
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

