library ieee;
use ieee.std_logic_1164.all;

-- This implements the VERA SPI controller
--
-- Memory map:
-- 0 WRITE : Tx byte to send
-- 0 READ  : Rx byte received
-- 1 WRITE : bit 0 is card select
-- 1 READ  : bit 0 is card select
--           bit 7 is busy

entity spi is
   port (
      clk_i       : in    std_logic;
      addr_i      : in    std_logic_vector( 0 downto 0);
      wr_en_i     : in    std_logic;
      wr_data_i   : in    std_logic_vector( 7 downto 0);
      rd_en_i     : in    std_logic;
      rd_data_o   : out   std_logic_vector( 7 downto 0);

      sd_reset_o  : out   std_logic;                       -- SD card
      sd_dat_io   : inout std_logic_vector(3 downto 0);    -- miso, cs
      sd_cmd_io   : inout std_logic;                       -- mosi
      sd_sck_io   : inout std_logic;
      sd_cd_i     : in    std_logic
   );
end spi;

architecture structural of spi is

   signal ss      : std_logic;
   signal busy    : std_logic;
   signal tx_byte : std_logic_vector(7 downto 0);
   signal rx_byte : std_logic_vector(7 downto 0);
   signal bit_cnt : integer range 0 to 8;
   signal cmd_cnt : integer range 0 to 8;

begin

   p_reg : process (clk_i)
   begin
      if falling_edge(clk_i) then
         if wr_en_i = '1' then
            case addr_i(0) is
               when '0' =>
                  if ss and not busy then
                     tx_byte <= wr_data_i;
                     busy    <= '1';
                     bit_cnt <= 0;
                  end if;

               when '1' =>
                  if ss /= wr_data_i(0) then
                     ss <= wr_data_i(0);
                     if wr_data_i(0) = '1' then
                        cmd_cnt <= 0;
                     end if;
                  end if;
            end case;
         end if;

         if rd_en_i = '1' then
            case addr_i(0) is
               when '0' =>
                  rd_data_o <= rx_byte;

               when '1' =>
                  rd_data_o <= busy & "000000" & ss;
            end case;
         end if;

         if busy = '1' then
            bit_cnt <= bit_cnt + 1;
            if bit_cnt = 8 then
               busy <= '0';
            end if;
         end if;
      end if;
   end process p_reg;

end architecture structural;

