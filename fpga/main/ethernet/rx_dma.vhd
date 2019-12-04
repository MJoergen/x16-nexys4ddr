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

entity rx_dma is
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

      -- Connected to Rx FIFO
      fifo_empty_i : in  std_logic;
      fifo_rd_en_o : out std_logic;
      fifo_data_i  : in  std_logic_vector(7 downto 0);
      fifo_eof_i   : in  std_logic
   );
end rx_dma;

architecture structural of rx_dma is

   signal cpu_addr_r  : std_logic_vector(15 downto 0);
   signal fifo_addr_r : std_logic_vector(15 downto 0);
   signal own_r       : std_logic;
   signal own_clear_r : std_logic;

   type mem_t is array (0 to 2**G_ADDR_BITS-1) of std_logic_vector(7 downto 0);

   signal mem_r : mem_t := (others => (others => '0'));

   type state_t is (IDLE_ST, DATA_ST, WAIT_ST);
   signal state : state_t := IDLE_ST;

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
--               when "010" => mem_r(to_integer(cpu_addr_r(G_ADDR_BITS-1 downto 0))) <= wr_data_i;
--                             cpu_addr_r <= cpu_addr_r + 1;
               when "011" => own_r                   <= wr_data_i(0);
               when others => null;
            end case;
         end if;

         if wr_en_i = '1' then
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


   p_fsm : process(clk_i)
   begin
      if rising_edge(clk_i) then

         -- Default values
         fifo_rd_en_o <= '0';
         own_clear_r  <= '0';

         case state is
            when IDLE_ST =>
               if own_r = '1' and fifo_empty_i = '0' then
                  fifo_addr_r <= (others => '0');
                  state       <= DATA_ST;
               end if;

            when DATA_ST =>
               if fifo_empty_i = '0' and fifo_rd_en_o = '0' then
                  fifo_rd_en_o <= '1';
                  mem_r(to_integer(fifo_addr_r)) <= fifo_data_i;
                  fifo_addr_r <= fifo_addr_r + 1;

                  if fifo_eof_i = '1' then
                     own_clear_r <= '1';
                     state       <= WAIT_ST;
                  end if;
               end if;

            when WAIT_ST =>
               if own_r = '0' then
                  own_clear_r <= '0';
                  state     <= IDLE_ST;
               end if;

         end case;

         if rst_i = '1' then
            fifo_rd_en_o <= '0';
            own_clear_r  <= '0';
            state        <= IDLE_ST;
         end if;
      end if;
   end process p_fsm;


end structural;

