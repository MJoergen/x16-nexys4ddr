library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is the main YM2151 module
-- The single clock is the CPU clock.

entity ym2151 is
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      -- CPU interface
      addr_i    : in  std_logic_vector(0 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      -- Waveform output
      val_o     : out std_logic_vector(9 downto 0)
   );
end ym2151;

architecture structural of ym2151 is

   -- Register interface
   signal wr_addr_r : std_logic_vector(7 downto 0);

   type t_regs is array (0 to 255) of std_logic_vector(7 downto 0);
   signal regs_r : t_regs;

   -- Counter to control when to update the waveform (approx. 100 kHz).
   constant C_CNT_MAX : std_logic_vector(7 downto 0) := to_stdlogicvector(8333/100, 8);
   signal cnt_r : std_logic_vector(7 downto 0);

   -- Current waveform value
   signal val_r : std_logic_vector(9 downto 0);

begin

   ----------------------
   -- Write to registers
   ----------------------

   p_regs : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if wr_en_i = '1' then
            case addr_i is
               when "0" => 
                  wr_addr_r <= wr_data_i;
               when "1" => 
                  regs_r(to_integer(wr_addr_r)) <= wr_data_i;
               when others => null;
            end case;
         end if;
      end if;
   end process p_regs;


   ----------------------
   -- Counter
   ----------------------

   p_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cnt_r <= cnt_r + 1;
         if cnt_r = C_CNT_MAX then
            cnt_r <= (others => '0');
         end if;
      end if;
   end process p_cnt;


   ----------------------------------------------------
   -- Simple counter to produce a triangualer waveform
   ----------------------------------------------------

   p_val : process (clk_i)
   begin
      if rising_edge(clk_i) then
         if cnt_r = 0 then
            val_r <= val_r + 4;
         end if;
      end if;
   end process p_val;


   ----------------
   -- Drive output
   ----------------
   val_o <= val_r;

end architecture structural;

