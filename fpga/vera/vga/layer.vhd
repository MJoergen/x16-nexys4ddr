library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This block implements a VERA layer
-- It basically multiplexes between the different possible modes.

entity layer is
   port (
      clk_i          : in  std_logic;

      -- From Layer settings
      mapbase_i      : in  std_logic_vector(16 downto 0);
      tilebase_i     : in  std_logic_vector(16 downto 0);
      mode_i         : in  std_logic_vector( 2 downto 0);

      -- Input pixel counters
      pix_x_i        : in  std_logic_vector( 9 downto 0);
      pix_y_i        : in  std_logic_vector( 9 downto 0);

      -- Interface to Video RAM
      vram_addr_o    : out std_logic_vector(16 downto 0);
      vram_rd_en_o   : out std_logic;
      vram_rd_data_i : in  std_logic_vector( 7 downto 0);

      -- Interface to Palette RAM
      pal_addr_o     : out std_logic_vector( 7 downto 0);
      pal_rd_en_o    : out std_logic;
      pal_rd_data_i  : in  std_logic_vector(11 downto 0);

      -- Output colour
      col_o          : out std_logic_vector(11 downto 0);
      delay_o        : out std_logic_vector( 9 downto 0)     -- Length of pipeline
   );
end layer;

architecture rtl of layer is

   -- Signals from mode 0
   signal vram_addr_mode0_s   : std_logic_vector(16 downto 0);
   signal vram_rd_en_mode0_s  : std_logic;
   signal pal_addr_mode0_s    : std_logic_vector( 7 downto 0);
   signal pal_rd_en_mode0_s   : std_logic;
   signal pix_x_mode0_s       : std_logic_vector( 9 downto 0);
   signal pix_y_mode0_s       : std_logic_vector( 9 downto 0);
   signal col_mode0_s         : std_logic_vector(11 downto 0);
   signal delay_mode0_s       : std_logic_vector( 9 downto 0);

   signal vram_addr_mode7_s   : std_logic_vector(16 downto 0);
   signal vram_rd_en_mode7_s  : std_logic;
   signal pal_addr_mode7_s    : std_logic_vector( 7 downto 0);
   signal pal_rd_en_mode7_s   : std_logic;
   signal pix_x_mode7_s       : std_logic_vector( 9 downto 0);
   signal pix_y_mode7_s       : std_logic_vector( 9 downto 0);
   signal col_mode7_s         : std_logic_vector(11 downto 0);
   signal delay_mode7_s       : std_logic_vector( 9 downto 0);

begin

   ----------------------
   -- Instantiate mode 0
   ----------------------

   i_mode0 : entity work.mode0
      port map (
         clk_i          => clk_i,
         pix_x_i        => pix_x_i,
         pix_y_i        => pix_y_i,
         vram_addr_o    => vram_addr_mode0_s,
         vram_rd_en_o   => vram_rd_en_mode0_s,
         vram_rd_data_i => vram_rd_data_i,
         pal_addr_o     => pal_addr_mode0_s,
         pal_rd_en_o    => pal_rd_en_mode0_s,
         pal_rd_data_i  => pal_rd_data_i,
         mapbase_i      => mapbase_i,
         tilebase_i     => tilebase_i,
         col_o          => col_mode0_s,
         delay_o        => delay_mode0_s
      ); -- i_mode0


   ----------------------
   -- Instantiate mode 7
   ----------------------

   i_mode7 : entity work.mode7
      port map (
         clk_i          => clk_i,
         pix_x_i        => pix_x_i,
         pix_y_i        => pix_y_i,
         vram_addr_o    => vram_addr_mode7_s,
         vram_rd_en_o   => vram_rd_en_mode7_s,
         vram_rd_data_i => vram_rd_data_i,
         pal_addr_o     => pal_addr_mode7_s,
         pal_rd_en_o    => pal_rd_en_mode7_s,
         pal_rd_data_i  => pal_rd_data_i,
         tilebase_i     => tilebase_i,
         col_o          => col_mode7_s,
         delay_o        => delay_mode7_s
      ); -- i_mode7


   ----------------------------
   -- Multiplex output signals
   ----------------------------

   vram_addr_o  <= vram_addr_mode7_s  when mode_i = "111" else vram_addr_mode0_s;
   vram_rd_en_o <= vram_rd_en_mode7_s when mode_i = "111" else vram_rd_en_mode0_s;
   pal_addr_o   <= pal_addr_mode7_s   when mode_i = "111" else pal_addr_mode0_s;
   pal_rd_en_o  <= pal_rd_en_mode7_s  when mode_i = "111" else pal_rd_en_mode0_s;
   col_o        <= col_mode7_s        when mode_i = "111" else col_mode0_s;
   delay_o      <= delay_mode7_s      when mode_i = "111" else delay_mode0_s;

end architecture rtl;

