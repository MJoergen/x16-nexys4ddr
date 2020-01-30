library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use ieee.math_real.all;

-- This file contains the ROM with the phase increments (frequency) of each
-- note.
--
-- The input consists of 12*64 = 768 possible keys, represented as a 10-bit binary number.
-- The output is the phase increment

entity phaseinc_rom is
   generic (
      G_CLOCK_HZ : integer -- Frequency of input clock
   );
   port (
      clk_i     : in  std_logic;
      addr_i    : in  std_logic_vector( 9 downto 0);
      rd_data_o : out std_logic_vector(11 downto 0)
   );
end phaseinc_rom;

architecture synthesis of phaseinc_rom is

   -- This defines a type containing an array of bytes
   type mem_t is array (0 to 1023) of std_logic_vector(11 downto 0);

   -- This reads the ROM contents from a text file
   impure function InitRom return mem_t is
      variable ROM_v      : mem_t := (others => (others => '0'));
      variable freq_v     : real;
      variable phaseinc_v : integer;
   begin
      -- Index 0 corresponds to C#, which is 4 semitones above A.
      for i in 0 to 767 loop
         freq_v     := 440.0 * (2.0 ** (real(i+4*64)/768.0));
         phaseinc_v := integer((2.0**24)*freq_v)/G_CLOCK_HZ;
         ROM_v(i)   := to_stdlogicvector(phaseinc_v, 12);
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

