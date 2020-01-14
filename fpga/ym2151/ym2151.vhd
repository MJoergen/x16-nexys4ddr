library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the main YM2151 module

entity ym2151 is
   port (
      clk_i : in  std_logic;                       -- CPU clock
      rst_i : in  std_logic;
      val_o : out std_logic_vector(9 downto 0)
   );
end ym2151;

architecture structural of ym2151 is

   constant C_CNT_MAX : std_logic_vector(7 downto 0) := to_stdlogicvector(8333/100, 8);

   signal val_r : std_logic_vector(9 downto 0);
   signal cnt_r : std_logic_vector(7 downto 0);

begin

   p_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cnt_r <= cnt_r + 1;
         if cnt_r = C_CNT_MAX then
            cnt_r <= (others => '0');
         end if;
      end if;
   end process p_cnt;


   -- Simple counter to produce a triangualer waveform
   p_val : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cnt_r = 0 then
            val_r <= val_r + 4;
         end if;
      end if;
   end process p_val;

end architecture structural;

