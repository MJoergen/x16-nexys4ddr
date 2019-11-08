library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- A VERY basic implementation of the VIA 6522 chip.
-- Currently, it only suppors the two general purpose
-- I/O ports, as well as the free-running timer 1.

entity via is
   port (
      clk_i     : in    std_logic;
      rst_i     : in    std_logic;
      addr_i    : in    std_logic_vector(3 downto 0);
      wr_en_i   : in    std_logic;
      wr_data_i : in    std_logic_vector(7 downto 0);
      rd_en_i   : in    std_logic;
      rd_data_o : out   std_logic_vector(7 downto 0);
      porta_io  : inout std_logic_vector(7 downto 0);
      portb_io  : inout std_logic_vector(7 downto 0)
   );
end via;

architecture structural of via is

   signal porta_r  : std_logic_vector( 7 downto 0);
   signal portb_r  : std_logic_vector( 7 downto 0);
   signal dira_r   : std_logic_vector( 7 downto 0);  -- 0 means input, 1 means output
   signal dirb_r   : std_logic_vector( 7 downto 0);
   signal timer1_r : std_logic_vector(15 downto 0);

begin

   ------------------------
   -- Write from processor
   ------------------------

   p_write : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_i = '1' then
            case addr_i is
               when "0000" => portb_r <= wr_data_i;
               when "0001" => porta_r <= wr_data_i;
               when "0010" => dirb_r  <= wr_data_i;
               when "0011" => dira_r  <= wr_data_i;
               when others => null;
            end case;
         end if;

         timer1_r <= timer1_r - 1;
         
         if rst_i = '1' then
            porta_r  <= (others => '0');
            portb_r  <= (others => '0');
            dira_r   <= (others => '1');  -- TBD !!
            dirb_r   <= (others => '1');  -- TBD !!
            timer1_r <= (others => '0');
         end if;
      end if;
   end process p_write;


   ------------------------
   -- Read from processor
   ------------------------

   p_read : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if rd_en_i = '1' then
            case addr_i is
               when "0000" => rd_data_o <= portb_io;
               when "0001" => rd_data_o <= porta_io;
               when "0010" => rd_data_o <= dirb_r;
               when "0011" => rd_data_o <= dira_r;
               when "0100" => rd_data_o <= timer1_r(7 downto 0);
               when "0101" => rd_data_o <= timer1_r(15 downto 8);
               when others => rd_data_o <= (others => '0');
            end case;
         end if;
      end if;
   end process p_read;


   --------------------------
   -- Generate output driver
   --------------------------

   gen_out : for i in 7 downto 0 generate
      porta_io(i) <= porta_r(i) when dira_r(i) = '1' else 'Z';
      portb_io(i) <= portb_r(i) when dirb_r(i) = '1' else 'Z';
   end generate gen_out;

end architecture structural;

