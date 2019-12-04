library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

-- This module is a test bench for the Ethernet module.

entity ethernet_tb is
end entity ethernet_tb;

architecture structural of ethernet_tb is

   -- Connected to DUT
   signal main_clk_s         : std_logic;  -- 8.33 MHz
   signal main_clkn_s        : std_logic;  -- 8.33 MHz
   signal main_rst_s         : std_logic;
   signal main_addr_s        : std_logic_vector(3 downto 0);
   signal main_wr_en_s       : std_logic := '0';
   signal main_wr_data_s     : std_logic_vector(7 downto 0);
   signal main_rd_en_s       : std_logic := '0';
   signal main_rd_data_s     : std_logic_vector(7 downto 0);
   --
   signal eth_clk_s          : std_logic;  -- 50 MHz
   signal eth_refclk_s       : std_logic;
   signal eth_rstn_s         : std_logic;
   signal eth_rxd_s          : std_logic_vector(1 downto 0);
   signal eth_crsdv_s        : std_logic;
   signal eth_txd_s          : std_logic_vector(1 downto 0);
   signal eth_txen_s         : std_logic;

   -- Used to clear the sim_ram between each test.
   signal sim_ram_in         : std_logic_vector(16383 downto 0);
   signal sim_ram_out        : std_logic_vector(16383 downto 0);
   signal sim_ram_init       : std_logic;

   -- Control the execution of the test.
   signal sim_test_running_s : std_logic := '1';

begin

   -----------------------------
   -- Generate clock and reset
   -----------------------------

   -- Generate cpu clock @ 8.33 MHz
   proc_main_clk : process
   begin
      main_clk_s <= '1', '0' after 60 ns;
      wait for 120 ns;

      if sim_test_running_s = '0' then
         wait;
      end if;
   end process proc_main_clk;

   -- Generate cpu reset
   proc_main_rst : process
   begin
      main_rst_s <= '1', '0' after 200 ns;
      wait;
   end process proc_main_rst;

   -- Generate eth clock @ 50 MHz
   proc_eth_clk : process
   begin
      eth_clk_s <= '1', '0' after 10 ns;
      wait for 20 ns;

      if sim_test_running_s = '0' then
         wait;
      end if;
   end process proc_eth_clk;


   ----------------
   -- PHY loopback
   ----------------

   eth_rxd_s   <= eth_txd_s;
   eth_crsdv_s <= eth_txen_s;

   main_clkn_s <= not main_clk_s;


   -------------------
   -- Instantiate DUT
   -------------------

   i_ethernet : entity work.ethernet
      port map (
         clk_i        => main_clkn_s,
         rst_i        => main_rst_s,
         addr_i       => main_addr_s,
         wr_en_i      => main_wr_en_s,
         wr_data_i    => main_wr_data_s,
         rd_en_i      => main_rd_en_s,
         rd_data_o    => main_rd_data_s,
         --
         eth_clk_i    => eth_clk_s,
         eth_txd_o    => eth_txd_s,
         eth_txen_o   => eth_txen_s,
         eth_rxd_i    => eth_rxd_s,
         eth_rxerr_i  => '0',
         eth_crsdv_i  => eth_crsdv_s,
         eth_intn_i   => '0',
         eth_mdio_io  => open,
         eth_mdc_o    => open,
         eth_rstn_o   => eth_rstn_s,
         eth_refclk_o => eth_refclk_s
      ); -- i_ethernet
   

   --------------------
   -- Main test program
   --------------------

   p_test : process

      procedure write(addr : std_logic_vector; value : std_logic_vector) is
      begin
         main_addr_s    <= addr;
         main_wr_data_s <= value;
         main_wr_en_s   <= '1';
         wait until main_clk_s = '1';
         main_wr_en_s   <= '0';
         wait until main_clk_s = '1';
      end procedure write;

      procedure read(addr : std_logic_vector; value : out std_logic_vector) is
      begin
         main_addr_s  <= addr;
         main_rd_en_s <= '1';
         wait until main_clk_s = '1';
         value := main_rd_data_s;
         main_rd_en_s <= '0';
         wait until main_clk_s = '1';
      end procedure read;
      
      
      procedure send_frame(first : integer; length : integer; offset : integer) is
         variable value : std_logic_vector(7 downto 0);
      begin
         write("1000", X"00");
         write("1001", X"00");
         write("1010", to_std_logic_vector(length mod 256, 8));
         write("1010", to_std_logic_vector(length/256, 8));
         for i in 0 to length-1 loop
            write("1010", to_std_logic_vector((i+first) mod 256, 8));
         end loop;
         write("1011", X"01");    -- Start Tx

         while (true) loop
            read("1011", value);
            if value = 0 then
               exit;
            end if;
         end loop;

      end procedure send_frame;

      procedure receive_frame(first : integer; length : integer; offset : integer) is
         variable value : std_logic_vector(7 downto 0);
      begin
         write("0011", X"01");    -- Start Rx

         while (true) loop
            read("1011", value);
            if value = 0 then
               exit;
            end if;
         end loop;

         write("1000", X"00");
         write("1001", X"00");

         read("1011", value);
         assert value = length mod 256;
         read("1011", value);
         assert value = length/256;


         for i in 0 to length-1 loop
            read("1011", value);
            assert value = to_std_logic_vector((i+first) mod 256, 8);
         end loop;

      end procedure receive_frame;

   begin

      -- Wait for reset
      wait until eth_rstn_s = '1';
      wait until main_clk_s = '1';


      -----------------------------------------------
      -- Test 1 : Send a single frame
      -- Expected behaviour: Frame is received
      -----------------------------------------------

      send_frame(first => 32, length => 100, offset => 1000);
      receive_frame(first => 32, length => 100, offset => 600);


      -----------------------------------------------
      -- Test 2 : Send two frames
      -- Expected behaviour: Two frames are received
      -----------------------------------------------

      send_frame(first => 40, length => 90, offset => 800);
      send_frame(first => 50, length => 80, offset => 400);
      receive_frame(first => 40, length => 90, offset => 400);
      receive_frame(first => 50, length => 80, offset => 800);


      -----------------------------------------------
      -- END OF TEST
      -----------------------------------------------

      report "Test completed";
      sim_test_running_s <= '0';
      wait;

   end process p_test;

end structural;

