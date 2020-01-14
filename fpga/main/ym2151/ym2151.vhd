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

   -----------------
   -- CPU interface
   -----------------

   signal wr_addr_r : std_logic_vector(7 downto 0);
   signal wr_data_r : std_logic_vector(7 downto 0);
   signal wr_en_r   : std_logic;


   ------------
   -- Channels
   ------------

   type t_channel is record
      m1 : std_logic;
      c1 : std_logic;
      m2 : std_logic;
      c2 : std_logic;
   end record t_channel;

   constant C_CHANNEL_DEFAULT : t_channel := (
      m1 => '0',
      c1 => '0',
      m2 => '0',
      c2 => '0'
   );

   type t_channel_vector is array (natural range<>) of t_channel;
   signal channels : t_channel_vector(7 downto 0) := (others => C_CHANNEL_DEFAULT);


   ------------
   -- Waveform
   ------------

   -- Counter to control when to update the waveform (approx. 100 kHz).
   constant C_CNT_MAX : std_logic_vector(7 downto 0) := to_stdlogicvector(8333/100, 8);
   signal cnt_r : std_logic_vector(7 downto 0);

   -- Current waveform value
   signal val_r : std_logic_vector(9 downto 0);

begin

   ----------------------
   -- CPU interface
   ----------------------

   p_regs : process (clk_i)
   begin
      if rising_edge(clk_i) then
         wr_en_r <= '0';
         if wr_en_i = '1' then
            case addr_i is
               when "0" => 
                  wr_addr_r <= wr_data_i;
               when "1" => 
                  wr_data_r <= wr_data_i;
                  wr_en_r   <= '1';
               when others => null;
            end case;
         end if;
      end if;
   end process p_regs;


   ----------------------
   -- Channels
   ----------------------

   p_channels : process (clk_i)
      variable channel_v : integer;
   begin
      if rising_edge(clk_i) then
         channel_v := to_integer(wr_data_r(2 downto 0));
         if wr_en_r = '1' then
            case wr_addr_r is
               when X"08" => -- Key ON/OFF
                  channels(channel_v).m1 <= wr_data_r(3);
                  channels(channel_v).c1 <= wr_data_r(4);
                  channels(channel_v).m2 <= wr_data_r(5);
                  channels(channel_v).c2 <= wr_data_r(6);

               when others => null;
            end case;
         end if;
      end if;
   end process p_channels;


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

