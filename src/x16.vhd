library ieee;
use ieee.std_logic_1164.all;

-- This is the top level module of the X16. The ports on this entity are mapped
-- directly to pins on the FPGA.
--
-- Signal names are prefixed by the corresponding clock domain.

entity x16 is
   port (
      -- Clock and reset
      sys_clk_i    : in    std_logic;                       -- 100 MHz
      sys_rstn_i   : in    std_logic;                       -- CPU reset, active low

      -- Switches and LEDs
      async_sw_i   : in    std_logic_vector(15 downto 0);   -- Used for debugging.
      async_led_o  : out   std_logic_vector(15 downto 0);   -- Used for debugging.

      -- PS/2 keyboard
      ps2_clk_io   : inout std_logic;
      ps2_data_io  : inout std_logic;

      -- Connected to Ethernet PHY
      eth_txd_o    : out   std_logic_vector(1 downto 0);
      eth_txen_o   : out   std_logic;
      eth_rxd_i    : in    std_logic_vector(1 downto 0);
      eth_rxerr_i  : in    std_logic;
      eth_crsdv_i  : in    std_logic;
      eth_intn_i   : in    std_logic;
      eth_mdio_io  : inout std_logic;
      eth_mdc_o    : out   std_logic;
      eth_rstn_o   : out   std_logic;
      eth_refclk_o : out   std_logic;

      -- SD card
      sd_reset_o   : out   std_logic;
      sd_dat_io    : inout std_logic_vector(3 downto 0);    -- miso, cs
      sd_cmd_io    : inout std_logic;                       -- mosi
      sd_sck_o     : out   std_logic;
      sd_cd_i      : in    std_logic;

      -- Audio output
      aud_pwm_o    : inout std_logic;
      aud_sd_o     : out   std_logic;

      -- VGA output
      vga_hs_o     : out   std_logic;
      vga_vs_o     : out   std_logic;
      vga_col_o    : out   std_logic_vector(11 downto 0)    -- 4 bits for each colour RGB.
   );
end x16;

architecture structural of x16 is

   constant C_ROM_INIT_FILE           : string := "main/rom.txt";     -- ROM contents.
   constant C_YM2151_CLOCK_HZ         : integer := 3579545;

   -- Clock and reset
   signal eth_clk_s                   : std_logic;
   signal vga_clk_s                   : std_logic;
   signal pwm_clk_s                   : std_logic;
   signal main_clk_s                  : std_logic;
   signal main_clkn_s                 : std_logic;                    -- Inverted clock
   signal main_rst_s                  : std_logic;
   signal ym2151_clk_s                : std_logic;
   signal ym2151_rst_s                : std_logic;

   signal main_addr_s                 : std_logic_vector(15 downto 0);
   signal main_wr_en_s                : std_logic;
   signal main_wr_data_s              : std_logic_vector( 7 downto 0);
   signal main_rd_en_s                : std_logic;
   signal main_rd_data_s              : std_logic_vector( 7 downto 0);
   signal main_debug_s                : std_logic_vector(15 downto 0);
   signal main_vera_debug_s           : std_logic_vector(16 downto 0);
   signal main_vera_irq_s             : std_logic;
   signal main_ym2151_cfg_valid_s     : std_logic;
   signal main_ym2151_cfg_ready_s     : std_logic;
   signal main_ym2151_cfg_addr_s      : std_logic_vector( 7 downto 0);
   signal main_ym2151_cfg_data_s      : std_logic_vector( 7 downto 0);
   signal main_ym2151_cfg_addr_data_s : std_logic_vector(15 downto 0);

   signal ym2151_cfg_valid_s          : std_logic;
   signal ym2151_cfg_ready_s          : std_logic;
   signal ym2151_cfg_addr_s           : std_logic_vector( 7 downto 0);
   signal ym2151_cfg_data_s           : std_logic_vector( 7 downto 0);
   signal ym2151_cfg_addr_data_s      : std_logic_vector(15 downto 0);
   signal ym2151_aud_data_s           : std_logic_vector(11 downto 0);

   signal ps2_data_in_s               : std_logic;
   signal ps2_data_out_s              : std_logic;
   signal ps2_dataen_s                : std_logic;
   signal ps2_clk_in_s                : std_logic;
   signal ps2_clk_out_s               : std_logic;
   signal ps2_clken_s                 : std_logic;

   signal spi_sclk_s                  : std_logic;
   signal spi_mosi_s                  : std_logic;
   signal spi_miso_s                  : std_logic;
   signal spi_cs_s                    : std_logic;

   signal pwm_aud_val_s               : std_logic_vector(11 downto 0);
   signal pwm_aud_pwm_s               : std_logic;

   -- Debug
   constant C_DEBUG_MODE                           : boolean := false; -- TRUE OR FALSE

   attribute mark_debug                            : boolean;
   attribute mark_debug of pwm_aud_val_s           : signal is C_DEBUG_MODE;
   attribute mark_debug of pwm_aud_pwm_s           : signal is C_DEBUG_MODE;

   attribute mark_debug of main_ym2151_cfg_valid_s : signal is C_DEBUG_MODE;
   attribute mark_debug of main_ym2151_cfg_ready_s : signal is C_DEBUG_MODE;
   attribute mark_debug of main_ym2151_cfg_addr_s  : signal is C_DEBUG_MODE;
   attribute mark_debug of main_ym2151_cfg_data_s  : signal is C_DEBUG_MODE;

   attribute mark_debug of ym2151_rst_s            : signal is C_DEBUG_MODE;
   attribute mark_debug of ym2151_cfg_valid_s      : signal is C_DEBUG_MODE;
   attribute mark_debug of ym2151_cfg_ready_s      : signal is C_DEBUG_MODE;
   attribute mark_debug of ym2151_cfg_addr_s       : signal is C_DEBUG_MODE;
   attribute mark_debug of ym2151_cfg_data_s       : signal is C_DEBUG_MODE;
   attribute mark_debug of ym2151_aud_data_s       : signal is C_DEBUG_MODE;

