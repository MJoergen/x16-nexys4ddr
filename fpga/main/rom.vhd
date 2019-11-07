library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

entity rom is
   generic (
      G_INIT_FILE : string;
      G_ADDR_BITS : integer
   );
   port (
      clk_i     : in  std_logic;
      addr_i    : in  std_logic_vector(G_ADDR_BITS-1 downto 0);
      rd_en_i   : in  std_logic;       -- Ignored, to save logic resources.
      rd_data_o : out std_logic_vector(7 downto 0)
   );
end rom;

architecture structural of rom is

   constant C_SIMULATION : boolean :=
   -- pragma synthesis_off
   true or
   -- pragma synthesis_on
   false;

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 2**G_ADDR_BITS-1) of std_logic_vector(7 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRamFromFile(RamFileName : in string) return mem_t is
      FILE RamFile : text;
      variable RamFileLine : line;
      variable RAM : mem_t := (others => (others => '0'));
   begin
      if C_SIMULATION then
         file_open(RamFile, RamFileName, read_mode);
         for i in mem_t'range loop
            readline (RamFile, RamFileLine);
            hread (RamFileLine, RAM(i));
            if endfile(RamFile) then
               return RAM;
            end if;
         end loop;
      end if;
      return RAM;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRamFromFile(G_INIT_FILE);
--   signal mem_r : mem_t := (others => (others => '0'));

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         rd_data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end structural;

