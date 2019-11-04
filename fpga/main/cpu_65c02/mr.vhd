library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity mr is
   port (
      clk_i    : in  std_logic;
      wait_i   : in  std_logic;
      mr_sel_i : in  std_logic;
      alu_mr_i : in  std_logic_vector(7 downto 0);

      mr_o     : out std_logic_vector(7 downto 0)
   );
end entity mr;

architecture structural of mr is

   -- 'A' register
   signal mr : std_logic_vector(7 downto 0);

begin

   -- 'A' register
   mr_proc : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wait_i = '0' then
            if mr_sel_i = '1' then
               mr <= alu_mr_i;
            end if;
         end if;
      end if;
   end process mr_proc;

   -- Drive output signal
   mr_o <= mr;

end architecture structural;

