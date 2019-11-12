library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

entity ps2_buffer is
   port (
      clk_i       : in    std_logic;
      rst_i       : in    std_logic;
      -- Connected to keyboard
      ps2_clk_io  : inout std_logic;
      ps2_data_io : inout std_logic;
      -- Connected to MAIN module
      ps2_clk_o    : out std_logic;
      ps2_clk_i    : in  std_logic;
      ps2_clken_i  : in  std_logic;
      ps2_data_o   : out std_logic;
      ps2_data_i   : in  std_logic;
      ps2_dataen_i : in  std_logic
   );
end ps2_buffer;

architecture structural of ps2_buffer is

   signal data  : std_logic_vector(10 downto 0);
   signal valid : std_logic;
   signal ready : std_logic;

begin

   i_ps2_reader : entity work.ps2_reader
      port map (
         clk_i       => clk_i,
         rst_i       => rst_i,
         ps2_clk_io  => ps2_clk_io,
         ps2_data_io => ps2_data_io,
         data_o      => data,
         valid_o     => valid,
         ready_i     => ready
      ); -- i_ps2_reader

   i_ps2_writer : entity work.ps2_writer is
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         data_i       => data,
         valid_i      => valid,
         ready_o      => ready,
         ps2_clk_o    => ps2_clk_o,
         ps2_clk_i    => ps2_clk_i,
         ps2_clken_i  => ps2_clken_i,
         ps2_data_o   => ps2_data_o,
         ps2_data_i   => ps2_data_i,
         ps2_dataen_i => ps2_dataen_i
      ); i_ps2_writer

end structural;

