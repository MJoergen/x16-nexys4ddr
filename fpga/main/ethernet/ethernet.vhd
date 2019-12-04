library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This module provides a high-level interface to the Ethernet port.

entity ethernet is
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;

      -- Connected to CPU
      addr_i       : in  std_logic_vector(3 downto 0);
      wr_en_i      : in  std_logic;
      wr_data_i    : in  std_logic_vector(7 downto 0);
      rd_en_i      : in  std_logic;
      rd_data_o    : out std_logic_vector(7 downto 0);

      -- Connected to PHY.
      eth_clk_i    : in    std_logic; -- Must be 50 MHz
      eth_txd_o    : out   std_logic_vector(1 downto 0);
      eth_txen_o   : out   std_logic;
      eth_rxd_i    : in    std_logic_vector(1 downto 0);
      eth_rxerr_i  : in    std_logic;
      eth_crsdv_i  : in    std_logic;
      eth_intn_i   : in    std_logic;
      eth_mdio_io  : inout std_logic;
      eth_mdc_o    : out   std_logic;
      eth_rstn_o   : out   std_logic;
      eth_refclk_o : out   std_logic
   );
end ethernet;

architecture structural of ethernet is

   -- Minimum reset assert time for the Ethernet PHY is 25 ms.
   -- At 50 MHz (= 20 ns pr clock cycle) this is approx 2*10^6 clock cycles.
   -- Therefore, the rst_cnt has a size of 21 bits, which means that
   -- 'eth_rst' is deasserted after 40 ms.
   signal eth_rst_r            : std_logic := '1';
   signal eth_rst_cnt_r        : std_logic_vector(20 downto 0) := (others => '1');

   -- Connected to the PHY
   signal eth_rx_valid_s       : std_logic;
   signal eth_rx_eof_s         : std_logic;
   signal eth_rx_data_s        : std_logic_vector(7 downto 0);
   signal eth_rx_error_s       : std_logic_vector(1 downto 0);
   signal eth_tx_empty_s       : std_logic;
   signal eth_tx_rden_s        : std_logic;
   signal eth_tx_data_s        : std_logic_vector(7 downto 0);
   signal eth_tx_eof_s         : std_logic_vector(0 downto 0);

   -- Connection from rx_header to rxfifo
   signal eth_rxheader_valid_s : std_logic;
   signal eth_rxheader_data_s  : std_logic_vector(7 downto 0);
   signal eth_rxheader_eof_s   : std_logic_vector(0 downto 0);
   signal eth_rxheader_afull_s : std_logic;

   -- Connection from rxfifo to rx_dma
   signal rxfifo_empty_s       : std_logic;
   signal rxfifo_data_s        : std_logic_vector(7 downto 0);
   signal rxfifo_eof_s         : std_logic_vector(0 downto 0);
   signal rxfifo_rden_s        : std_logic;

   -- Connection from tx_dma to txfifo
   signal txfifo_afull_s       : std_logic;
   signal txfifo_valid_s       : std_logic;
   signal txfifo_data_s        : std_logic_vector(7 downto 0);
   signal txfifo_eof_s         : std_logic_vector(0 downto 0);
   
   signal rx_rd_data_s         : std_logic_vector(7 downto 0);
   signal tx_rd_data_s         : std_logic_vector(7 downto 0);

