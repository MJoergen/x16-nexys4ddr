library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the PWN module
-- It takes as input a 10-bit signal and produces a PWN output.
-- The input frequency should be 100 MHz, and the PWM frequency therefore
-- becomes approx. 100 kHz.

entity pwm is
   port (
      clk_i    : in  std_logic;                       -- 100 MHz
      val_i    : in  std_logic_vector(9 downto 0);
      pwm_o    : out std_logic
   );
end pwm;

architecture structural of pwm is

   signal cnt_r    : std_logic_vector(9 downto 0);
   signal val_r    : std_logic_vector(9 downto 0);

begin

   p_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cnt_r <= cnt_r + 1;
         if cnt_r = "1111111111" then
            val_r <= val_i;
         end if;
      end if;
   end process p_cnt;

   p_pwm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cnt_r < val_r then
            pwm_o <= '1';
         else
            pwm_o <= '0';
         end if;
      end if;
   end process p_pwm;

end architecture structural;