begin

   aud_sd_o <= '1';

   --------------------------------------------------------
   -- Generate AUD tristate buffers, simulating open-collector:
   -- Either drive low or tristate; never drive high.
   --------------------------------------------------------

   aud_pwm_o <= '0' when pwm_aud_pwm_s = '0' else 'Z';


   --------------------------------------------------------
   -- Generate SPI tristate buffers.
   --------------------------------------------------------

   -- The SD_RESET signal needs to be actively driven low by the FPGA to power
   -- the microSD card slot.
   sd_reset_o   <= '0';
   sd_dat_io(3) <= not spi_cs_s;    -- The CS signal is active low.
   sd_dat_io(2) <= 'Z';             -- Set to input
   sd_dat_io(1) <= 'Z';             -- Set to input
   sd_dat_io(0) <= 'Z';             -- Set to input
   spi_miso_s   <= sd_dat_io(0);
   sd_cmd_io    <= spi_mosi_s;
   sd_sck_o     <= spi_sclk_s;

   -- The SD Card is powered up in the SD mode. It will enter SPI mode if the
   -- CS signal is asserted (negative) during the reception of the reset
   -- command (CMD0). If the card recognizes that the SD mode is required it
   -- will not respond to the command and remain in the SD mode. If SPI mode is
   -- required, the card will switch to SPI and respond with the SPI mode R1
   -- response.


   --------------------------------------------------------
   -- Generate PS/2 tristate buffers, simulating open-collector:
   -- Either drive low or tristate; never drive high.
   --------------------------------------------------------

   ps2_data_in_s <= ps2_data_io;
   ps2_clk_in_s  <= ps2_clk_io;
   ps2_data_io   <= ps2_data_out_s when ps2_dataen_s = '1' and ps2_data_out_s = '0' else 'Z';
   ps2_clk_io    <= ps2_clk_out_s  when ps2_clken_s  = '1' and ps2_clk_out_s  = '0' else 'Z';


   --------------------------------------------------------
   -- Instantiate Clock and Reset
   --------------------------------------------------------

   i_clk_rst : entity work.clk_rst
      port map (
         sys_clk_i    => sys_clk_i,      -- 100 MHz
         sys_rstn_i   => sys_rstn_i,
         eth_clk_o    => eth_clk_s,      --  50 MHz
         vga_clk_o    => vga_clk_s,      --  25.2 MHz
         main_clk_o   => main_clk_s,     --   8.33 MHz
         main_rst_o   => main_rst_s,
         pwm_clk_o    => pwm_clk_s,      -- 100 MHz
         ym2151_clk_o => ym2151_clk_s,   --   3.579545 MHz
         ym2151_rst_o => ym2151_rst_s
      ); -- i_clk_rst

   main_clkn_s <= not main_clk_s;


   --------------------------------------------------------
   -- Instantiate VERA module
   --------------------------------------------------------

   i_vera : entity work.vera
      port map (
         cpu_clk_i     => main_clkn_s,
         cpu_rst_i     => main_rst_s,
         cpu_addr_i    => main_addr_s(2 downto 0),
         cpu_wr_en_i   => main_wr_en_s,
         cpu_wr_data_i => main_wr_data_s,
         cpu_rd_en_i   => main_rd_en_s,
         cpu_rd_data_o => main_rd_data_s,
         cpu_debug_o   => main_vera_debug_s,
         cpu_irq_o     => main_vera_irq_s,
         --
         spi_sclk_o    => spi_sclk_s,
         spi_mosi_o    => spi_mosi_s,
         spi_miso_i    => spi_miso_s,
         spi_cs_o      => spi_cs_s,
         --
         vga_clk_i     => vga_clk_s,
         vga_hs_o      => vga_hs_o,
         vga_vs_o      => vga_vs_o,
         vga_col_o     => vga_col_o
      ); -- i_vera


   --------------------------------------------------------
   -- Instantiate main computer (CPU, RAM, ROM, VIA, etc.)
   --------------------------------------------------------

   i_main : entity work.main
      generic map (
         G_ROM_INIT_FILE => C_ROM_INIT_FILE
      )
      port map (
         clk_i            => main_clk_s,
         rst_i            => main_rst_s,
         nmi_i            => '0',
         irq_i            => main_vera_irq_s,
         vera_addr_o      => main_addr_s(2 downto 0),
         vera_wr_en_o     => main_wr_en_s,
         vera_wr_data_o   => main_wr_data_s,
         vera_rd_en_o     => main_rd_en_s,
         vera_rd_data_i   => main_rd_data_s,
         vera_debug_o     => main_debug_s,
         --
         ym2151_valid_o   => main_ym2151_cfg_valid_s,
         ym2151_ready_i   => main_ym2151_cfg_ready_s,
         ym2151_addr_o    => main_ym2151_cfg_addr_s,
         ym2151_data_o    => main_ym2151_cfg_data_s,
         --
         ps2_data_in_i    => ps2_data_in_s,
         ps2_data_out_o   => ps2_data_out_s,
         ps2_dataen_o     => ps2_dataen_s,
         ps2_clk_in_i     => ps2_clk_in_s,
         ps2_clk_out_o    => ps2_clk_out_s,
         ps2_clken_o      => ps2_clken_s,
         --
         eth_clk_i        => eth_clk_s,
         eth_txd_o        => eth_txd_o,
         eth_txen_o       => eth_txen_o,
         eth_rxd_i        => eth_rxd_i,
         eth_rxerr_i      => eth_rxerr_i,
         eth_crsdv_i      => eth_crsdv_i,
         eth_intn_i       => eth_intn_i,
         eth_mdio_io      => eth_mdio_io,
         eth_mdc_o        => eth_mdc_o,
         eth_rstn_o       => eth_rstn_o,
         eth_refclk_o     => eth_refclk_o
      ); -- i_main
      

   --------------------------------------------------------
   -- Instantiate CDC from Main to YM2151
   --------------------------------------------------------

   main_ym2151_cfg_addr_data_s(7 downto 0)  <= main_ym2151_cfg_data_s;
   main_ym2151_cfg_addr_data_s(15 downto 8) <= main_ym2151_cfg_addr_s;

   i_cdc_vector : entity work.cdc_vector
      generic map (
         G_SIZE => 16
      )
      port map (
         src_clk_i   => main_clk_s,
         src_valid_i => main_ym2151_cfg_valid_s,
         src_ready_o => main_ym2151_cfg_ready_s,
         src_data_i  => main_ym2151_cfg_addr_data_s,
         dst_clk_i   => ym2151_clk_s,
         dst_valid_o => ym2151_cfg_valid_s,
         dst_ready_i => ym2151_cfg_ready_s,
         dst_data_o  => ym2151_cfg_addr_data_s
      ); -- i_cdc_vector

   ym2151_cfg_data_s <= ym2151_cfg_addr_data_s(7 downto 0);
   ym2151_cfg_addr_s <= ym2151_cfg_addr_data_s(15 downto 8);


   --------------------------------------------------------
   -- Instantiate YM2151 module
   --------------------------------------------------------

   i_ym2151 : entity work.ym2151
      generic map (
         G_CLOCK_HZ => C_YM2151_CLOCK_HZ
      )
      port map (
         clk_i       => ym2151_clk_s,
         rst_i       => ym2151_rst_s,
         cfg_valid_i => ym2151_cfg_valid_s,
         cfg_ready_o => ym2151_cfg_ready_s,
         cfg_addr_i  => ym2151_cfg_addr_s,
         cfg_data_i  => ym2151_cfg_data_s,
         aud_valid_o => open,
         aud_data_o  => ym2151_aud_data_s
      ); -- i_ym2151


   --------------------------------------------------------
   -- Instantiate CDC from YM2151 to PWM
   --------------------------------------------------------

   i_cdc : entity work.cdc
      generic map (
         G_SIZE => 12
      )
      port map (
         src_clk_i => ym2151_clk_s,
         src_dat_i => ym2151_aud_data_s,
         dst_clk_i => pwm_clk_s,
         dst_dat_o => pwm_aud_val_s
      ); -- i_cdc


   --------------------------------------------------------
   -- Instantiate PWM module
   --------------------------------------------------------

   i_pwm : entity work.pwm
      port map (
         clk_i     => pwm_clk_s,
         density_i => pwm_aud_val_s,
         pwm_o     => pwm_aud_pwm_s
      ); -- i_pwm


   --------------------------------
   -- Connect debug output signals 
   --------------------------------

   async_led_o <= main_vera_debug_s(15 downto 0);

end architecture structural;

