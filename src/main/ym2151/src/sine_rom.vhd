library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

use work.ym2151_package.all;

-- This file contains the ROM with the sine table.

entity sine_rom is
   port (
      clk_i  : in  std_logic;
      addr_i : in  std_logic_vector(C_PHASE_WIDTH-1 downto 0);
      data_o : out std_logic_vector(C_SINE_WIDTH-1 downto 0)
   );
end sine_rom;

architecture synthesis of sine_rom is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 2**C_PHASE_WIDTH-1) of std_logic_vector(C_SINE_WIDTH-1 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      variable phase_v : real;
      variable sin_v   : real;
      variable ROM_v   : mem_t := (others => (others => '0'));
   begin
      for i in 0 to 2**C_PHASE_WIDTH-1 loop
         phase_v := (real(i*2+1) * MATH_PI / real(2**C_PHASE_WIDTH));
         sin_v   := (sin(phase_v)+1.0)*0.5;
         ROM_v(i):= to_stdlogicvector(integer(sin_v*real(2**C_SINE_WIDTH-1)), C_SINE_WIDTH);
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

