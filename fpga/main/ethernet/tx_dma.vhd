library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is a simple DMA.
-- It provides a simple CPU interface to a virtual buffer of 2 kB (0x0800).
-- The CPU register interface is as follows:
-- "000" : lo 
-- "001" : hi 
-- "010" : dat
-- "011" : own    0 : owned by CPU, 1 : owned by Ethernet module

entity tx_dma is
   generic (
      G_ADDR_BITS : integer := 11
   );
   port (
      -- Connected to CPU
      cpu_clk_i     : in  std_logic;
      cpu_rst_i     : in  std_logic;
      cpu_addr_i    : in  std_logic_vector(2 downto 0);
      cpu_wr_en_i   : in  std_logic;
      cpu_wr_data_i : in  std_logic_vector(7 downto 0);
      cpu_rd_en_i   : in  std_logic;
      cpu_rd_data_o : out std_logic_vector(7 downto 0);

      -- Connected to PHY
      eth_clk_i     : in  std_logic;
      eth_rst_i     : in  std_logic;
      eth_rd_en_i   : in  std_logic;
      eth_data_o    : out std_logic_vector(7 downto 0);
      eth_sb_o      : out std_logic;
      eth_empty_o   : out std_logic
   );
end tx_dma;

architecture structural of tx_dma is

   -- CPU clock domain
   signal cpu_addr_r      : std_logic_vector(15 downto 0);
   signal cpu_own_r       : std_logic;
   signal cpu_own_clear_s : std_logic;

   -- Dual Port RAM
   type mem_t is array (0 to 2**G_ADDR_BITS-1) of std_logic_vector(7 downto 0);
   signal mem_r : mem_t := (others => (others => '0'));

   -- ETH clock domain
   type t_eth_state is (IDLE_ST, LEN_LO_ST, LEN_HI_ST, DATA_ST, WAIT_ST);
   signal eth_state_r     : t_eth_state := IDLE_ST;
   signal eth_fifo_s      : std_logic_vector( 7 downto 0);
   signal eth_addr_r      : std_logic_vector(15 downto 0);
   signal eth_len_r       : std_logic_vector(15 downto 0);
   signal eth_own_s       : std_logic;
   signal eth_own_clear_r : std_logic;

begin

   ----------------------------------------------------------------------------------------------------
   -- CPU clock domain
   ----------------------------------------------------------------------------------------------------

   p_cpu : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         cpu_rd_data_o <= (others => '0');

         if cpu_wr_en_i = '1' then
            case cpu_addr_i is
               when "000" => cpu_addr_r( 7 downto 0) <= cpu_wr_data_i;
               when "001" => cpu_addr_r(15 downto 8) <= cpu_wr_data_i;
               when "010" => mem_r(to_integer(cpu_addr_r(G_ADDR_BITS-1 downto 0))) <= cpu_wr_data_i;
                             cpu_addr_r <= cpu_addr_r + 1;
               when "011" => cpu_own_r               <= cpu_wr_data_i(0);
               when others => null;
            end case;
         end if;

         if cpu_rd_en_i = '1' then
            case cpu_addr_i is
               when "000" => cpu_rd_data_o <= cpu_addr_r( 7 downto 0);
               when "001" => cpu_rd_data_o <= cpu_addr_r(15 downto 8);
               when "010" => cpu_rd_data_o <= mem_r(to_integer(cpu_addr_r(G_ADDR_BITS-1 downto 0)));
                             cpu_addr_r    <= cpu_addr_r + 1;
               when "011" => cpu_rd_data_o(0) <= cpu_own_r;
               when others => null;
            end case;
         end if;
         
         if cpu_own_clear_s = '1' then
            cpu_own_r <= '0';
         end if;
         
         if cpu_rst_i = '1' then
            cpu_addr_r <= (others => '0');
            cpu_own_r  <= '0';
         end if;
      end if;
   end process p_cpu;


   ----------------------------------------------------------------------------------------------------
   -- Clock Domain Crossing
   ----------------------------------------------------------------------------------------------------

   i_cdc_own : entity work.cdc
      generic map (
         G_SIZE => 1
      )
      port map (
         src_clk_i => cpu_clk_i,
         src_dat_i(0) => cpu_own_r,
         dst_clk_i => eth_clk_i,
         dst_dat_o(0) => eth_own_s
      ); -- i_cdc_own

   i_cdc_own_clear : entity work.cdc
      generic map (
         G_SIZE => 1
      )
      port map (
         src_clk_i => eth_clk_i,
         src_dat_i(0) => eth_own_clear_r,
         dst_clk_i => cpu_clk_i,
         dst_dat_o(0) => cpu_own_clear_s
      ); -- i_cdc_own_clear


   ----------------------------------------------------------------------------------------------------
   -- ETH clock domain
   ----------------------------------------------------------------------------------------------------

   eth_fifo_s <= mem_r(to_integer(eth_addr_r(G_ADDR_BITS-1 downto 0)));

   p_eth : process (eth_clk_i)
   begin
      if rising_edge(eth_clk_i) then
         eth_empty_o <= '1';

         case eth_state_r is
            when IDLE_ST =>
               if eth_own_s = '1' then
                  eth_addr_r  <= (others => '0');
                  eth_state_r <= LEN_LO_ST;
               end if;

            when LEN_LO_ST =>
               eth_len_r(7 downto 0) <= eth_fifo_s;
               eth_addr_r  <= eth_addr_r + 1;
               eth_state_r <= LEN_HI_ST;

            when LEN_HI_ST =>
               eth_len_r(15 downto 8) <= eth_fifo_s;
               eth_addr_r  <= eth_addr_r + 1;
               eth_state_r <= DATA_ST;

            when DATA_ST =>
               eth_sb_o    <= '0';
               eth_data_o  <= eth_fifo_s;
               eth_empty_o <= '0';

               if eth_len_r = 1 then
                  eth_sb_o <= '1';
               end if;

               if eth_rd_en_i = '1' then
                  eth_addr_r  <= eth_addr_r + 1;
                  eth_len_r   <= eth_len_r - 1;
                  if eth_len_r = 1 then
                     eth_own_clear_r <= '1';
                     eth_state_r     <= WAIT_ST;
                  end if;
               end if;

            when WAIT_ST =>
               if eth_own_s = '0' then
                  eth_own_clear_r <= '0';
                  eth_state_r     <= IDLE_ST;
               end if;
         end case;

         if eth_rst_i= '1' then
            eth_sb_o        <= '0';
            eth_empty_o     <= '1';
            eth_len_r       <= (others => '0');
            eth_addr_r      <= (others => '0');
            eth_own_clear_r <= '0';
            eth_state_r     <= IDLE_ST;
         end if;

      end if;
   end process p_eth;

end structural;

