library ieee;
use ieee.std_logic_1164.all;

-- This is the top level module of the VERA.
--
-- This block accepts CPU accesses synchronous to the CPU block
-- and generates a VGA output synchronous to the VGA clock.
-- This block therefore operates at two separate clock frequencies.
-- The actual clock domain crossings take place in the following
-- modules:
-- * vram (for video RAM)
-- * palette (for palette RAM)
-- * cdc (for configuration settings)

entity vera is
   port (
      cpu_clk_i     : in  std_logic;                        -- 8.33 MHz
      cpu_rst_i     : in  std_logic;
      cpu_addr_i    : in  std_logic_vector( 4 downto 0);
      cpu_wr_en_i   : in  std_logic;
      cpu_wr_data_i : in  std_logic_vector( 7 downto 0);
      cpu_rd_en_i   : in  std_logic;
      cpu_rd_data_o : out std_logic_vector( 7 downto 0);
      cpu_debug_o   : out std_logic_vector(16 downto 0);
      cpu_irq_o     : out std_logic;

      spi_sclk_o    : out std_logic;       -- sd_sck_io
      spi_mosi_o    : out std_logic;       -- sd_cmd_io
      spi_miso_i    : in  std_logic;       -- sd_dat_io(0)
      spi_cs_o      : out std_logic;       -- sd_dat_io(3)

      vga_clk_i     : in  std_logic;                        -- 25.2 MHz
      vga_hs_o      : out std_logic;
      vga_vs_o      : out std_logic;
      vga_col_o     : out std_logic_vector(11 downto 0)     -- 4 bits for each colour RGB.
   );
end vera;

architecture structural of vera is

   ---------------------------------------------
   -- These signals are in the CPU clock domain
   ---------------------------------------------

   -- video RAM
   signal cpu_vram_addr_s    : std_logic_vector(16 downto 0);
   signal cpu_vram_wr_en_s   : std_logic;
   signal cpu_vram_wr_data_s : std_logic_vector( 7 downto 0);
   signal cpu_vram_rd_data_s : std_logic_vector( 7 downto 0);
   -- palette RAM
   signal cpu_pal_addr_s     : std_logic_vector( 8 downto 0);
   signal cpu_pal_wr_en_s    : std_logic;
   signal cpu_pal_wr_data_s  : std_logic_vector( 7 downto 0);
   signal cpu_pal_rd_data_s  : std_logic_vector( 7 downto 0);
   -- configuration registers
   signal cpu_map_base_s     : std_logic_vector(16 downto 0);
   signal cpu_tile_base_s    : std_logic_vector(16 downto 0);
   signal cpu_mode_s         : std_logic_vector( 2 downto 0);
   signal cpu_hscale_s       : std_logic_vector( 7 downto 0);
   signal cpu_vscale_s       : std_logic_vector( 7 downto 0);
   -- interrupt
   signal cpu_vsync_irq_s    : std_logic;


   ---------------------------------------------
   -- These signals are in the VGA clock domain
   ---------------------------------------------

   -- video RAM
   signal vga_vram_addr_s    : std_logic_vector(16 downto 0);
   signal vga_vram_rd_data_s : std_logic_vector( 7 downto 0);
   -- palette RAM
   signal vga_pal_addr_s     : std_logic_vector( 7 downto 0);
   signal vga_pal_rd_data_s  : std_logic_vector(11 downto 0);
   -- configuration registers
   signal vga_map_base_r     : std_logic_vector(16 downto 0);
   signal vga_tile_base_r    : std_logic_vector(16 downto 0);
   signal vga_mode_r         : std_logic_vector( 2 downto 0);
   signal vga_hscale_r       : std_logic_vector( 7 downto 0);
   signal vga_vscale_r       : std_logic_vector( 7 downto 0);
   -- interrupt
   signal vga_vsync_irq_s    : std_logic;

