library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

-- This file contains the ROM with the exp table.

entity exp_rom is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(9 downto 0);
      data_o : out std_logic_vector(9 downto 0)
   );
end exp_rom;

architecture synthesis of exp_rom is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 1023) of std_logic_vector(9 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      variable ROM_v : mem_t := (others => (others => '0'));
      variable exp_v : real;
   begin
      for i in 0 to 1023 loop
         exp_v   := exp(-real(i+1) / 1024.0 * log(2.0));
         report to_string(exp_v);
         ROM_v(i):= to_stdlogicvector(integer(exp_v*1024.0), 10);
      end loop;
      return ROM_v;
   end function;

   -- Initialize memory contents
   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end synthesis;

