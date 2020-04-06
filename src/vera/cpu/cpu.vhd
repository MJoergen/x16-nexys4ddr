library ieee;
use ieee.std_logic_1164.all;

-- This is the CPU interface within the VERA.
--
-- It multiplexes the requests to the Video RAM, the palette RAM, and the
-- configuration settings.

entity cpu is
   port (
      clk_i          : in  std_logic;
      rst_i          : in  std_logic;
      -- External CPU interface
      addr_i         : in  std_logic_vector( 4 downto 0);
      wr_en_i        : in  std_logic;
      wr_data_i      : in  std_logic_vector( 7 downto 0);
      rd_en_i        : in  std_logic;
      rd_data_o      : out std_logic_vector( 7 downto 0);
      irq_o          : out std_logic;
      -- SPI
      spi_sclk_o     : out std_logic;
      spi_mosi_o     : out std_logic;
      spi_miso_i     : in  std_logic;
      spi_cs_o       : out std_logic;

      -- Video RAM
      vram_addr_o    : out std_logic_vector(16 downto 0);
      vram_wr_en_o   : out std_logic;
      vram_wr_data_o : out std_logic_vector( 7 downto 0);
      vram_rd_data_i : in  std_logic_vector( 7 downto 0);
      -- palette RAM
      pal_addr_o     : out std_logic_vector( 8 downto 0);
      pal_wr_en_o    : out std_logic;
      pal_wr_data_o  : out std_logic_vector( 7 downto 0);
      pal_rd_data_i  : in  std_logic_vector( 7 downto 0);
      -- configuration settings
      map_base_o     : out std_logic_vector(16 downto 0);
      tile_base_o    : out std_logic_vector(16 downto 0);
      mode_o         : out std_logic_vector( 2 downto 0);
      hscale_o       : out std_logic_vector( 7 downto 0);
      vscale_o       : out std_logic_vector( 7 downto 0);
      -- interrupt
      vsync_irq_i    : in  std_logic
   );
end cpu;

architecture structural of cpu is

   signal l1_mapbase_s  : std_logic_vector(7 downto 0);
   signal l1_tilebase_s : std_logic_vector(7 downto 0);

begin

   i_config : entity work.config
      port map (
         clk_i          => clk_i,
         rst_i          => rst_i,
         addr_i         => addr_i,
         wr_en_i        => wr_en_i,
         wr_data_i      => wr_data_i,
         rd_en_i        => rd_en_i,
         rd_data_o      => rd_data_o,
         irq_o          => irq_o,
         vram_addr_o    => vram_addr_o,
         vram_wr_en_o   => vram_wr_en_o,
         vram_wr_data_o => vram_wr_data_o,
         vram_rd_data_i => vram_rd_data_i,
         pal_addr_o     => pal_addr_o,
         pal_wr_en_o    => pal_wr_en_o,
         pal_wr_data_o  => pal_wr_data_o,
         pal_rd_data_i  => pal_rd_data_i,

         ctrl_o         => open,
         irq_line_o     => open,
         irq_i          => (3 downto 1 => '0', 0 => vsync_irq_i),
         dc_video_o     => open,
         dc_hscale_o    => hscale_o,
         dc_vscale_o    => vscale_o,
         dc_border_o    => open,
         dc_hstart_o    => open,
         dc_hstop_o     => open,
         dc_vstart_o    => open,
         dc_vstop_o     => open,
         l0_config_o    => open,
         l0_mapbase_o   => open,
         l0_tilebase_o  => open,
         l0_hscroll_o   => open,
         l0_vscroll_o   => open,
         l1_config_o    => open,
         l1_mapbase_o   => l1_mapbase_s,
         l1_tilebase_o  => l1_tilebase_s,
         l1_hscroll_o   => open,
         l1_vscroll_o   => open,
         audio_ctrl_o   => open,
         audio_rate_o   => open,
         audio_data_o   => open,
         spi_data_o     => open,
         spi_ctrl_o     => open
      ); -- i_config

   map_base_o  <= l1_mapbase_s & "000000000";
   tile_base_o <= l1_tilebase_s(7 downto 2) & "00000000000";
   mode_o      <= "000";

end architecture structural;