begin

   ------------------------
   -- Interface to the CPU
   ------------------------

   i_cpu : entity work.cpu
      port map (
         clk_i          => cpu_clk_i,
         rst_i          => cpu_rst_i,
         addr_i         => cpu_addr_i,
         wr_en_i        => cpu_wr_en_i,
         wr_data_i      => cpu_wr_data_i,
         rd_en_i        => cpu_rd_en_i,
         rd_data_o      => cpu_rd_data_o,
         irq_o          => cpu_irq_o,
         vram_addr_o    => cpu_vram_addr_s,
         vram_wr_en_o   => cpu_vram_wr_en_s,
         vram_wr_data_o => cpu_vram_wr_data_s,
         vram_rd_data_i => cpu_vram_rd_data_s,
         pal_addr_o     => cpu_pal_addr_s,
         pal_wr_en_o    => cpu_pal_wr_en_s,
         pal_wr_data_o  => cpu_pal_wr_data_s,
         pal_rd_data_i  => cpu_pal_rd_data_s,
         map_base_o     => cpu_map_base_s,
         tile_base_o    => cpu_tile_base_s,
         mode_o         => cpu_mode_s,
         hscale_o       => cpu_hscale_s,
         vscale_o       => cpu_vscale_s,
         vsync_irq_i    => cpu_vsync_irq_s,
         -- SPI
         spi_sclk_o     => spi_sclk_o,
         spi_mosi_o     => spi_mosi_o,
         spi_miso_i     => spi_miso_i,
         spi_cs_o       => spi_cs_o
      ); -- i_cpu


   ------------------------------------------------------
   -- Debug output. Last address written to in Video RAM
   ------------------------------------------------------

   p_debug : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         if cpu_vram_wr_en_s = '1' then
            cpu_debug_o <= cpu_vram_addr_s;
         end if;
      end if;
   end process p_debug;


   --------------------------------
   -- Instantiate 128 kB Video RAM
   --------------------------------

   i_vram : entity work.vram
      port map (
         -- CPU access
         cpu_clk_i     => cpu_clk_i,
         cpu_addr_i    => cpu_vram_addr_s,
         cpu_wr_en_i   => cpu_vram_wr_en_s,
         cpu_wr_data_i => cpu_vram_wr_data_s,
         cpu_rd_data_o => cpu_vram_rd_data_s,

         -- VGA access
         vga_clk_i     => vga_clk_i,
         vga_rd_addr_i => vga_vram_addr_s,
         vga_rd_data_o => vga_vram_rd_data_s
      ); -- i_vram


   ---------------------------
   -- Instantiate palette RAM
   ---------------------------

   i_palette : entity work.palette
      port map (
         -- Read and writes from CPU
         cpu_clk_i     => cpu_clk_i,
         cpu_rst_i     => cpu_rst_i,
         cpu_addr_i    => cpu_pal_addr_s,
         cpu_wr_en_i   => cpu_pal_wr_en_s,
         cpu_wr_data_i => cpu_pal_wr_data_s,
         cpu_rd_data_o => cpu_pal_rd_data_s,

         -- Reads from the VGA block
         vga_clk_i     => vga_clk_i,
         vga_rd_addr_i => vga_pal_addr_s,
         vga_rd_data_o => vga_pal_rd_data_s
      ); -- i_palette


   --------------------------
   -- Clock domain crossing
   --------------------------

   i_cdc : entity work.cdc
      generic map (
         G_SIZE => 53
      )
      port map (
         src_clk_i               => cpu_clk_i,
         src_dat_i(16 downto  0) => cpu_map_base_s,
         src_dat_i(33 downto 17) => cpu_tile_base_s,
         src_dat_i(36 downto 34) => cpu_mode_s,
         src_dat_i(44 downto 37) => cpu_hscale_s,
         src_dat_i(52 downto 45) => cpu_vscale_s,
         dst_clk_i               => vga_clk_i,
         dst_dat_o(16 downto  0) => vga_map_base_r,
         dst_dat_o(33 downto 17) => vga_tile_base_r,
         dst_dat_o(36 downto 34) => vga_mode_r,
         dst_dat_o(44 downto 37) => vga_hscale_r,
         dst_dat_o(52 downto 45) => vga_vscale_r
      ); -- i_cdc


   -----------------------
   -- Generate VGA output
   -----------------------

   i_vga : entity work.vga
      port map (
         clk_i          => vga_clk_i,
         mapbase_i      => vga_map_base_r,
         tilebase_i     => vga_tile_base_r,
         mode_i         => vga_mode_r,
         hscale_i       => vga_hscale_r,
         vscale_i       => vga_vscale_r,
         vram_addr_o    => vga_vram_addr_s,
         vram_rd_data_i => vga_vram_rd_data_s,
         pal_addr_o     => vga_pal_addr_s,
         pal_rd_data_i  => vga_pal_rd_data_s,
         vsync_irq_o    => vga_vsync_irq_s,
         hs_o           => vga_hs_o,
         vs_o           => vga_vs_o,
         col_o          => vga_col_o
      ); -- i_vga


   --------------------------
   -- Clock domain crossing
   --------------------------

   i_pulse_conv : entity work.pulse_conv
      port map (
         src_clk_i   => vga_clk_i,
         src_pulse_i => vga_vsync_irq_s,
         dst_clk_i   => cpu_clk_i,
         dst_pulse_o => cpu_vsync_irq_s
      ); -- i_pulse_conv

end architecture structural;

