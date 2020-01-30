library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

-- This file contains the ROM with the sine table.

entity sine_rom is
   port (
      clk_i     : in  std_logic;
      addr_i    : in  std_logic_vector(9 downto 0);
      rd_data_o : out std_logic_vector(9 downto 0)
   );
end sine_rom;

architecture synthesis of sine_rom is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 1023) of std_logic_vector(9 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      variable ROM_v : mem_t := (others => (others => '0'));
      variable sin_v : real;
   begin
      for i in 0 to 1023 loop
         sin_v   := sin(real(i*2+1) * MATH_PI / 1024.0)+1.0;
         ROM_v(i):= to_stdlogicvector(integer(sin_v*512.0), 10);
      end loop;
      return ROM_v;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         rd_data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end synthesis;

