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
      addr_i         : in  std_logic_vector( 2 downto 0);
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
      -- configruation settings
      map_base_o     : out std_logic_vector(17 downto 0);
      tile_base_o    : out std_logic_vector(17 downto 0);
      mode_o         : out std_logic_vector( 2 downto 0);
      hscale_o       : out std_logic_vector( 7 downto 0);
      vscale_o       : out std_logic_vector( 7 downto 0);
      -- interrupt
      vsync_irq_i    : in  std_logic
   );
end cpu;

architecture structural of cpu is

   -- CPU accesses translated to the internal memory map.
   signal internal_addr_s    : std_logic_vector(19 downto 0);
   signal internal_wr_en_s   : std_logic;
   signal internal_wr_data_s : std_logic_vector( 7 downto 0);
   signal internal_rd_en_s   : std_logic;
   signal internal_rd_data_s : std_logic_vector( 7 downto 0);

   signal spi_addr_s         : std_logic_vector( 0 downto 0);
   signal spi_wr_en_s        : std_logic;
   signal spi_wr_data_s      : std_logic_vector( 7 downto 0);
   signal spi_rd_en_s        : std_logic;
   signal spi_rd_data_s      : std_logic_vector( 7 downto 0);

   -- Memory map
   signal vram_cs_s          : std_logic;
   signal pal_cs_s           : std_logic;
   signal spi_cs_s           : std_logic;

   -- Read data
   signal config_rd_data_s   : std_logic_vector( 7 downto 0);

begin

   --------------------------------------------------
   -- Translate from external to internal memory map
   --------------------------------------------------

   i_mmu : entity work.mmu
      port map (
         clk_i          => clk_i,
         -- External memory map
         cpu_addr_i     => addr_i,
         cpu_wr_en_i    => wr_en_i,
         cpu_wr_data_i  => wr_data_i,
         cpu_rd_en_i    => rd_en_i,
         cpu_rd_data_o  => rd_data_o,
         cpu_irq_o      => irq_o,
         -- Internal memory map
         vera_addr_o    => internal_addr_s,
         vera_wr_en_o   => internal_wr_en_s,
         vera_wr_data_o => internal_wr_data_s,
         vera_rd_en_o   => internal_rd_en_s,
         vera_rd_data_i => internal_rd_data_s,
         -- Interrupt
         vsync_irq_i    => vsync_irq_i
      ); -- i_cpu_interface


   -------------------
   -- Instantiate SPI
   -------------------

   i_spi : entity work.spi
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         addr_i     => spi_addr_s,
         wr_en_i    => spi_wr_en_s,
         wr_data_i  => spi_wr_data_s,
         rd_en_i    => spi_rd_en_s,
         rd_data_o  => spi_rd_data_s,
         spi_sclk_o => spi_sclk_o,
         spi_mosi_o => spi_mosi_o,
         spi_miso_i => spi_miso_i,
         spi_cs_o   => spi_cs_o
      ); -- i_spi


   --------------------------
   -- Configuration settings
   --------------------------

   i_config : entity work.config
      port map (
         clk_i       => clk_i,
         addr_i      => internal_addr_s,
         wr_en_i     => internal_wr_en_s,
         wr_data_i   => internal_wr_data_s,
         rd_en_i     => internal_rd_en_s,
         rd_data_o   => config_rd_data_s,
         map_base_o  => map_base_o,
         tile_base_o => tile_base_o,
         hscale_o    => hscale_o,
         vscale_o    => vscale_o,
         mode_o      => mode_o
      ); -- i_config


   -- Access Video RAM
   vram_addr_o    <= internal_addr_s(16 downto 0);
   vram_cs_s      <= '1' when internal_addr_s(19 downto 17) = "000" else '0';
   vram_wr_en_o   <= vram_cs_s and internal_wr_en_s;
   vram_wr_data_o <= internal_wr_data_s;

   -- Access palette RAM
   pal_addr_o    <= internal_addr_s(8 downto 0);
   pal_cs_s      <= '1' when internal_addr_s(19 downto 12) = X"F1" else '0';
   pal_wr_en_o   <= pal_cs_s and internal_wr_en_s;
   pal_wr_data_o <= internal_wr_data_s;

   -- Access SPI
   spi_addr_s    <= internal_addr_s(0 downto 0);
   spi_cs_s      <= '1' when internal_addr_s(19 downto 12) = X"F7" else '0';
   spi_wr_en_s   <= spi_cs_s and internal_wr_en_s;
   spi_wr_data_s <= internal_wr_data_s;
   spi_rd_en_s   <= spi_cs_s and internal_rd_en_s;
   

   -- Multiplex CPU read
   internal_rd_data_s <= vram_rd_data_i when vram_cs_s = '1' else
                         pal_rd_data_i  when pal_cs_s  = '1' else
                         spi_rd_data_s  when spi_cs_s  = '1' else
                         config_rd_data_s;

end architecture structural;

