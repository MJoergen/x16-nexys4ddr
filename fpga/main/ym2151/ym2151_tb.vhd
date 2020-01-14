library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

-- This module is a test bench for the YM2151 module.

entity ym2151_tb is
end entity ym2151_tb;

architecture structural of ym2151_tb is

   -- Connected to DUT
   signal clk_s              : std_logic;  -- 8.33 MHz
   signal rst_s              : std_logic;
   signal addr_s             : std_logic_vector(0 downto 0);
   signal wr_en_s            : std_logic := '0';
   signal wr_data_s          : std_logic_vector(7 downto 0);

   signal ym2151_val_s       : std_logic_vector(9 downto 0);

   -- Control the execution of the test.
   signal sim_test_running_s : std_logic := '1';

begin

   -----------------------------
   -- Generate clock and reset
   -----------------------------

   -- Generate cpu clock @ 8.33 MHz
   proc_clk : process
   begin
      clk_s <= '1', '0' after 60 ns;
      wait for 120 ns;

      if sim_test_running_s = '0' then
         wait;
      end if;
   end process proc_clk;

   -- Generate cpu reset
   proc_rst : process
   begin
      rst_s <= '1', '0' after 200 ns;
      wait;
   end process proc_rst;

   -------------------
   -- Instantiate DUT
   -------------------

   i_ym2151 : entity work.ym2151
      port map (
         clk_i     => clk_s,
         rst_i     => rst_s,
         addr_i    => addr_s,
         wr_en_i   => wr_en_s,
         wr_data_i => wr_data_s,
         val_o     => ym2151_val_s
      ); -- i_ym2151
   

   --------------------
   -- Main test program
   --------------------

   p_test : process

      procedure write(addr : std_logic_vector; value : std_logic_vector) is
      begin
         addr_s    <= "0";
         wr_data_s <= addr;
         wr_en_s   <= '1';
         wait until clk_s = '1';
         wr_en_s   <= '0';
         wait until clk_s = '1';

         addr_s    <= "1";
         wr_data_s <= value;
         wr_en_s   <= '1';
         wait until clk_s = '1';
         wr_en_s   <= '0';
         wait until clk_s = '1';
      end procedure write;

   begin

      -- Wait for reset
      wait until clk_s  = '1';

      -----------------------------------------------
      -- END OF TEST
      -----------------------------------------------

      report "Test completed";
      sim_test_running_s <= '0';
      wait;

   end process p_test;

end structural;

