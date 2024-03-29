library ieee;
use ieee.std_logic_1164.all;

-- This block handles all the configuration settings of the VERA,
-- i.e. everything other than the Video RAM and the palette RAM.
--
-- TBD: Currently, only MAP and TILE area base addressess are supported.

entity config is
   port (
      clk_i       : in  std_logic;
      addr_i      : in  std_logic_vector(19 downto 0);
      wr_en_i     : in  std_logic;
      wr_data_i   : in  std_logic_vector( 7 downto 0);
      rd_en_i     : in  std_logic;
      rd_data_o   : out std_logic_vector( 7 downto 0);

      map_base_o  : out std_logic_vector(17 downto 0);
      tile_base_o : out std_logic_vector(17 downto 0);
      mode_o      : out std_logic_vector( 2 downto 0);
      hscale_o    : out std_logic_vector( 7 downto 0);
      vscale_o    : out std_logic_vector( 7 downto 0)
   );
end config;

architecture structural of config is

begin

   p_config : process (clk_i)
   begin
      if rising_edge(clk_i) then
         map_base_o( 1 downto 0) <= "00";
         tile_base_o(1 downto 0) <= "00";

         if wr_en_i = '1' then
            case addr_i(19 downto 12) is
               when X"F0" =>                                                     -- Display composer
                  case addr_i is
                     when X"F0001" => hscale_o <= wr_data_i;                     -- DC_HSCALE
                     when X"F0002" => vscale_o <= wr_data_i;                     -- DC_VSCALE
                     when others => null;
                  end case;
               when X"F2" => null;                                               -- Layer 0
               when X"F3" =>                                                     -- Layer 1
                  case addr_i is
                     when X"F3000" => mode_o <= wr_data_i(7 downto 5);           -- L1_MODE
                     when X"F3002" => map_base_o(  9 downto  2) <= wr_data_i;    -- L1_MAP_BASE_L
                     when X"F3003" => map_base_o( 17 downto 10) <= wr_data_i;    -- L1_MAP_BASE_H
                     when X"F3004" => tile_base_o( 9 downto  2) <= wr_data_i;    -- L1_TILE_BASE_L
                     when X"F3005" => tile_base_o(17 downto 10) <= wr_data_i;    -- L1_TILE_BASE_H
                     when others => null;
                  end case;
               when X"F4" => null;                                               -- Sprite
               when X"F5" => null;                                               -- Sprite attributes
               when X"F6" => null;                                               -- Audio
               when X"F7" => null;                                               -- SPI
                  -- F7000 : spi_data. Initiate transmit upon write.
                  -- F7001 : spi_ctl. Read Bit 7 is high = busy.
                  --                  Write Bit 0 high = select
               when X"F8" => null;                                               -- UART
               when others => null;
            end case;
         end if; -- if wr_en_i = '1' then

         if rd_en_i = '1' then
            case addr_i(19 downto 12) is
               when X"F0" =>                                                     -- Displace composer
                  case addr_i is
                     when X"F0001" => rd_data_o <= hscale_o;
                     when X"F0002" => rd_data_o <= vscale_o;
                     when others => null;
                  end case;
               when X"F3" =>                                                     -- Layer 1
                  case addr_i is
                     when X"F3000" => rd_data_o <= mode_o & "00001";
                     when X"F3002" => rd_data_o <= map_base_o(  9 downto  2);
                     when X"F3003" => rd_data_o <= map_base_o( 17 downto 10);
                     when X"F3004" => rd_data_o <= tile_base_o( 9 downto  2);
                     when X"F3005" => rd_data_o <= tile_base_o(17 downto 10);
                     when others => null;
                  end case;
               when others => null;
            end case;
         end if; -- if rd_en_i = '1' then
      end if;
   end process p_config;

end architecture structural;

