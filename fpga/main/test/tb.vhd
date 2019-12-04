library ieee;
use ieee.std_logic_1164.all;

entity tb is
end entity tb;

architecture simulation of tb is

   signal cpu_clk_s       : std_logic;
   signal cpu_clkn_s      : std_logic;
   signal cpu_rst_s       : std_logic;
   signal nmi_s           : std_logic;
   signal vera_irq_s      : std_logic;
   signal vera_addr_s     : std_logic_vector(2 downto 0);
   signal vera_wr_en_s    : std_logic;
   signal vera_wr_data_s  : std_logic_vector(7 downto 0);
   signal vera_rd_en_s    : std_logic;
   signal vera_rd_data_s  : std_logic_vector(7 downto 0);
   signal vera_debug_s    : std_logic_vector(15 downto 0);

   -- video RAM
   signal vram_addr_s     : std_logic_vector(16 downto 0);
   signal vram_wr_en_s    : std_logic;
   signal vram_wr_data_s  : std_logic_vector( 7 downto 0);
   signal vram_rd_en_s    : std_logic;
   signal vram_rd_data_s  : std_logic_vector( 7 downto 0);

   signal vsync_irq_s     : std_logic;

   signal kbd_data_s      : std_logic_vector(10 downto 0);
   signal kbd_valid_s     : std_logic;
   signal kbd_ready_s     : std_logic;

   signal ps2_data_in_s   : std_logic;
   signal ps2_data_out_s  : std_logic;
   signal ps2_dataen_s    : std_logic;
   signal ps2_clk_in_s    : std_logic;
   signal ps2_clk_out_s   : std_logic;
   signal ps2_clken_s     : std_logic;

   signal spi_sclk_s      : std_logic;
   signal spi_mosi_s      : std_logic;
   signal spi_miso_s      : std_logic;
   signal spi_cs_s        : std_logic;

   signal spi_valid_out_s : std_logic;
   signal spi_valid_in_s  : std_logic;
   signal spi_data_out_s  : std_logic_vector(7 downto 0);
   signal spi_data_in_s   : std_logic_vector(7 downto 0);

   signal eth_clk_s       : std_logic;
   signal eth_txd_s       : std_logic_vector(1 downto 0);
   signal eth_txen_s      : std_logic;
   signal eth_rxd_s       : std_logic_vector(1 downto 0);
   signal eth_crsdv_s     : std_logic;
   signal eth_rstn_s      : std_logic;
   signal eth_refclk_s    : std_logic;

