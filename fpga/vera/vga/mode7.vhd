library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This block implements VERA mode 7 (bitmap mode with 8 bits per pixel).
--
-- In this mode the map data is not used, and the tile data is interpreted
-- as a number of rows of 640 bytes each. So the address is calculated
-- as 640*y + x.

-- Currently, it is hardcoded that:
-- * TILEW = 0, which means 320x240 pixels.
--
-- On input it has the free-running pixel counters, as well as the base
-- address for the TILE area.
-- On output it has colour of the corresponding pixel.
-- Because there are several pipeline stages in this block, the output must
-- also include the pixel counters delayed accordingly.
--
-- This block needs to read the Video RAM once for each pixel:
-- * To get the tile data for this character (using tilebase_i).
-- Additionally, it needs to read the colour from the palette RAM at every pixel.

entity mode7 is
   port (
      clk_i          : in  std_logic;

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

      -- From Layer settings 
      tilebase_i     : in  std_logic_vector(16 downto 0);

      -- Output colour
      col_o          : out std_logic_vector(11 downto 0);
      delay_o        : out std_logic_vector( 9 downto 0)     -- Length of pipeline
   );
end mode7;

architecture rtl of mode7 is

   -- Pipeline
   signal pal_rd_data_r   : std_logic_vector(11 downto 0);


   -- Debug
   constant DEBUG_MODE                    : boolean := false; -- TRUE OR FALSE

   attribute mark_debug                   : boolean;
   attribute mark_debug of pix_x_i        : signal is DEBUG_MODE;
   attribute mark_debug of pix_y_i        : signal is DEBUG_MODE;
   attribute mark_debug of pal_addr_o     : signal is DEBUG_MODE;
   attribute mark_debug of pal_rd_data_i  : signal is DEBUG_MODE;
   attribute mark_debug of vram_addr_o    : signal is DEBUG_MODE;
   attribute mark_debug of vram_rd_data_i : signal is DEBUG_MODE;
   attribute mark_debug of col_o          : signal is DEBUG_MODE;

begin

   ---------------------------------------
   -- Always read from Video RAM
   -- Address is base+y*640+x, calculated as
   -- base+y*128+y*512+x.
   ---------------------------------------

   p_vram : process (clk_i)
   begin
      if rising_edge(clk_i) then
         vram_addr_o  <= tilebase_i +
                         (pix_y_i & "0000000") +
                         (pix_y_i(7 downto 0) & "000000000") +
                         ("0000000" & pix_x_i);
         vram_rd_en_o <= '1';
      end if;
   end process p_vram;


   ---------------------------------------
   -- Always read from Palette RAM
   ---------------------------------------

   p_pal : process (clk_i)
   begin
      if rising_edge(clk_i) then
         pal_addr_o  <= vram_rd_data_i;
         pal_rd_en_o <= '1';
      end if;
   end process p_pal;


   --------------------
   -- Output registers
   --------------------

   p_output : process (clk_i)
   begin
      if rising_edge(clk_i) then
         pal_rd_data_r <= pal_rd_data_i;
         col_o         <= pal_rd_data_r;
         delay_o       <= "0000000110";
      end if;
   end process p_output;

end architecture rtl;

