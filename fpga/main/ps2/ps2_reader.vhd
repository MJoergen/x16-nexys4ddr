library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ps2_reader is
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;
      ps2_clk_i    : in  std_logic;
      ps2_clk_o    : out std_logic;
      ps2_clken_o  : out std_logic;
      ps2_data_i   : in  std_logic;
      ps2_data_o   : out std_logic;
      ps2_dataen_o : out std_logic;
      data_o       : out std_logic_vector(10 downto 0);
      valid_o      : out std_logic;
      ready_i      : in  std_logic
   );
end ps2_reader;

architecture structural of ps2_reader is

   signal ps2_clk_d  : std_logic;
   signal ps2_data_d : std_logic;
   signal ps2_clk_dd : std_logic;
   signal counter    : integer range 0 to 11;

begin

   p_reg : process (clk_i)
   begin
      if rising_edge(clk_i) then
         ps2_clk_d  <= ps2_clk_i;
         ps2_data_d <= ps2_data_i;
      end if;
   end process p_reg;

   p_data : process (clk_i)
   begin
      if rising_edge(clk_i) then
         ps2_clk_dd <= ps2_clk_d;
         if ps2_clk_dd = '1' and ps2_clk_d = '0' then
            data_o  <= ps2_data_d & data_o(10 downto 1);
            counter <= counter + 1;
         end if;

         -- Reset, when output has been received.
         if valid_o = '1' and ready_i = '1' then
            counter <= 0;
         end if;

         if rst_i = '1' then
            counter <= 0;
         end if;
      end if;
   end process p_data;

   -- Present data when ready
   valid_o <= '1' when counter = 11 else '0';

   -- Block incoming, until we have delivered our result
   ps2_clk_o   <= '0' when valid_o = '1' and ready_i = '0' else '1';
   ps2_clken_o <= '1' when valid_o = '1' and ready_i = '0' else '0';

   ps2_data_o   <= '1';
   ps2_dataen_o <= '0';

end structural;

