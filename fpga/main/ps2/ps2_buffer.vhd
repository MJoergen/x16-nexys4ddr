library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This module acts as a FIFO between the keyboard and the BASIC ROM.
-- The reason is that the keyboard interface on the Nexys4DDR board
-- does not quite follow the timing standard.

entity ps2_buffer is
   port (
      clk_i         : in  std_logic;
      rst_i         : in  std_logic;
      -- Connected to keyboard
      kbd_clk_i     : in  std_logic;
      kbd_clk_o     : out std_logic;
      kbd_clken_o   : out std_logic;
      kbd_data_i    : in  std_logic;
      kbd_data_o    : out std_logic;
      kbd_dataen_o  : out std_logic;
      -- Connected to MAIN module
      main_clk_o    : out std_logic;
      main_clk_i    : in  std_logic;
      main_clken_i  : in  std_logic;
      main_data_o   : out std_logic;
      main_data_i   : in  std_logic;
      main_dataen_i : in  std_logic
   );
end ps2_buffer;

architecture structural of ps2_buffer is

   signal data  : std_logic_vector(10 downto 0);
   signal valid : std_logic;
   signal ready : std_logic;

   -- Debug
   constant DEBUG_MODE                   : boolean := false; -- TRUE OR FALSE

   attribute mark_debug                  : boolean;
   attribute mark_debug of valid         : signal is DEBUG_MODE;
   attribute mark_debug of ready         : signal is DEBUG_MODE;
   attribute mark_debug of kbd_clk_i     : signal is DEBUG_MODE;
   attribute mark_debug of kbd_clk_o     : signal is DEBUG_MODE;
   attribute mark_debug of kbd_clken_o   : signal is DEBUG_MODE;
   attribute mark_debug of kbd_data_i    : signal is DEBUG_MODE;
   attribute mark_debug of kbd_data_o    : signal is DEBUG_MODE;
   attribute mark_debug of kbd_dataen_o  : signal is DEBUG_MODE;
   attribute mark_debug of main_clk_o    : signal is DEBUG_MODE;
   attribute mark_debug of main_clk_i    : signal is DEBUG_MODE;
   attribute mark_debug of main_clken_i  : signal is DEBUG_MODE;
   attribute mark_debug of main_data_o   : signal is DEBUG_MODE;
   attribute mark_debug of main_data_i   : signal is DEBUG_MODE;
   attribute mark_debug of main_dataen_i : signal is DEBUG_MODE;

begin

   -- Read from keyboad
   i_ps2_reader : entity work.ps2_reader
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         ps2_clk_i    => kbd_clk_i,
         ps2_clk_o    => kbd_clk_o,
         ps2_clken_o  => kbd_clken_o,
         ps2_data_i   => kbd_data_i,
         ps2_data_o   => kbd_data_o,
         ps2_dataen_o => kbd_dataen_o,
         data_o       => data,
         valid_o      => valid,
         ready_i      => ready
      ); -- i_ps2_reader

   -- Write to BASIC ROM
   i_ps2_writer : entity work.ps2_writer
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         data_i       => data,
         valid_i      => valid,
         ready_o      => ready,
         ps2_clk_o    => main_clk_o,
         ps2_clk_i    => main_clk_i,
         ps2_clken_i  => main_clken_i,
         ps2_data_o   => main_data_o,
         ps2_data_i   => main_data_i,
         ps2_dataen_i => main_dataen_i
      ); -- i_ps2_writer

end structural;

