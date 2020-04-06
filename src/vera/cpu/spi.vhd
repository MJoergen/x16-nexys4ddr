library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This implements the VERA SPI Master
--
-- Memory map:
-- 0 WRITE : Tx byte to send
-- 0 READ  : Rx byte received
-- 1 WRITE : bit 0 is card select
--         : bit 1 is Slow clock (0: 12.5 MHz, 1: 390 kHz).
-- 1 READ  : bit 0 is card select
--           bit 7 is busy

-- The Master must set the clock frequency, as well as polarity and phase (aka SPI mode).
-- Clock frequency : 390 kHz = 12.5 MHz / 32.
-- SPI mode        : 0.  Data in and out is valid on rising edge of clock.
-- The "out" side changes the data on the falling edge of the preceding clock
-- cycle, while the "in" side captures the data on (or shortly after) the
-- rising edge of the clock cycle. The out side holds the data valid until the
-- falling edge of the current clock cycle. For the first cycle, the first bit
-- must be on the MOSI line before the rising clock edge.
-- In other words:
-- * input data is captured on rising edge of SCLK.
-- * output data is propagated on falling edge of SCLK.
--
-- The clock must be pulled low before the chip select is activated. The chip
-- select line must be activated, which normally means being toggled low, for
-- the peripheral before the start of the transfer, and then deactivated
-- afterward. Most peripherals allow or require several transfers while the
-- select line is low; this routine might be called several times before
-- deselecting the chip.
--
-- Data bits are shifted MSB first.

entity spi is
   port (
      clk_i      : in  std_logic;
      rst_i      : in  std_logic;

      -- CPU interface
      addr_i     : in  std_logic_vector( 0 downto 0);
      wr_en_i    : in  std_logic;
      wr_data_i  : in  std_logic_vector( 7 downto 0);
      rd_en_i    : in  std_logic;
      rd_data_o  : out std_logic_vector( 7 downto 0);

      -- Connect to SD card
      spi_sclk_o : out std_logic;       -- sd_sck_io
      spi_mosi_o : out std_logic;       -- sd_cmd_io
      spi_miso_i : in  std_logic;       -- sd_dat_io(0)
      spi_cs_o   : out std_logic        -- sd_dat_io(3)
   );
end spi;

architecture structural of spi is

   signal valid_r    : std_logic;
   signal ready_s    : std_logic;
   signal data_in_r  : std_logic_vector(7 downto 0);
   signal data_out_s : std_logic_vector(7 downto 0);

   -- Debug
   constant DEBUG_MODE                : boolean := false; -- TRUE OR FALSE

   attribute mark_debug               : boolean;
   attribute mark_debug of addr_i     : signal is DEBUG_MODE;
   attribute mark_debug of wr_en_i    : signal is DEBUG_MODE;
   attribute mark_debug of wr_data_i  : signal is DEBUG_MODE;
   attribute mark_debug of rd_en_i    : signal is DEBUG_MODE;
   attribute mark_debug of rd_data_o  : signal is DEBUG_MODE;
   attribute mark_debug of valid_r    : signal is DEBUG_MODE;
   attribute mark_debug of ready_s    : signal is DEBUG_MODE;
   attribute mark_debug of data_in_r  : signal is DEBUG_MODE;
   attribute mark_debug of data_out_s : signal is DEBUG_MODE;

begin

   ---------------------------
   -- Decode CPU write access
   ---------------------------

   p_write : process (clk_i)
   begin
      if rising_edge(clk_i) then
         valid_r <= '0';

         if wr_en_i = '1' then
            case addr_i is
               when "0" =>
                  data_in_r <= wr_data_i;
                  valid_r   <= '1';

               when "1" =>
                  spi_cs_o <= wr_data_i(0);

               when others =>
                  null;
            end case;
         end if;

         if rst_i = '1' then
            spi_cs_o <= '0';
         end if;
      end if;
   end process p_write;


   --------------------------
   -- Decode CPU read access
   --------------------------

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         rd_data_o <= X"00";  -- Default value

         if rd_en_i = '1' then
            case addr_i is
               when "0" =>
                  rd_data_o <= data_out_s;

               when "1" =>
                  rd_data_o(0) <= spi_cs_o;
                  rd_data_o(7) <= not ready_s; -- busy

               when others =>
                  null;
            end case;
         end if;
      end if;
   end process p_read;


   --------------------------
   -- Instantiate SPI Master
   --------------------------

   i_spi_master : entity work.spi_master
      port map (
         clk_i      => clk_i,
         rst_i      => rst_i,
         valid_i    => valid_r,
         ready_o    => ready_s,
         data_i     => data_in_r,
         data_o     => data_out_s,
         spi_sclk_o => spi_sclk_o,
         spi_mosi_o => spi_mosi_o,
         spi_miso_i => spi_miso_i
      ); -- i_spi_master

end architecture structural;

