library ieee;
use ieee.std_logic_1164.all;

-- This block is a simple pulse converter.
-- It accepts a pulse of a single clock cycle on the input,
-- and presents a pulse of a single clock cycle on the output.
--
-- It works by converting the input pulse to a level toggle,
-- and back again.
--
-- Note: The pulses on the input side may not be too close.

entity pulse_conv is
   port (
      src_clk_i   : in  std_logic;
      src_pulse_i : in  std_logic;
      dst_clk_i   : in  std_logic;
      dst_pulse_o : out std_logic
   );
end pulse_conv;

architecture structural of pulse_conv is

   signal src_level_r : std_logic_vector(0 downto 0) := "0";
   signal dst_level_s : std_logic_vector(0 downto 0);
   signal dst_level_d : std_logic_vector(0 downto 0);

begin

   -- Convert pulse to level toggle
   p_src_level : process (src_clk_i)
   begin
      if rising_edge(src_clk_i) then
         if src_pulse_i = '1' then
            src_level_r(0) <= not src_level_r(0);
         end if;
      end if;
   end process p_src_level;

   -- Synchronize level toggle to destination
   i_cdc : entity work.cdc
      generic map (
         G_SIZE => 1
      )
      port map (
         src_clk_i => src_clk_i,
         src_dat_i => src_level_r,
         dst_clk_i => dst_clk_i,
         dst_dat_o => dst_level_s
      ); -- i_cdc

   -- Convert level toggle to pulse
   p_dst_pulse : process (dst_clk_i)
   begin
      if rising_edge(dst_clk_i) then
         dst_pulse_o <= dst_level_s(0) xor dst_level_d(0);
         dst_level_d <= dst_level_s;
      end if;
   end process p_dst_pulse;

end architecture structural;

