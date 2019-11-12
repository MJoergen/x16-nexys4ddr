library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This module pretends to be a keyboard, writing to the MAIN module.

-- A clock period is at least 2*30 microseconds. Each microsecond contains
-- 8.33 clock cycles, so half a period is 30*8.33 = approx 256 clock cycles.

-- I'm following the diagram on page 18 of the document: http://www.mcamafia.de/pdf/ibm_hitrc07.pdf

entity ps2_writer is
   port (
      clk_i        : in  std_logic;
      rst_i        : in  std_logic;
      -- Conneted internally
      data_i       : in  std_logic_vector(10 downto 0);
      valid_i      : in  std_logic;
      ready_o      : out std_logic;
      -- Connected to MAIN module
      ps2_clk_o    : out std_logic;
      ps2_clk_i    : in  std_logic;
      ps2_clken_i  : in  std_logic;
      ps2_data_o   : out std_logic;
      ps2_data_i   : in  std_logic;
      ps2_dataen_i : in  std_logic
   );
end ps2_writer;

architecture structural of ps2_writer is
   
   signal ps2_clk   : std_logic;
   signal ps2_data  : std_logic;

   signal data      : std_logic_vector(10 downto 0);
   signal counter   : integer range 0 to 11;

   signal usec_up   : std_logic_vector(2 downto 0);   -- 8 clock cycles
   signal usecs     : std_logic_vector(7 downto 0);   -- Free running timer
   signal usec_next : std_logic_vector(7 downto 0);   -- Time for next event

   type state_t is (IDLE_ST, T1_ST, T2_ST, T3_ST);
   signal state : state_t;

begin

   -- Ready to receive new data, when not transmitting.
   ready_o   <= '1' when state = IDLE_ST else '0';


   ps2_clk  <= ps2_clk_o when ps2_clken_i = '0' else
               ps2_clk_o and ps2_clk_i;

   ps2_data <= ps2_data_o when ps2_dataen_i = '0' else
               ps2_data_o and ps2_data_i;


   p_fsm : process (clk_i)
   begin
      if rising_edge(clk_i) then
         case state is
            when IDLE_ST =>
               if ps2_clk = '1' and ps2_data = '1' and   -- May we send?
                  valid_i = '1' and ready_o = '1' then   -- Is there data to send?

                  data      <= data_i;                  -- Consume input data
                  counter   <= 11;       
                  usec_next <= usecs + 1;
                  state     <= T2_ST;
               end if;

            when T1_ST =>
               if usecs = usec_next then
                  ps2_clk_o <= '0';
                  usec_next <= usecs + 40;
                  state     <= T3_ST;
               end if;

            when T3_ST =>
               if usecs = usec_next then
                  ps2_clk_o <= '1';
                  usec_next <= usecs + 20;
                  state     <= T2_ST;
               end if;

            when T2_ST =>
               if usecs = usec_next then
                  if counter > 0 and ps2_clk = '1' then
                     ps2_data_o <= data(0);                 -- Send next bit
                     data       <= '1' & data(10 downto 1);
                     usec_next  <= usecs + 20;
                     state      <= T1_ST;
                     counter    <= counter - 1;
                  end if;
                  if counter = 0 and ps2_clk = '1' then
                     state      <= IDLE_ST;
                  end if;
               end if;
         end case;

         if rst_i = '1' then
            state      <= IDLE_ST;
            counter    <= 0;
            ps2_data_o <= '1';
            ps2_clk_o  <= '1';
         end if;
      end if;
   end process p_fsm;


   p_usec : process (clk_i)
   begin
      if rising_edge(clk_i) then
         usec_up <= usec_up + 1;
         if usec_up = 0 then
            usecs <= usecs + 1;
         end if;

         if rst_i = '1' then
            usecs   <= (others => '0');
            usec_up <= "000";
         end if;
      end if;
   end process p_usec;

end structural;

