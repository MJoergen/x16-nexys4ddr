library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the Pulse Density Modulation module.
-- It takes as input a 12-bit signal representing an unsigned value between
-- 0x0.000 and 0x0.FFF. This value is interpreted as the required density
-- of the output signal.
-- The output will be a PDM signal which ranges from constantly zero to
-- constantly one.

entity pdm is
   port (
      clk_i     : in  std_logic;
      density_i : in  std_logic_vector(11 downto 0);
      pdm_o     : out std_logic
   );
end pdm;

architecture synthesis of pdm is

   signal accumulator_r : std_logic_vector(12 downto 0) := (others => '0');

begin

   p_accumulator : process (clk_i)
      variable accumulator_v : std_logic_vector(12 downto 0);
   begin
      if rising_edge(clk_i) then
         accumulator_v := accumulator_r + ("0" & density_i);
         if accumulator_v(12) = '1' then
            accumulator_r <= accumulator_v + 1;
         else
            accumulator_r <= accumulator_v;
         end if;
         pdm_o <= accumulator_v(12);
      end if;
   end process p_accumulator;


end architecture synthesis;

