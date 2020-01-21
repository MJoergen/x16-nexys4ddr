library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This block is a dummy block that generates a number of writes from the CPU,
-- used for testing VERA mode 7.
--
-- Upon startup the KERNAL/BASIC performs the following sequence of writes to the VERA:
-- 1. 0x0F800 - 0x0FFFF : Tile data.
-- 2. 0xF3000 - 0xF3009 : Layer 2.  Values 01:06:00:00:00:3E:00:00:00:00
-- 3. 0xF0000 - 0xF0008 : Composer. Values 01:80:80:0E:00:80:00:E0:28
-- 4. 0x00000 - 0x03FFF : Clear screen. Values 20:61 repeated.
-- 5. 0x00000 - 0x008FF : Display welcome screen.
--
-- The default values of the composer settings are interpreted as follows:
-- * VGA output
-- * HSCALE = VSCALE = 0x80, which means 1 output pixel for every input pixel.
-- * HSTART = 0, HSTOP = 640
-- * VSTART = 0, VSTOP = 480
-- 
-- The default values of the layer settings are interpreted as follows:
-- * MODE = 0, which means 16 colour text mode
-- * MAPW = 2, which means 128 tiles wide
-- * MAPH = 1, which means 64 tiles high
-- * TILEW = TILEH = 0, which means each tile is 8x8
-- * MAPBASE = 0, which means the MAP area starts at 0x00000
-- * TILEBASE = 0x3E00, which means the TILE area starts at 0x0F800
-- * HSCROLL = VSCROLL = 0

entity cpu_dummy is
   port (
      clk_i     : in  std_logic;
      addr_o    : out std_logic_vector(15 downto 0);
      wr_en_o   : out std_logic;
      wr_data_o : out std_logic_vector( 7 downto 0);
      rd_en_o   : out std_logic;
      debug_o   : out std_logic_vector(15 downto 0);
      rd_data_i : in  std_logic_vector( 7 downto 0)
   );
end cpu_dummy;

architecture structural of cpu_dummy is

   signal exp_data_r : std_logic_vector(7 downto 0);

   -- This defines a type containing an array of bytes
   type command is record
      addr  : std_logic_vector(15 downto 0);
      data  : std_logic_vector( 7 downto 0);
      wr_en : std_logic;
   end record command;
   type command_vector is array (natural range <>) of command;

   constant commands : command_vector := (
      -- Configure layer 1
      (X"9F25", X"00", '1'), -- Select address port 0
      (X"9F20", X"00", '1'),
      (X"9F21", X"30", '1'),
      (X"9F22", X"1F", '1'), -- Set address to 0xF3000 and increment to 1.
      (X"9F23", X"E1", '1'), -- 0xF3000 L1_CTRL0
      (X"9F23", X"10", '1'), -- 0xF3001 L1_CTRL1
      (X"9F23", X"00", '1'), -- 0xF3002 L1_MAP_BASE_L
      (X"9F23", X"00", '1'), -- 0xF3003 L1_MAP_BASE_H
      (X"9F23", X"00", '1'), -- 0xF3004 L1_TILE_BASE_L
      (X"9F23", X"00", '1'), -- 0xF3005 L1_TILE_BASE_H
      (X"9F23", X"00", '1'), -- 0xF3006 L1_HSCROLL_L
      (X"9F23", X"00", '1'), -- 0xF3007 L1_HSCROLL_H
      (X"9F23", X"00", '1'), -- 0xF3008 L1_VSCROLL_L
      (X"9F23", X"00", '1'), -- 0xF3009 L1_VSCROLL_H

      -- Configure palette
      (X"9F20", X"00", '1'),
      (X"9F21", X"10", '1'),
      (X"9F22", X"1F", '1'), -- Set address to 0xF1000 and increment to 1.
      (X"9F23", X"00", '1'), -- GB(0)
      (X"9F23", X"00", '1'), -- R(0)
      (X"9F23", X"02", '1'), -- GB(1)
      (X"9F23", X"00", '1'), -- R(1)

      (X"9F20", X"F6", '1'),
      (X"9F21", X"11", '1'),
      (X"9F22", X"1F", '1'), -- Set address to 0xF11F6 and increment to 1.
      (X"9F23", X"FF", '1'), -- GB(0xFB)
      (X"9F23", X"FF", '1'), -- R(0xFB)

      -- Configure display composer
      (X"9F20", X"00", '1'),
      (X"9F21", X"00", '1'),
      (X"9F22", X"1F", '1'), -- Set address to 0xF0000 and increment to 1.
      (X"9F23", X"01", '1'), -- 0xF0000  DC_VIDEO
      (X"9F23", X"20", '1'), -- 0xF0001  DC_HSCALE
      (X"9F23", X"20", '1'), -- 0xF0002  DC_VSCALE
      (X"9F23", X"0E", '1'), -- 0xF0003  DC_BORDER_COLOR
      (X"9F23", X"00", '1'), -- 0xF0004  DC_HSTART_L
      (X"9F23", X"80", '1'), -- 0xF0005  DC_HSTOP_L
      (X"9F23", X"00", '1'), -- 0xF0006  DC_VSTART_L
      (X"9F23", X"E0", '1'), -- 0xF0007  DC_VSTOP_L
      (X"9F23", X"28", '1'), -- 0xF0008  DC_STARTSTOP_H
      (X"9F23", X"00", '1'), -- 0xF0008  DC_IRQ_LINE_L
      (X"9F23", X"00", '1'), -- 0xF0008  DC_IRQ_LINE_H

      -- The first part is the map area, i.e. the characters and colours.
      (X"9F20", X"00", '1'),
      (X"9F21", X"00", '1'),
      (X"9F22", X"10", '1'), -- Set address to 0x00000 and increment to 1.
      (X"9F23", X"FB", '1')  -- X=0, Y=0
   );

   signal index : integer := 0;

begin

   -- This process generates the CPU accesses
   p_wr : process (clk_i)
   begin
      if rising_edge(clk_i) then
         addr_o <= X"9F20";
         wr_en_o <= '0';
         rd_en_o <= '0';
         if index < commands'length then
            addr_o(2 downto 0) <= commands(index).addr(2 downto 0);
            if commands(index).wr_en = '1' then
               wr_en_o   <= '1';
               wr_data_o <= commands(index).data;
            else
               rd_en_o <= '1';
               exp_data_r <= commands(index).data;
            end if;
            index  <= index + 1;
         end if;
      end if;
   end process p_wr;

   debug_o <= to_stdlogicvector(index, 16);

   -- This process verifies the result of the CPU reads.
   p_rd : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if rd_en_o = '1' then
            assert rd_data_i = exp_data_r
               report "Read " & to_hstring(rd_data_i) & ", expected " & to_hstring(exp_data_r)
                  severity warning;
         end if;
      end if;
   end process p_rd;

end architecture structural;

