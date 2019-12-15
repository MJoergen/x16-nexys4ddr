library ieee;
use ieee.std_logic_1164.all;

-- This is the top level module of the VGA module in the VERA.
-- It generates a display with 640x480 pixels at 60 Hz refresh rate.

entity vga is
   port (
      clk_i          : in  std_logic;                       -- 25.2 MHz
      -- From Layer settings
      mapbase_i      : in  std_logic_vector(17 downto 0);
      tilebase_i     : in  std_logic_vector(17 downto 0);
      mode_i         : in  std_logic_vector( 2 downto 0);
      hscale_i       : in  std_logic_vector( 7 downto 0);
      vscale_i       : in  std_logic_vector( 7 downto 0);
      -- video RAM
      vram_addr_o    : out std_logic_vector(16 downto 0);
      vram_rd_en_o   : out std_logic;
      vram_rd_data_i : in  std_logic_vector( 7 downto 0);
      -- palette RAM
      pal_addr_o     : out std_logic_vector( 7 downto 0);
      pal_rd_en_o    : out std_logic;
      pal_rd_data_i  : in  std_logic_vector(11 downto 0);
      -- interrupt
      vsync_irq_o    : out std_logic;
      -- VGA output
      hs_o           : out std_logic;
      vs_o           : out std_logic;
      col_o          : out std_logic_vector(11 downto 0)    -- 4 bits for each colour RGB.
   );
end vga;

architecture structural of vga is

   signal pix_x_s            : std_logic_vector( 9 downto 0);
   signal pix_y_s            : std_logic_vector( 9 downto 0);
   signal pix_x_scaled_s     : std_logic_vector( 9 downto 0);
   signal pix_y_scaled_s     : std_logic_vector( 9 downto 0);

   signal col_s              : std_logic_vector(11 downto 0);
   signal delay_s            : std_logic_vector( 9 downto 0);

begin

   ------------------------------
   -- Instantiate pixel counters
   ------------------------------

   i_pix : entity work.pix
      generic map (
         G_PIX_X_COUNT => 800,
         G_PIX_Y_COUNT => 525
      )
      port map (
         clk_i   => clk_i,
         pix_x_o => pix_x_s,
         pix_y_o => pix_y_s
      ); -- i_pix

   pix_x_scaled_s <= "00" & pix_x_s(9 downto 2) when hscale_i = X"20" else
                      "0" & pix_x_s(9 downto 1) when hscale_i = X"40" else
                            pix_x_s;
   pix_y_scaled_s <= "00" & pix_y_s(9 downto 2) when vscale_i = X"20" else
                      "0" & pix_y_s(9 downto 1) when vscale_i = X"40" else
                            pix_y_s;

   ------------------------------
   -- Instantiate layer renderer
   ------------------------------

   i_layer : entity work.layer
      port map (
         clk_i          => clk_i,
         mapbase_i      => mapbase_i(16 downto 0),
         tilebase_i     => tilebase_i(16 downto 0),
         mode_i         => mode_i,
         pix_x_i        => pix_x_scaled_s,
         pix_y_i        => pix_y_scaled_s,
         vram_addr_o    => vram_addr_o,
         vram_rd_en_o   => vram_rd_en_o,
         vram_rd_data_i => vram_rd_data_i,
         pal_addr_o     => pal_addr_o,
         pal_rd_en_o    => pal_rd_en_o,
         pal_rd_data_i  => pal_rd_data_i,
         col_o          => col_s,
         delay_o        => delay_s
      ); -- i_layer


   ------------------------------
   -- Instantiate VGA signalling
   ------------------------------

   i_sync : entity work.sync
      port map (
         clk_i       => clk_i,
         pix_x_i     => pix_x_s,
         pix_y_i     => pix_y_s,
         col_i       => col_s,
         delay_i     => delay_s,
         vsync_irq_o => vsync_irq_o,
         vga_hs_o    => hs_o,
         vga_vs_o    => vs_o,
         vga_col_o   => col_o
      ); -- i_sync


end architecture structural;

