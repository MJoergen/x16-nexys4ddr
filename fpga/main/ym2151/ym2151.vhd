library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

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
   -- Devices
   ------------

   type t_device is record
      total_level        : std_logic_vector(6 downto 0);
      detune1            : std_logic_vector(2 downto 0);
      detune2            : std_logic_vector(1 downto 0);
      phase_multiply     : std_logic_vector(3 downto 0);
      sensitivity_enable : std_logic;

      key_scale          : std_logic_vector(1 downto 0);
      attack_rate        : std_logic_vector(4 downto 0);
      first_decay_rate   : std_logic_vector(4 downto 0);
      second_decay_rate  : std_logic_vector(3 downto 0);
      release_rate       : std_logic_vector(3 downto 0);

      first_decay_level  : std_logic_vector(3 downto 0);
      key_code           : std_logic_vector(6 downto 0);
   end record t_device;

   constant C_DEVICE_DEFAULT : t_device := (
      total_level        => (others => '0'),
      detune1            => (others => '0'),
      detune2            => (others => '0'),
      phase_multiply     => (others => '0'),
      sensitivity_enable => '0',

      key_scale          => (others => '0'),
      attack_rate        => (others => '0'),
      first_decay_rate   => (others => '0'),
      second_decay_rate  => (others => '0'),
      release_rate       => (others => '0'),

      first_decay_level  => (others => '0'),
      key_code           => (others => '0')
   );

   type t_device_vector is array (natural range<>) of t_device;


   ------------
   -- Channels
   ------------

   type t_channel is record
      modulator1     : std_logic;
      carrier1       : std_logic;
      modulator2     : std_logic;
      carrier2       : std_logic;
      devices        : t_device_vector(3 downto 0);
      fb_shift       : std_logic_vector(2 downto 0);
      pm_sensitivity : std_logic_vector(2 downto 0);
      am_sensitivity : std_logic_vector(1 downto 0);
   end record t_channel;

   constant C_CHANNEL_DEFAULT : t_channel := (
      modulator1     => '0',
      carrier1       => '0',
      modulator2     => '0',
      carrier2       => '0',
      devices        => (others => C_DEVICE_DEFAULT),
      fb_shift       => (others => '0'),
      pm_sensitivity => (others => '0'),
      am_sensitivity => (others => '0')
   );

   type t_channel_vector is array (natural range<>) of t_channel;


   ------------
   -- Channels
   ------------

   type t_config is record
      channels  : t_channel_vector(7 downto 0);
      pm_depth  : std_logic_vector(6 downto 0);
      am_depth  : std_logic_vector(6 downto 0);
   end record t_config;

   constant C_CONFIG_DEFAULT : t_config := (
      channels => (others => C_CHANNEL_DEFAULT),
      pm_depth => (others => '0'),
      am_depth => (others => '0')
   );

   signal config_r : t_config := C_CONFIG_DEFAULT;


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


   -----------------
   -- Configuration
   -----------------

   p_config : process (clk_i)
      variable channel_v : integer;
      variable device_v : integer;
   begin
      if rising_edge(clk_i) then
         channel_v := to_integer(wr_data_r(2 downto 0));
         device_v  := to_integer(wr_data_r(4 downto 3));

         if wr_en_r = '1' then
            case wr_addr_r(7 downto 5) is
               when "000" => -- 0x00 - 0x1F
                  case wr_addr_r is
                     when X"08" => -- Key ON/OFF
                        config_r.channels(channel_v).modulator1 <= wr_data_r(3);
                        config_r.channels(channel_v).carrier1   <= wr_data_r(4);
                        config_r.channels(channel_v).modulator2 <= wr_data_r(5);
                        config_r.channels(channel_v).carrier2   <= wr_data_r(6);

                     when X"19" => -- Modulation depth
                        case wr_data_r(7) is
                           when '0' => config_r.am_depth <= wr_data_r(6 downto 0);
                           when '1' => config_r.pm_depth <= wr_data_r(6 downto 0);
                           when others => null;
                        end case;

                     when others => null;
                  end case;

               when "001" => -- 0x20 - 0x3F
                  -- TBD
                  case wr_addr_r(4 downto 3) is
                     when "00" => -- Channel control
                        config_r.channels(channel_v).fb_shift <= wr_data_r(5 downto 3);

                     when "01" => -- Key code
                        config_r.channels(channel_v).devices(0).key_code <= wr_data_r(6 downto 0);
                        config_r.channels(channel_v).devices(1).key_code <= wr_data_r(6 downto 0);
                        config_r.channels(channel_v).devices(2).key_code <= wr_data_r(6 downto 0);
                        config_r.channels(channel_v).devices(3).key_code <= wr_data_r(6 downto 0);

                     when "10" => -- Key fraction
                        -- TBD

                     when "11" => -- Modulation sensitivity
                        config_r.channels(channel_v).pm_sensitivity <= wr_data_r(6 downto 4);
                        config_r.channels(channel_v).am_sensitivity <= wr_data_r(1 downto 0);

                     when others => null;
                  end case;

               when "010" => -- 0x40 - 0x5F
                  config_r.channels(channel_v).devices(device_v).detune1            <= wr_data_r(6 downto 4);
                  config_r.channels(channel_v).devices(device_v).phase_multiply     <= wr_data_r(3 downto 0);

               when "011" => -- 0x60 - 0x7F
                  config_r.channels(channel_v).devices(device_v).total_level        <= wr_data_r(6 downto 0);

               when "100" => -- 0x80 - 0x9F
                  config_r.channels(channel_v).devices(device_v).key_scale          <= wr_data_r(7 downto 6);
                  config_r.channels(channel_v).devices(device_v).attack_rate        <= wr_data_r(4 downto 0);

               when "101" => -- 0xA0 - 0xBF
                  config_r.channels(channel_v).devices(device_v).sensitivity_enable <= wr_data_r(7);
                  config_r.channels(channel_v).devices(device_v).first_decay_rate   <= wr_data_r(4 downto 0);

               when "110" => -- 0xC0 - 0xDF
                  config_r.channels(channel_v).devices(device_v).detune2            <= wr_data_r(7 downto 6);
                  config_r.channels(channel_v).devices(device_v).second_decay_rate  <= wr_data_r(3 downto 0);

               when "111" => -- 0xE0 - 0xFF
                  config_r.channels(channel_v).devices(device_v).first_decay_level  <= wr_data_r(7 downto 4);
                  config_r.channels(channel_v).devices(device_v).release_rate       <= wr_data_r(3 downto 0);

               when others => null;
            end case;
         end if;
      end if;
   end process p_config;


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


   ----------------
   -- Drive output
   ----------------
   val_o <= val_r;

end architecture structural;

