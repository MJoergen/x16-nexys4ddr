library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

-- This file contains the ROM with the table of log sine..
-- Input is interpreted as an unsigned fractional number between 0 and 2pi.
-- Output is the negative logarithm of the sine, interpreted as an unsigned
-- 
-- The function calculated is y=-log(abs(sin(x))).

entity logsine_rom is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(C_LOGSINE_ADDR_WIDTH-1 downto 0);
      data_o : out std_logic_vector(C_LOGSINE_DATA_WIDTH-1 downto 0)
   );
end logsine_rom;

architecture synthesis of logsine_rom is

   type mem_t is array (0 to 2**C_LOGSINE_ADDR_WIDTH-1) of std_logic_vector(C_LOGSINE_DATA_WIDTH-1 downto 0);

   impure function InitRom return mem_t is
      variable phase_v   : real;
      variable logsine_v : real;
      variable ROM_v     : mem_t := (others => (others => '0'));
   begin
      for i in 0 to 2**C_LOGSINE_ADDR_WIDTH-1 loop
         phase_v   := (real(i*2+1) * MATH_PI / real(2**C_LOGSINE_ADDR_WIDTH));
         logsine_v := -log(abs(sin(phase_v)));
         ROM_v(i)  := to_stdlogicvector(integer(logsine_v*real(2**C_LOGSINE_DATA_WIDTH-1)), C_LOGSINE_DATA_WIDTH);
      end loop;
      return ROM_v;
   end function;

   signal mem_r : mem_t := InitRom;

begin

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         data_o <= mem_r(to_integer(addr_i));
      end if;
   end process p_read;

end synthesis;

