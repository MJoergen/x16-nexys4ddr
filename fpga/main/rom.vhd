library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

-- This module models a single-port asynchronous ROM.
--
-- Note: Read occurs on the *falling* edge of the clock cycle. This is to allow
-- the 65C02 to read asynchronously.

entity rom is
   generic (
      G_INIT_FILE : string;
      G_ADDR_BITS : integer
   );
   port (
      clk_i     : in  std_logic;
      addr_i    : in  std_logic_vector(G_ADDR_BITS-1 downto 0);
      rd_en_i   : in  std_logic;
      rd_data_o : out std_logic_vector(7 downto 0)
   );
end rom;

architecture structural of rom is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 2**G_ADDR_BITS-1) of std_logic_vector(7 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRamFromFile(RamFileName : in string) return mem_t is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : mem_t := (others => (others => '0'));
   begin
      file_open(RamFile, RamFileName, read_mode);
      for i in mem_t'range loop
         readline (RamFile, RamFileLine);
         hread (RamFileLine, RAM(i));
         if endfile(RamFile) then
            return RAM;
         end if;
      end loop;
      return RAM;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRamFromFile(G_INIT_FILE);

begin

   p_read : process (clk_i)
   begin
      if falling_edge(clk_i) then
         if rd_en_i = '1' then
            rd_data_o <= mem_r(to_integer(addr_i));
         end if;
      end if;
   end process p_read;

end structural;

