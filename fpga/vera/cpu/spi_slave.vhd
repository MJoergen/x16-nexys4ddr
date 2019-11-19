library ieee;
use ieee.std_logic_1164.all;

-- This emulates a SPI slave

entity spi_slave is
   port (
      clk_i  : in  std_logic;
      rst_i  : in  std_logic;

      sclk_i : in  std_logic;
      ss_i   : in  std_logic;
      mosi_i : in  std_logic;
      miso_o : out std_logic
   );
end spi_slave;

architecture structural of spi_slave is

begin


end architecture structural;

