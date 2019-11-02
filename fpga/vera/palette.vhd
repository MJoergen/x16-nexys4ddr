library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is a file containing the palette memory.
-- It performs a mapping from 8-bit values to 12-bit colours.

entity palette is
   port (
      -- CPU port
      cpu_clk_i     : in  std_logic;
      cpu_addr_i    : in  std_logic_vector( 8 downto 0);
      cpu_wr_en_i   : in  std_logic;
      cpu_wr_data_i : in  std_logic_vector( 7 downto 0);
      cpu_rd_en_i   : in  std_logic;
      cpu_rd_data_o : out std_logic_vector( 7 downto 0);
      -- VGA port
      vga_clk_i     : in  std_logic;
      vga_rd_addr_i : in  std_logic_vector( 7 downto 0);
      vga_rd_en_i   : in  std_logic;
      vga_rd_data_o : out std_logic_vector(11 downto 0)
   );
end palette;

architecture rtl of palette is

   -- This defines a type containing an array of bytes.
   type mem_t is array (0 to 511) of std_logic_vector(7 downto 0);

   -- Default palette. Copied from x16-emulator.
   signal mem_r : mem_t := ( 
      X"00", X"00", X"FF", X"0F", X"00", X"08", X"FE", X"0A",
      X"4C", X"0C", X"C5", X"00", X"0A", X"00", X"E7", X"0E",
      X"85", X"0D", X"40", X"06", X"77", X"0F", X"33", X"03",
      X"77", X"07", X"F6", X"0A", X"8F", X"00", X"BB", X"0B",
      X"00", X"00", X"11", X"01", X"22", X"02", X"33", X"03",
      X"44", X"04", X"55", X"05", X"66", X"06", X"77", X"07",
      X"88", X"08", X"99", X"09", X"AA", X"0A", X"BB", X"0B",
      X"CC", X"0C", X"DD", X"0D", X"EE", X"0E", X"FF", X"0F",
      X"11", X"02", X"33", X"04", X"44", X"06", X"66", X"08",
      X"88", X"0A", X"99", X"0C", X"BB", X"0F", X"11", X"02",
      X"22", X"04", X"33", X"06", X"44", X"08", X"55", X"0A",
      X"66", X"0C", X"77", X"0F", X"00", X"02", X"11", X"04",
      X"11", X"06", X"22", X"08", X"22", X"0A", X"33", X"0C",
      X"33", X"0F", X"00", X"02", X"00", X"04", X"00", X"06",
      X"00", X"08", X"00", X"0A", X"00", X"0C", X"00", X"0F",
      X"21", X"02", X"43", X"04", X"64", X"06", X"86", X"08",
      X"A8", X"0A", X"C9", X"0C", X"EB", X"0F", X"11", X"02",
      X"32", X"04", X"53", X"06", X"74", X"08", X"95", X"0A",
      X"B6", X"0C", X"D7", X"0F", X"10", X"02", X"31", X"04",
      X"51", X"06", X"62", X"08", X"82", X"0A", X"A3", X"0C",
      X"C3", X"0F", X"10", X"02", X"30", X"04", X"40", X"06",
      X"60", X"08", X"80", X"0A", X"90", X"0C", X"B0", X"0F",
      X"21", X"01", X"43", X"03", X"64", X"05", X"86", X"07",
      X"A8", X"09", X"C9", X"0B", X"FB", X"0D", X"21", X"01",
      X"42", X"03", X"63", X"04", X"84", X"06", X"A5", X"08",
      X"C6", X"09", X"F7", X"0B", X"20", X"01", X"41", X"02",
      X"61", X"04", X"82", X"05", X"A2", X"06", X"C3", X"08",
      X"F3", X"09", X"20", X"01", X"40", X"02", X"60", X"03",
      X"80", X"04", X"A0", X"05", X"C0", X"06", X"F0", X"07",
      X"21", X"01", X"43", X"03", X"65", X"04", X"86", X"06",
      X"A8", X"08", X"CA", X"09", X"FC", X"0B", X"21", X"01",
      X"42", X"02", X"64", X"03", X"85", X"04", X"A6", X"05",
      X"C8", X"06", X"F9", X"07", X"20", X"00", X"41", X"01",
      X"62", X"01", X"83", X"02", X"A4", X"02", X"C5", X"03",
      X"F6", X"03", X"20", X"00", X"41", X"00", X"61", X"00",
      X"82", X"00", X"A2", X"00", X"C3", X"00", X"F3", X"00",
      X"22", X"01", X"44", X"03", X"66", X"04", X"88", X"06",
      X"AA", X"08", X"CC", X"09", X"FF", X"0B", X"22", X"01",
      X"44", X"02", X"66", X"03", X"88", X"04", X"AA", X"05",
      X"CC", X"06", X"FF", X"07", X"22", X"00", X"44", X"01",
      X"66", X"01", X"88", X"02", X"AA", X"02", X"CC", X"03",
      X"FF", X"03", X"22", X"00", X"44", X"00", X"66", X"00",
      X"88", X"00", X"AA", X"00", X"CC", X"00", X"FF", X"00",
      X"12", X"01", X"34", X"03", X"56", X"04", X"68", X"06",
      X"8A", X"08", X"AC", X"09", X"CF", X"0B", X"12", X"01",
      X"24", X"02", X"46", X"03", X"58", X"04", X"6A", X"05",
      X"8C", X"06", X"9F", X"07", X"02", X"00", X"14", X"01",
      X"26", X"01", X"38", X"02", X"4A", X"02", X"5C", X"03",
      X"6F", X"03", X"02", X"00", X"14", X"00", X"16", X"00",
      X"28", X"00", X"2A", X"00", X"3C", X"00", X"3F", X"00",
      X"12", X"01", X"34", X"03", X"46", X"05", X"68", X"07",
      X"8A", X"09", X"9C", X"0B", X"BF", X"0D", X"12", X"01",
      X"24", X"03", X"36", X"04", X"48", X"06", X"5A", X"08",
      X"6C", X"09", X"7F", X"0B", X"02", X"01", X"14", X"02",
      X"16", X"04", X"28", X"05", X"2A", X"06", X"3C", X"08",
      X"3F", X"09", X"02", X"01", X"04", X"02", X"06", X"03",
      X"08", X"04", X"0A", X"05", X"0C", X"06", X"0F", X"07",
      X"12", X"02", X"34", X"04", X"46", X"06", X"68", X"08",
      X"8A", X"0A", X"9C", X"0C", X"BE", X"0F", X"11", X"02",
      X"23", X"04", X"35", X"06", X"47", X"08", X"59", X"0A",
      X"6B", X"0C", X"7D", X"0F", X"01", X"02", X"13", X"04",
      X"15", X"06", X"26", X"08", X"28", X"0A", X"3A", X"0C",
      X"3C", X"0F", X"01", X"02", X"03", X"04", X"04", X"06",
      X"06", X"08", X"08", X"0A", X"09", X"0C", X"0B", X"0F"
   );
 
begin

   ---------------
   -- CPU access.
   ---------------

   p_cpu_write : process (cpu_clk_i)
   begin
      if falling_edge(cpu_clk_i) then
         if cpu_wr_en_i = '1' then
            mem_r(to_integer(cpu_addr_i)) <= cpu_wr_data_i;
         end if;
      end if;
   end process p_cpu_write;

   p_cpu_read : process (cpu_clk_i)
   begin
      if falling_edge(cpu_clk_i) then
         if cpu_rd_en_i = '1' then
            cpu_rd_data_o <= mem_r(to_integer(cpu_addr_i));
         end if;
      end if;
   end process p_cpu_read;


   ---------------
   -- VGA access.
   ---------------

   p_vga : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         if vga_rd_en_i = '1' then
            vga_rd_data_o(11 downto 8) <= mem_r(to_integer(vga_rd_addr_i & "1"))(3 downto 0);
            vga_rd_data_o(7 downto 0)  <= mem_r(to_integer(vga_rd_addr_i & "0"));
         end if;
      end if;
   end process p_vga;

end rtl;