begin

   ------------------------------
   -- Generates reset signal for the Ethernet PHY.
   ------------------------------

   p_eth_rst : process (eth_clk_i)
   begin
      if rising_edge(eth_clk_i) then
         if eth_rst_cnt_r /= 0 then
            eth_rst_cnt_r <= eth_rst_cnt_r - 1;
         else
            eth_rst_r <= '0';
         end if;

         -- During simulation we want the reset pulse to be much shorter.
         -- pragma synthesis_off
         eth_rst_cnt_r(20 downto 6) <= (others => '0');
         -- pragma synthesis_on
      end if;
   end process p_eth_rst;
   

   ------------------------------
   -- Ethernet LAN 8720A PHY
   ------------------------------

   i_lan8720a : entity work.lan8720a
      port map (
         clk_i        => eth_clk_i,
         rst_i        => eth_rst_r,
         -- Rx interface
         rx_valid_o   => eth_rx_valid_s,
         rx_eof_o     => eth_rx_eof_s,
         rx_data_o    => eth_rx_data_s,
         rx_error_o   => eth_rx_error_s,
         -- Tx interface
         tx_empty_i   => eth_tx_empty_s,
         tx_rden_o    => eth_tx_rden_s,
         tx_data_i    => eth_tx_data_s,
         tx_eof_i     => eth_tx_eof_s(0),
         -- External pins to the LAN 8720A PHY
         eth_txd_o    => eth_txd_o,
         eth_txen_o   => eth_txen_o,
         eth_rxd_i    => eth_rxd_i,
         eth_rxerr_i  => eth_rxerr_i,
         eth_crsdv_i  => eth_crsdv_i,
         eth_intn_i   => eth_intn_i,
         eth_mdio_io  => eth_mdio_io,
         eth_mdc_o    => eth_mdc_o,
         eth_rstn_o   => eth_rstn_o,
         eth_refclk_o => eth_refclk_o
      ); -- i_lan8720a


   -------------------------------
   -- Header insertion
   -------------------------------

   i_rx_header : entity work.rx_header
      port map (
         clk_i          => eth_clk_i,
         rst_i          => eth_rst_r,
         rx_valid_i     => eth_rx_valid_s,
         rx_eof_i       => eth_rx_eof_s,
         rx_data_i      => eth_rx_data_s,
         rx_error_i     => eth_rx_error_s,
         --
         out_afull_i    => eth_rxheader_afull_s,
         out_valid_o    => eth_rxheader_valid_s,
         out_data_o     => eth_rxheader_data_s,
         out_eof_o      => eth_rxheader_eof_s(0)
      ); -- i_rx_header


   ------------------------------
   -- Instantiate rxfifo to cross clock domain
   ------------------------------

   i_rxfifo : entity work.fifo
      generic map (
         G_WIDTH => 8
      )
      port map (
         wr_clk_i   => eth_clk_i,
         wr_rst_i   => eth_rst_r,
         wr_en_i    => eth_rxheader_valid_s,
         wr_data_i  => eth_rxheader_data_s,
         wr_sb_i    => eth_rxheader_eof_s,
         wr_afull_o => eth_rxheader_afull_s,
         wr_error_o => open,  -- Ignored
         --
         rd_clk_i   => clk_i,
         rd_rst_i   => '0',
         rd_en_i    => rxfifo_rden_s,
         rd_data_o  => rxfifo_data_s,
         rd_sb_o    => rxfifo_eof_s,
         rd_empty_o => rxfifo_empty_s,
         rd_error_o => open   -- Ignored
      ); -- i_rxfifo


   ------------------------------
   -- Instantiate txfifo to cross clock domain
   ------------------------------

   i_txfifo : entity work.fifo
      generic map (
         G_WIDTH => 8
      )
      port map (
         wr_clk_i   => clk_i,
         wr_rst_i   => '0',
         wr_en_i    => txfifo_valid_s,
         wr_data_i  => txfifo_data_s,
         wr_sb_i    => txfifo_eof_s,
         wr_afull_o => txfifo_afull_s,
         wr_error_o => open,  -- Ignored
         rd_clk_i   => eth_clk_i,
         rd_rst_i   => eth_rst_r,
         rd_en_i    => eth_tx_rden_s,
         rd_data_o  => eth_tx_data_s,
         rd_sb_o    => eth_tx_eof_s,
         rd_empty_o => eth_tx_empty_s,
         rd_error_o => open   -- Ignored
      ); -- i_txfifo
   

   ------------------------------
   -- Instantiate Rx DMA
   ------------------------------

   i_rx_dma : entity work.rx_dma
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         addr_i       => addr_i(2 downto 0),
         wr_en_i      => wr_en_i,
         wr_data_i    => wr_data_i,
         rd_en_i      => rd_en_i,
         rd_data_o    => rx_rd_data_s,
         fifo_empty_i => rxfifo_empty_s,
         fifo_rd_en_o => rxfifo_rden_s,
         fifo_data_i  => rxfifo_data_s,
         fifo_eof_i   => rxfifo_eof_s(0)
      ); -- i_rx_dma


   ------------------------------
   -- Instantiate Tx DMA
   ------------------------------

   i_tx_dma : entity work.tx_dma
      port map (
         clk_i        => clk_i,
         rst_i        => rst_i,
         addr_i       => addr_i(2 downto 0),
         wr_en_i      => wr_en_i,
         wr_data_i    => wr_data_i,
         rd_en_i      => rd_en_i,
         rd_data_o    => tx_rd_data_s,
         --
         fifo_afull_i => txfifo_afull_s,
         fifo_valid_o => txfifo_valid_s,
         fifo_data_o  => txfifo_data_s,
         fifo_eof_o   => txfifo_eof_s(0)
      ); -- i_tx_dma


   rd_data_o <= rx_rd_data_s when addr_i(3) = '0' else tx_rd_data_s;


end structural;

