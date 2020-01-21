library ieee;
use ieee.std_logic_1164.all;

-- This emulates a SPI slave

-- The "out" side changes the data on the falling edge of the preceding clock
-- cycle, while the "in" side captures the data on (or shortly after) the
-- rising edge of the clock cycle. The out side holds the data valid until the
-- falling edge of the current clock cycle. For the first cycle, the first bit
-- must be on the MOSI line before the rising clock edge.

entity spi_slave is
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;

      -- TB interface
      valid_o    : out std_logic;
      data_o     : out std_logic_vector( 7 downto 0);
      valid_i    : in  std_logic;
      data_i     : in  std_logic_vector( 7 downto 0);

      -- Connect to DUT
      spi_sclk_i : in  std_logic;
      spi_mosi_i : in  std_logic;
      spi_miso_o : out std_logic
   );
end spi_slave;

architecture structural of spi_slave is

   signal spi_sclk_d  : std_logic;
   signal spi_mosi_d  : std_logic;

   signal spi_sclk_dd : std_logic;
   signal data_r      : std_logic_vector( 7 downto 0);

begin

   -- Synchronize signals to the main clock.
   p_reg : process (clk_i)
   begin
      if rising_edge(clk_i) then
         spi_sclk_d  <= spi_sclk_i;
         spi_mosi_d <= spi_mosi_i;
      end if;
   end process p_reg;

   p_data : process (clk_i)
   begin
      if rising_edge(clk_i) then
         spi_sclk_dd <= spi_sclk_d;

         -- Rising edge
         if spi_sclk_dd = '0' and spi_sclk_d = '1' then
            data_o <= spi_mosi_d & data_o(7 downto 1);
         end if;

         -- Falling edge
         if spi_sclk_dd = '1' and spi_sclk_d = '0' then
            data_r <= '1' & data_r(7 downto 1);
         end if;

         if valid_i = '1' then
            data_r <= data_i;
         end if;
      end if;
   end process p_data;

   spi_miso_o <= data_r(0);

end architecture structural;

