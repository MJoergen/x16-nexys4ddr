library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity tb is
end tb;

architecture structural of tb is

   signal clk          : std_logic;
   signal rst          : std_logic;

   signal wr_data      : std_logic_vector(10 downto 0);
   signal wr_valid     : std_logic;
   signal wr_ready     : std_logic;

   signal ps2_clk_w2r  : std_logic;
   signal ps2_clk_r2w  : std_logic;
   signal ps2_clken    : std_logic;
   signal ps2_data_w2r : std_logic;
   signal ps2_data_r2w : std_logic;
   signal ps2_dataen   : std_logic;

   signal rd_data      : std_logic_vector(10 downto 0);
   signal rd_valid     : std_logic;
   signal rd_ready     : std_logic;

begin

   -------------------
   -- Clock and reset
   -------------------

   p_clk : process
   begin
      clk <= '1', '0' after 6 ns;
      wait for 12 ns; -- 8.3 MHz
   end process p_clk;

   rst <= '1', '0' after 30*4 ns;

   wr_data <= "01100110011";
   wr_valid <= '0', '1' after 100*12 ns;

   process
   begin
      wr_valid <= '0';
      wait for 100*12 ns;
      wr_data <= "01100110011";
      wr_valid <= '1';
   end process;



   i_ps2_writer : entity work.ps2_writer
      port map (
         clk_i        => clk,
         rst_i        => rst,
         data_i       => wr_data,
         valid_i      => wr_valid,
         ready_o      => wr_ready,
         ps2_clk_o    => ps2_clk_w2r,
         ps2_clk_i    => ps2_clk_r2w,
         ps2_clken_i  => ps2_clken,
         ps2_data_o   => ps2_data_w2r,
         ps2_data_i   => ps2_data_r2w,
         ps2_dataen_i => ps2_dataen
      ); -- i_ps2_writer

   i_ps2_reader : entity work.ps2_reader
      port map (
         clk_i        => clk,
         rst_i        => rst,
         ps2_clk_i    => ps2_clk_w2r,
         ps2_clk_o    => ps2_clk_r2w,
         ps2_clken_o  => ps2_clken,
         ps2_data_i   => ps2_data_w2r,
         ps2_data_o   => ps2_data_r2w,
         ps2_dataen_o => ps2_dataen,
         data_o       => rd_data,
         valid_o      => rd_valid,
         ready_i      => rd_ready
      ); -- i_ps2_reader

end structural;

