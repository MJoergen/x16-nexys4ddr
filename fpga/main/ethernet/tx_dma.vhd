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
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;

      -- Connected to CPU
      addr_i       : in  std_logic_vector(2 downto 0);
      wr_en_i      : in  std_logic;
      wr_data_i    : in  std_logic_vector(7 downto 0);
      rd_en_i      : in  std_logic;
      rd_data_o    : out std_logic_vector(7 downto 0);

      -- Connected to Tx FIFO
      fifo_afull_i : in  std_logic;
      fifo_valid_o : out std_logic;
      fifo_data_o  : out std_logic_vector( 7 downto 0);
      fifo_eof_o   : out std_logic
   );
end tx_dma;

architecture structural of tx_dma is

   signal cpu_addr_r  : std_logic_vector(15 downto 0);
   signal fifo_addr_r : std_logic_vector(15 downto 0);
   signal own_r       : std_logic;
   signal own_clear_r : std_logic;
   signal len_r       : std_logic_vector(15 downto 0);
   signal mem_fifo_s  : std_logic_vector( 7 downto 0);

   type mem_t is array (0 to 2**G_ADDR_BITS-1) of std_logic_vector(7 downto 0);

   signal mem_r : mem_t := (others => (others => '0'));

   -- State machine to control the MAC framing
   type t_fsm_state is (IDLE_ST, LEN_LO_ST, LEN_HI_ST, DATA_ST);
   signal fsm_state : t_fsm_state := IDLE_ST;

begin

   ------------------------
   -- CPU access
   ------------------------

   p_cpu : process (clk_i)
   begin
      if rising_edge(clk_i) then
         rd_data_o <= (others => '0');

         if wr_en_i = '1' then
            case addr_i is
               when "000" => cpu_addr_r( 7 downto 0) <= wr_data_i;
               when "001" => cpu_addr_r(15 downto 8) <= wr_data_i;
               when "010" => mem_r(to_integer(cpu_addr_r(G_ADDR_BITS-1 downto 0))) <= wr_data_i;
                             cpu_addr_r <= cpu_addr_r + 1;
               when "011" => own_r                   <= wr_data_i(0);
               when others => null;
            end case;
         end if;

         if rd_en_i = '1' then
            case addr_i is
               when "000" => rd_data_o <= cpu_addr_r( 7 downto 0);
               when "001" => rd_data_o <= cpu_addr_r(15 downto 8);
               when "010" => rd_data_o <= mem_r(to_integer(cpu_addr_r(G_ADDR_BITS-1 downto 0)));
                             cpu_addr_r <= cpu_addr_r + 1;
               when "011" => rd_data_o(0) <= own_r;
               when others => null;
            end case;
         end if;
         
         if own_clear_r = '1' then
            own_r <= '0';
         end if;
         
         if rst_i = '1' then
            cpu_addr_r <= (others => '0');
            own_r      <= '0';
         end if;
      end if;
   end process p_cpu;

   mem_fifo_s <= mem_r(to_integer(fifo_addr_r(G_ADDR_BITS-1 downto 0)));


   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then

         -- Default values
         own_clear_r  <= '0';

         -- Connected to Tx FIFO
         fifo_valid_o <= '0';
         fifo_data_o  <= (others => '0');
         fifo_eof_o   <= '0';

         case fsm_state is
            when IDLE_ST =>
               if own_r = '1' then
                  fifo_addr_r <= (others => '0');
                  fsm_state <= LEN_LO_ST;
               end if;

            when LEN_LO_ST =>
               len_r(7 downto 0) <= mem_fifo_s;
               fifo_addr_r       <= fifo_addr_r + 1;
               fsm_state         <= LEN_HI_ST;

            when LEN_HI_ST =>
               len_r(15 downto 8) <= mem_fifo_s;
               fifo_addr_r        <= fifo_addr_r + 1;
               fsm_state          <= DATA_ST;

            when DATA_ST =>
               if len_r /= 0 then
                  fifo_data_o  <= mem_fifo_s;
                  fifo_valid_o <= '1';
                  fifo_addr_r  <= fifo_addr_r + 1;
                  len_r        <= len_r - 1;

                  if len_r = 1 then
                     fifo_eof_o  <= '1';
                     own_clear_r <= '1';
                     fsm_state   <= IDLE_ST;
                  end if;
               else
                  fsm_state <= IDLE_ST;
               end if;
         end case;

         if rst_i = '1' then
            own_clear_r  <= '0';
            fifo_valid_o <= '0';
            fsm_state    <= IDLE_ST;
         end if;
      end if;
   end process p_fsm;


end structural;

