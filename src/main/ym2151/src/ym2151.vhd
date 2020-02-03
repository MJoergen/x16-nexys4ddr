library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

use work.ym2151_package.all;

-- This is the main YM2151 module
-- The single clock is the CPU clock.
--
-- The register map is as follows (taken from http://www.cx5m.net/fmunit.htm)
-- 0x01        : Bit  1   : LFO reset
-- 0x08        : Key on.
--               Bit  6   : modulator 1
--               Bit  5   : carrier 1
--               Bit  4   : modulator 2
--               Bit  3   : carrier 2
--               Bits 2-0 : channel number
-- 0x0F        : Bit  7   : Noise enable
--               Bits 4-0 : Noise frequency
-- 0x11      ? : Timer A high
-- 0x12      ? : Timer A low
-- 0x13      ? : Timer B
-- 0x14        : Timer functions
-- 0x18        : Low oscillation frequency
-- 0x19        : Bit  7   : 0=Amplitude, 1=Phase
--               Bits 6-0 : Depth
-- 0x1B        : Control output and wave form select
--               Bit  7   : CT2
--               Bit  6   : CT1
--               Bits 1-0 : Wave form select (0=Saw, 1=Squared, 2=Triangle, 3=Noise)
-- 0x20        : Channel control
--               Bit  7   : RGT
--               Bit  6   : LFT
--               Bits 5-3 : FB
--               Bits 2-0 : CONNECT
-- 0x28 - 0x2F : Key code (bits 2-0 in address is channel number)
--             : Bits 7-4 : Octace
--             : Bits 3-0 : Note
-- 0x30 - 0x37 : Key fraction (bits 2-0 in address is channel number)
--             : Bits 7-2 : Key fraction
-- 0x38 - 0x3F : Modulation sensitivity (bits 2-0 in address is channel number)
--             : Bits 6-4 : PMS
--             : Bits 1-0 : AMS
-- 0x40 - 0x5F : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 6-4 : Detune(1)
--             : Bits 3-0 : Phase multiply
-- 0x60 - 0x7F : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 6-0 : Total level
-- 0x80 - 0x9F : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 7-6 : Key Scale
--             : Bits 4-0 : Attack rate
-- 0xA0 - 0xBF : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bit  7   : AM sensitivity enable
--             : Bits 4-0 : First decay rate
-- 0xC0 - 0xDF : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 7-6 : Detune(2)
--             : Bits 3-0 : Second decay rate
-- 0xE0 - 0xFF : (bits 2-0 in address is channel number, bits 4-3 in addresss is device)
--             : Bits 7-4 : First decay level
--             : Bits 3-0 : Release rate
-- Device: 0:Modulator1, 1:Modulator2, 2:Carrier1, 3:Carrier2

entity ym2151 is
   generic (
      G_CLOCK_HZ : integer := 8333333    -- Input clock frequency
   );
   port (
      clk_i     : in  std_logic;
      rst_i     : in  std_logic;
      -- CPU interface
      addr_i    : in  std_logic_vector(0 downto 0);
      wr_en_i   : in  std_logic;
      wr_data_i : in  std_logic_vector(7 downto 0);
      -- Waveform output
      val_o     : out std_logic_vector(C_PDM_WIDTH-1 downto 0)
   );
end ym2151;

architecture synthesis of ym2151 is

   -------------------------------------
   -- CPU interface
   -------------------------------------

   signal wr_addr_r : std_logic_vector(7 downto 0);
   signal wr_data_r : std_logic_vector(7 downto 0);
   signal wr_en_r   : std_logic;


   -------------------------------------
   -- Devices
   -------------------------------------

   signal device_cnt_r : integer range 0 to 31;

   signal devices_r    : t_device_vector(0 to 31);
   signal envelopes_s  : t_envelope_vector(0 to 31);
   signal phases_s     : t_phase_vector(0 to 31);


   signal exp_rom_addr_s : std_logic_vector(9 downto 0);
   signal exp_rom_data_s : std_logic_vector(9 downto 0);


   ------------
   -- Waveform
   ------------

   -- Counter to control when to update the waveform (approx. 100 kHz).
   constant C_CNT_MAX : std_logic_vector(7 downto 0) := to_stdlogicvector(8333/100, 8);
   signal cnt_r : std_logic_vector(7 downto 0);

   -- Current waveform value
   signal val_r : std_logic_vector(C_LOGSINE_ADDR_WIDTH-1 downto 0);

   -- Current waveform value
   signal logsine_s : std_logic_vector(C_LOGSINE_DATA_WIDTH-1 downto 0);

   -- Debug
   constant DEBUG_MODE               : boolean := false; -- TRUE OR FALSE

   attribute mark_debug              : boolean;
   attribute mark_debug of cnt_r     : signal is DEBUG_MODE;
   attribute mark_debug of val_r     : signal is DEBUG_MODE;
   attribute mark_debug of logsine_s : signal is DEBUG_MODE;

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


   -----------------
   -- Configuration
   -----------------

   p_config : process (clk_i)
      variable channel_v : integer;
      variable device_v : integer;
   begin
      if rising_edge(clk_i) then
         device_v  := to_integer(wr_data_r(4 downto 0));

         if wr_en_r = '1' then
            case wr_addr_r(7 downto 5) is
               when "000" => -- 0x00 - 0x1F
                  case wr_addr_r is
                     when X"08" => -- Key ON/OFF
                        devices_r(device_v).eg.key_onoff <= wr_data_r(3);
                        devices_r(device_v).eg.key_onoff <= wr_data_r(4);
                        devices_r(device_v).eg.key_onoff <= wr_data_r(5);
                        devices_r(device_v).eg.key_onoff <= wr_data_r(6);

                     when others => null;
                  end case;

               when "001" => -- 0x20 - 0x3F
                  case wr_addr_r(4 downto 3) is
                     when "01" => -- Key code
                        devices_r(device_v).pg.key_code <= wr_data_r(6 downto 0);

                     when others => null;
                  end case;

               when "011" => -- 0x60 - 0x7F
                  devices_r(device_v).eg.total_level        <= wr_data_r(6 downto 0);

               when "100" => -- 0x80 - 0x9F
                  devices_r(device_v).eg.attack_rate        <= wr_data_r(4 downto 0);

               when "101" => -- 0xA0 - 0xBF
                  devices_r(device_v).eg.first_decay_rate   <= wr_data_r(4 downto 0);

               when "110" => -- 0xC0 - 0xDF
                  devices_r(device_v).eg.second_decay_rate  <= wr_data_r(3 downto 0);

               when "111" => -- 0xE0 - 0xFF
                  devices_r(device_v).eg.first_decay_level  <= wr_data_r(7 downto 4);
                  devices_r(device_v).eg.release_rate       <= wr_data_r(3 downto 0);

               when others => null;
            end case;
         end if;

         if rst_i = '1' then
            devices_r <= (others => C_DEVICE_DEFAULT);
         end if;
      end if;
   end process p_config;


--    -------------------------------------
--    -- Cycle through the 32 devices
--    -------------------------------------
-- 
--    p_device_cnt : process (clk_i)
--    begin
--       if rising_edge(clk_i) then
--          device_cnt_r <= (device_cnt_r + 1) mod 32;
--          if rst_i = '1' then
--             device_cnt_r <= 0;
--          end if;
--       end if;
--    end process p_device_cnt;
-- 
-- 
--    -------------------------------------
--    -- Instantiate Phase Generators
--    -------------------------------------
-- 
--    i_phase_generator : entity work.phase_generator
--       generic map (
--          G_CLOCK_HZ => G_CLOCK_HZ
--       )
--       port map (
--          clk_i        => clk_i,
--          rst_i        => rst_i,
--          device_cnt_i => device_cnt_r,
--          devices_i    => devices_r,
--          phases_o     => phases_s
--       ); -- i_phase_generator
-- 
-- 
--    -------------------------------------
--    -- Instantiate Envelope Generator
--    -------------------------------------
-- 
--    i_envelope_generator : entity work.envelope_generator
--       generic map (
--          G_CLOCK_HZ => G_CLOCK_HZ
--       )
--       port map (
--          clk_i        => clk_i,
--          rst_i        => rst_i,
--          device_cnt_i => device_cnt_r,
--          devices_i    => devices_r,
--          envelopes_o  => envelopes_s
--       ); -- i_envelope_generator
-- 
-- 
--    exp_rom_addr_s <= phases_s(device_cnt_r)(19 downto 10) + envelopes_s(device_cnt_r);

   -------------------------------------
   -- Counter
   -------------------------------------

   p_cnt : process (clk_i)
   begin
      if rising_edge(clk_i) then
         cnt_r <= cnt_r + 1;
         if cnt_r = C_CNT_MAX then
            cnt_r <= (others => '0');
         end if;

         if rst_i = '1' then
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
         if rst_i = '1' then
            val_r <= (others => '0');
         end if;
      end if;
   end process p_val;


   --------------------------
   -- Instantiate sine table
   --------------------------

   i_logsine_rom : entity work.logsine_rom
      port map (
         clk_i  => clk_i,
         addr_i => val_r,
         data_o => logsine_s
      ); -- i_logsine_rom

   i_exp_rom : entity work.exp_rom
      port map (
         clk_i  => clk_i,
         addr_i => logsine_s,
         data_o => val_o(C_EXP_DATA_WIDTH-1 downto 0)
      ); -- i_exp_rom

end architecture synthesis;

