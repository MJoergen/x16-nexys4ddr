library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This module models a single-port asynchronous RAM.
--
-- Note: Both read and write occurs on the *falling* edge of
-- the clock cycle. This is to allow the 65C02 to read asynchronously.

entity ram is
   generic (
      G_ADDR_BITS : integer
   );
   port (
      clk_i     : in  std_logic;
      addr_i    : in  std_logic_vector(G_ADDR_BITS-1 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      rd_en_i   : in  std_logic;
      rd_data_o : out std_logic_vector(7 downto 0)
   );
end ram;

architecture structural of ram is

   type mem_t is array (0 to 2**G_ADDR_BITS-1) of std_logic_vector(7 downto 0);

   -- Initialize memory contents
   signal mem_r : mem_t := (others => (others => '0'));

begin

   p_write : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_i = '1' then
            mem_r(to_integer(addr_i)) <= wr_data_i;
         end if;
      end if;
   end process p_write;

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if rd_en_i = '1' then
            rd_data_o <= mem_r(to_integer(addr_i));
         end if;
      end if;
   end process p_read;

end structural;

