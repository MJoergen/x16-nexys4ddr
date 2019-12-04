library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;
use std.textio.all;

-- This module is a test bench for the Ethernet module.

entity ethernet_tb is
end entity ethernet_tb;

architecture structural of ethernet_tb is

   -- Connected to DUT
   signal cpu_clk_s          : std_logic;  -- 8.33 MHz
   signal cpu_clkn_s         : std_logic;  -- 8.33 MHz
   signal cpu_rst_s          : std_logic;
   signal cpu_addr_s         : std_logic_vector(3 downto 0);
   signal cpu_wr_en_s        : std_logic := '0';
   signal cpu_wr_data_s      : std_logic_vector(7 downto 0);
   signal cpu_rd_en_s        : std_logic := '0';
   signal cpu_rd_data_s      : std_logic_vector(7 downto 0);
   --
   signal eth_clk_s          : std_logic;  -- 50 MHz
   signal eth_refclk_s       : std_logic;
   signal eth_rstn_s         : std_logic;
   signal eth_rxd_s          : std_logic_vector(1 downto 0);
   signal eth_crsdv_s        : std_logic;
   signal eth_txd_s          : std_logic_vector(1 downto 0);
   signal eth_txen_s         : std_logic;

   -- Control the execution of the test.
   signal sim_test_running_s : std_logic := '1';

begin

   -----------------------------
   -- Generate clock and reset
   -----------------------------

   -- Generate cpu clock @ 8.33 MHz
   proc_cpu_clk : process
   begin
      cpu_clk_s <= '1', '0' after 60 ns;
      wait for 120 ns;

      if sim_test_running_s = '0' then
         wait;
      end if;
   end process proc_cpu_clk;

   -- Generate cpu reset
   proc_cpu_rst : process
   begin
      cpu_rst_s <= '1', '0' after 200 ns;
      wait;
   end process proc_cpu_rst;

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

   cpu_clkn_s <= not cpu_clk_s;


   -------------------
   -- Instantiate DUT
   -------------------

   i_ethernet : entity work.ethernet
      port map (
         cpu_clk_i     => cpu_clkn_s,
         cpu_rst_i     => cpu_rst_s,
         cpu_addr_i    => cpu_addr_s,
         cpu_wr_en_i   => cpu_wr_en_s,
         cpu_wr_data_i => cpu_wr_data_s,
         cpu_rd_en_i   => cpu_rd_en_s,
         cpu_rd_data_o => cpu_rd_data_s,
         --
         eth_clk_i     => eth_clk_s,
         eth_txd_o     => eth_txd_s,
         eth_txen_o    => eth_txen_s,
         eth_rxd_i     => eth_rxd_s,
         eth_rxerr_i   => '0',
         eth_crsdv_i   => eth_crsdv_s,
         eth_intn_i    => '0',
         eth_mdio_io   => open,
         eth_mdc_o     => open,
         eth_rstn_o    => eth_rstn_s,
         eth_refclk_o  => eth_refclk_s
      ); -- i_ethernet
   

   --------------------
   -- Main test program
   --------------------

   p_test : process

      procedure write(addr : std_logic_vector; value : std_logic_vector) is
      begin
         cpu_addr_s    <= addr;
         cpu_wr_data_s <= value;
         cpu_wr_en_s   <= '1';
         wait until cpu_clk_s = '1';
         cpu_wr_en_s   <= '0';
         wait until cpu_clk_s = '1';
      end procedure write;

      procedure read(addr : std_logic_vector; value : out std_logic_vector) is
      begin
         cpu_addr_s  <= addr;
         cpu_rd_en_s <= '1';
         wait until cpu_clk_s = '1';
         value := cpu_rd_data_s;
         cpu_rd_en_s <= '0';
         wait until cpu_clk_s = '1';
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
            read("0011", value);
            if value = 0 then
               exit;
            end if;
         end loop;

         write("0000", X"00");
         write("0001", X"00");

         read("0010", value);
         assert value = length mod 256;
         read("0010", value);
         assert value = length/256;


         for i in 0 to length-1 loop
            read("0010", value);
            assert value = to_std_logic_vector((i+first) mod 256, 8);
         end loop;

      end procedure receive_frame;

   begin

      -- Wait for reset
      wait until eth_rstn_s = '1';
      wait until cpu_clk_s  = '1';


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