begin

   --------------------
   -- Clock generation
   --------------------

   p_cpu_clk : process
   begin
      cpu_clk_s <= '1', '0' after 60 ns;
      wait for 120 ns; -- 8.3 MHz
   end process p_cpu_clk;

   cpu_rst_s <= '1', '0' after 600 ns;
   nmi_s <= '0';

   cpu_clkn_s <= not cpu_clk_s;

   p_eth_clk : process
   begin
      eth_clk_s <= '1', '0' after 10 ns;
      wait for 20 ns; -- 50 MHz
   end process p_eth_clk;


   --------------------------
   -- Instantiate MAIN block
   --------------------------

   i_main : entity work.main
      generic map (
         G_ROM_INIT_FILE => "rom.txt"
      )
      port map (
         clk_i          => cpu_clk_s,
         rst_i          => cpu_rst_s,
         nmi_i          => nmi_s,
         irq_i          => vera_irq_s,
         --
         ps2_data_in_i  => ps2_data_in_s,
         ps2_data_out_o => ps2_data_out_s,
         ps2_dataen_o   => ps2_dataen_s,
         ps2_clk_in_i   => ps2_clk_in_s,
         ps2_clk_out_o  => ps2_clk_out_s,
         ps2_clken_o    => ps2_clken_s,
         --
         eth_clk_i      => eth_clk_s,
         eth_txd_o      => eth_txd_s,
         eth_txen_o     => eth_txen_s,
         eth_rxd_i      => eth_rxd_s,
         eth_rxerr_i    => '0',
         eth_crsdv_i    => eth_crsdv_s,
         eth_intn_i     => '0',
         eth_mdio_io    => open,
         eth_mdc_o      => open,
         eth_rstn_o     => eth_rstn_s,
         eth_refclk_o   => eth_refclk_s,
         --
         vera_addr_o    => vera_addr_s,
         vera_wr_en_o   => vera_wr_en_s,
         vera_wr_data_o => vera_wr_data_s,
         vera_rd_en_o   => vera_rd_en_s,
         vera_rd_data_i => vera_rd_data_s,
         vera_debug_o   => vera_debug_s
      ); -- i_main


   ------------------------------
   -- Instantiate VERA interface
   ------------------------------

   i_vera : entity work.cpu
      port map (
         clk_i          => cpu_clkn_s,
         rst_i          => cpu_rst_s,
         addr_i         => vera_addr_s,
         wr_en_i        => vera_wr_en_s,
         wr_data_i      => vera_wr_data_s,
         rd_en_i        => vera_rd_en_s,
         rd_data_o      => vera_rd_data_s,
         irq_o          => vera_irq_s,
         vram_addr_o    => vram_addr_s,
         vram_wr_en_o   => vram_wr_en_s,
         vram_wr_data_o => vram_wr_data_s,
         vram_rd_en_o   => vram_rd_en_s,
         vram_rd_data_i => vram_rd_data_s,
         spi_sclk_o     => spi_sclk_s,
         spi_mosi_o     => spi_mosi_s,
         spi_miso_i     => spi_miso_s,
         spi_cs_o       => spi_cs_s,
         pal_addr_o     => open,
         pal_wr_en_o    => open,
         pal_wr_data_o  => open,
         pal_rd_en_o    => open,
         pal_rd_data_i  => (others => '0'),
         map_base_o     => open,
         tile_base_o    => open,
         vsync_irq_i    => vsync_irq_s
      ); -- i_vera

   p_vsync_irq : process
   begin
      vsync_irq_s <= '0';
      wait for 600*12 ns;
      vsync_irq_s <= '1';
      wait for 1*12 ns;
      vsync_irq_s <= '0';
      wait;
   end process p_vsync_irq;


   --------------------------------
   -- Instantiate 128 kB Video RAM
   --------------------------------

   i_vram : entity work.vram
      port map (
         -- CPU access
         cpu_clk_i     => cpu_clkn_s,
         cpu_addr_i    => vram_addr_s,
         cpu_wr_en_i   => vram_wr_en_s,
         cpu_wr_data_i => vram_wr_data_s,
         cpu_rd_en_i   => vram_rd_en_s,
         cpu_rd_data_o => vram_rd_data_s,

         -- VGA access
         vga_clk_i     => '0',
         vga_rd_addr_i => (others => '0'),
         vga_rd_en_i   => '0',
         vga_rd_data_o => open
      ); -- i_vram


   ---------------------------------
   -- Instantiate keyboard emulator
   ---------------------------------

   i_ps2_writer : entity work.ps2_writer
      port map (
         clk_i        => cpu_clk_s,
         rst_i        => cpu_rst_s,
         data_i       => kbd_data_s,
         valid_i      => kbd_valid_s,
         ready_o      => kbd_ready_s,
         ps2_clk_o    => ps2_clk_in_s,
         ps2_clk_i    => ps2_clk_out_s,
         ps2_clken_i  => ps2_clken_s,
         ps2_data_o   => ps2_data_in_s,
         ps2_data_i   => ps2_data_out_s,
         ps2_dataen_i => ps2_dataen_s
      ); -- i_ps2_writer

   p_kbd : process
   begin
      kbd_valid_s <= '0';
      wait for 100*12 ns;
      wait until cpu_clk_s = '1';

      kbd_data_s  <= "10110011010";
      kbd_valid_s <= '1';
      wait until cpu_clk_s = '1';
      while kbd_ready_s = '0' loop
         wait until cpu_clk_s = '1';
      end loop;
      kbd_valid_s <= '0';
      wait for 120 us;
      wait until cpu_clk_s = '1';
      wait;
   end process p_kbd;


   ---------------------------------
   -- Instantiate SPI emulator
   ---------------------------------

   i_spi_slave : entity work.spi_slave
      port map (
         clk_i      => cpu_clk_s,
         rst_i      => cpu_rst_s,
         valid_o    => spi_valid_out_s,
         valid_i    => spi_valid_in_s,
         data_o     => spi_data_out_s,
         data_i     => spi_data_in_s,
         spi_sclk_i => spi_sclk_s,
         spi_mosi_i => spi_mosi_s,
         spi_miso_o => spi_miso_s
      ); -- i_spi_slave

   p_spi : process
   begin
      spi_valid_in_s <= '0';
      wait for 100*12 ns;
      wait until cpu_clk_s = '1';

      spi_data_in_s <= X"5A";
      spi_valid_in_s <= '1';
      wait until cpu_clk_s = '1';
      spi_valid_in_s <= '0';
      wait until cpu_clk_s = '1';

      wait until spi_valid_out_s = '1';
      wait until cpu_clk_s = '1';
      assert spi_data_out_s = X"46";
      wait;
   end process p_spi;

end architecture simulation;

