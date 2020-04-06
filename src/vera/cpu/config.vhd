library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This block handles all the configuration settings of the VERA,
-- i.e. everything other than the internal memory map.
--
-- TBD: Currently, only MAP and TILE area base addresses are supported.

-- VERA_ADDRx_L      = $9F20
-- VERA_ADDRx_M      = $9F21
-- VERA_ADDRx_H      = $9F22
-- VERA_DATA0        = $9F23
-- VERA_DATA1        = $9F24
-- VERA_CTRL         = $9F25
-- VERA_IEN          = $9F26
-- VERA_ISR          = $9F27
-- VERA_IRQLINE_L    = $9F28
-- VERA_DC_VIDEO     = $9F29 ; DCSEL=0
-- VERA_DC_HSCALE    = $9F2A ; DCSEL=0
-- VERA_DC_VSCALE    = $9F2B ; DCSEL=0
-- VERA_DC_BORDER    = $9F2C ; DCSEL=0
-- VERA_DC_HSTART    = $9F29 ; DCSEL=1
-- VERA_DC_HSTOP     = $9F2A ; DCSEL=1
-- VERA_DC_VSTART    = $9F2B ; DCSEL=1
-- VERA_DC_VSTOP     = $9F2C ; DCSEL=1
-- VERA_L0_CONFIG    = $9F2D
-- VERA_L0_MAPBASE   = $9F2E
-- VERA_L0_TILEBASE  = $9F2F
-- VERA_L0_HSCROLL_L = $9F30
-- VERA_L0_HSCROLL_H = $9F31
-- VERA_L0_VSCROLL_L = $9F32
-- VERA_L0_VSCROLL_H = $9F33
-- VERA_L1_CONFIG    = $9F34
-- VERA_L1_MAPBASE   = $9F35
-- VERA_L1_TILEBASE  = $9F36
-- VERA_L1_HSCROLL_L = $9F37
-- VERA_L1_HSCROLL_H = $9F38
-- VERA_L1_VSCROLL_L = $9F39
-- VERA_L1_VSCROLL_H = $9F3A
-- VERA_AUDIO_CTRL   = $9F3B
-- VERA_AUDIO_RATE   = $9F3C
-- VERA_AUDIO_DATA   = $9F3D (write only)
-- VERA_SPI_DATA     = $9F3E
-- VERA_SPI_CTRL     = $9F3F

-- Internal memory map:
-- $00000 - $1F9BF   Video RAM
-- $1F9C0 - $1F9FF   PSG registers
-- $1FA00 - $1FBFF   Palette
-- $1FC00 - $1FFFF   Sprite attributes

entity config is
   port (
      -- CPU interface
      clk_i              : in  std_logic;
      rst_i              : in  std_logic;
      addr_i             : in  std_logic_vector(4 downto 0);
      wr_en_i            : in  std_logic;
      wr_data_i          : in  std_logic_vector(7 downto 0);
      rd_en_i            : in  std_logic;
      rd_data_o          : out std_logic_vector(7 downto 0);
      irq_o              : out std_logic;

      -- Video RAM
      vram_addr_o        : out std_logic_vector(16 downto 0);
      vram_wr_en_o       : out std_logic;
      vram_wr_data_o     : out std_logic_vector( 7 downto 0);
      vram_rd_data_i     : in  std_logic_vector( 7 downto 0);

      -- palette RAM
      pal_addr_o         : out std_logic_vector( 8 downto 0);
      pal_wr_en_o        : out std_logic;
      pal_wr_data_o      : out std_logic_vector( 7 downto 0);
      pal_rd_data_i      : in  std_logic_vector( 7 downto 0);

      -- VERA configuration
      ctrl_o             : out std_logic_vector(7 downto 0);
      irq_line_o         : out std_logic_vector(8 downto 0);

      -- Interrupt sources
      irq_i              : in  std_logic_vector(3 downto 0);

      -- Display composer
      dc_video_o         : out std_logic_vector(7 downto 0);
      dc_hscale_o        : out std_logic_vector(7 downto 0);
      dc_vscale_o        : out std_logic_vector(7 downto 0);
      dc_border_o        : out std_logic_vector(7 downto 0);
      dc_hstart_o        : out std_logic_vector(7 downto 0);
      dc_hstop_o         : out std_logic_vector(7 downto 0);
      dc_vstart_o        : out std_logic_vector(7 downto 0);
      dc_vstop_o         : out std_logic_vector(7 downto 0);

      -- Layer 0
      l0_config_o        : out std_logic_vector(7 downto 0);
      l0_mapbase_o       : out std_logic_vector(7 downto 0);
      l0_tilebase_o      : out std_logic_vector(7 downto 0);
      l0_hscroll_o       : out std_logic_vector(11 downto 0);
      l0_vscroll_o       : out std_logic_vector(11 downto 0);

      -- Layer 1
      l1_config_o        : out std_logic_vector(7 downto 0);
      l1_mapbase_o       : out std_logic_vector(7 downto 0);
      l1_tilebase_o      : out std_logic_vector(7 downto 0);
      l1_hscroll_o       : out std_logic_vector(11 downto 0);
      l1_vscroll_o       : out std_logic_vector(11 downto 0);

      -- Audio
      audio_ctrl_o       : out std_logic_vector(7 downto 0);
      audio_rate_o       : out std_logic_vector(7 downto 0);
      audio_data_o       : out std_logic_vector(7 downto 0);

      -- SPI
      spi_data_o         : out std_logic_vector(7 downto 0);
      spi_ctrl_o         : out std_logic_vector(7 downto 0)
   );
end config;

architecture synthesis of config is

   type CONFIG_t is array (0 to 31) of std_logic_vector(7 downto 0);
   signal config_r         : CONFIG_t := (others => (others => '0'));

   type ADDRESS_t is array (0 to 1) of std_logic_vector(23 downto 0);
   signal address_r        : ADDRESS_t := (others => (others => '0'));

   type COMPOSER_t is array (0 to 7) of std_logic_vector(7 downto 0);
   signal composer_r       : COMPOSER_t := (others => (others => '0'));

   signal config_rd_data_r : std_logic_vector(7 downto 0);

   signal isr_r            : std_logic_vector(7 downto 0);

   alias addrsel_a         : std_logic_vector(0 downto 0) is config_r(5)(0 downto 0);
   alias dcsel_a           : std_logic_vector(0 downto 0) is config_r(5)(1 downto 1);

   signal internal_addr_s  : std_logic_vector(16 downto 0);
   signal internal_cs_s    : std_logic;
   signal internal_wr_en_s : std_logic;

   signal pal_cs_s         : std_logic;

   -- Convert the 4-bit increment setting to a 17-bit increment value.
   function get_increment(arg : std_logic_vector) return std_logic_vector is
      variable idx  : integer range 0 to 15;
      variable decr : integer range 0 to 1;
      variable res  : std_logic_vector(16 downto 0);
   begin
      idx  := to_integer(arg) / 2;
      decr := to_integer(arg) mod 2;

      res := (others => '0');
      case idx is
         when  0 => res := to_stdlogicvector(  0, 17);
         when  1 => res := to_stdlogicvector(  1, 17);
         when  2 => res := to_stdlogicvector(  2, 17);
         when  3 => res := to_stdlogicvector(  4, 17);
         when  4 => res := to_stdlogicvector(  8, 17);
         when  5 => res := to_stdlogicvector( 16, 17);
         when  6 => res := to_stdlogicvector( 32, 17);
         when  7 => res := to_stdlogicvector( 64, 17);
         when  8 => res := to_stdlogicvector(128, 17);
         when  9 => res := to_stdlogicvector(256, 17);
         when 10 => res := to_stdlogicvector(512, 17);
         when 11 => res := to_stdlogicvector( 40, 17);
         when 12 => res := to_stdlogicvector( 80, 17);
         when 13 => res := to_stdlogicvector(160, 17);
         when 14 => res := to_stdlogicvector(320, 17);
         when 15 => res := to_stdlogicvector(640, 17);
      end case;

      if decr = 1 then
         return (not res) + 1;
      else
         return res;
      end if;
   end function get_increment;

begin

   p_config : process (clk_i)
      variable isr_v : std_logic_vector(7 downto 0);
   begin
      if rising_edge(clk_i) then
         isr_v := isr_r;

         if wr_en_i = '1' then
            config_r(to_integer(addr_i)) <= wr_data_i;

            case to_integer(addr_i) is
               when 0 =>
                  address_r(to_integer(addrsel_a))(7 downto 0) <= wr_data_i;

               when 1 =>
                  address_r(to_integer(addrsel_a))(15 downto 8) <= wr_data_i;

               when 2 =>
                  address_r(to_integer(addrsel_a))(23 downto 16) <= wr_data_i;

               when 3 =>
                  address_r(0)(16 downto 0) <= address_r(0)(16 downto 0)
                     + get_increment(address_r(0)(23 downto 19));

               when 4 =>
                  address_r(1)(16 downto 0) <= address_r(1)(16 downto 0)
                     + get_increment(address_r(1)(23 downto 19));

               when others =>
                  null;
            end case;

            if addr_i >= 9 and addr_i <= 12 then
               composer_r(to_integer(addr_i)-9 + 4*to_integer(dcsel_a)) <= wr_data_i;
            end if;

            if addr_i = 7 then
               isr_v := isr_v and not wr_data_i;
            end if;
         end if;

         if rd_en_i = '1' then
            config_rd_data_r <= config_r(to_integer(addr_i));

            case to_integer(addr_i) is
               when 0 =>
                  config_rd_data_r <= address_r(to_integer(addrsel_a))(7 downto 0);

               when 1 =>
                  config_rd_data_r <= address_r(to_integer(addrsel_a))(15 downto 8);

               when 2 =>
                  config_rd_data_r <= address_r(to_integer(addrsel_a))(23 downto 16);

               when 3 =>
                  address_r(0)(16 downto 0) <= address_r(0)(16 downto 0)
                     + get_increment(address_r(0)(23 downto 19));

               when 4 =>
                  address_r(1)(16 downto 0) <= address_r(1)(16 downto 0)
                     + get_increment(address_r(1)(23 downto 19));

               when others =>
                  null;
            end case;

            if addr_i >= 9 and addr_i <= 12 then
               config_rd_data_r <= composer_r(to_integer(addr_i)-9 + 4*to_integer(dcsel_a));
            end if;

            if addr_i = 7 then
               config_rd_data_r <= isr_r;
            end if;
         end if;

         isr_r(3 downto 0) <= isr_v(3 downto 0) or irq_i;
      end if;
   end process p_config;

   ctrl_o        <= config_r(5);
   irq_line_o    <= config_r(6)(7) & config_r(8);

   dc_video_o    <= composer_r(0);
   dc_hscale_o   <= composer_r(1);
   dc_vscale_o   <= composer_r(2);
   dc_border_o   <= composer_r(3);
   dc_hstart_o   <= composer_r(4);
   dc_hstop_o    <= composer_r(5);
   dc_vstart_o   <= composer_r(6);
   dc_vstop_o    <= composer_r(7);

   l0_config_o   <= config_r(13);
   l0_mapbase_o  <= config_r(14);
   l0_tilebase_o <= config_r(15);
   l0_hscroll_o  <= config_r(17)(3 downto 0) & config_r(16);
   l0_vscroll_o  <= config_r(19)(3 downto 0) & config_r(18);

   l1_config_o   <= config_r(20);
   l1_mapbase_o  <= config_r(21);
   l1_tilebase_o <= config_r(22);
   l1_hscroll_o  <= config_r(24)(3 downto 0) & config_r(23);
   l1_vscroll_o  <= config_r(26)(3 downto 0) & config_r(25);

   audio_ctrl_o  <= config_r(27);
   audio_rate_o  <= config_r(28);
   audio_data_o  <= config_r(29);

   spi_data_o    <= config_r(30);
   spi_ctrl_o    <= config_r(31);


-- Internal memory map:
-- $00000 - $1F9BF   Video RAM
-- $1F9C0 - $1F9FF   PSG registers
-- $1FA00 - $1FBFF   Palette
-- $1FC00 - $1FFFF   Sprite attributes

   internal_addr_s  <= address_r(to_integer(addrsel_a))(16 downto 0);
   internal_cs_s    <= '1' when addr_i = 3 or addr_i = 4 else '0';
   internal_wr_en_s <= wr_en_i and internal_cs_s;

   -- Access Video RAM
   vram_addr_o    <= internal_addr_s(16 downto 0);
   vram_wr_en_o   <= internal_wr_en_s;
   vram_wr_data_o <= wr_data_i;

   -- Access palette RAM
   pal_addr_o    <= internal_addr_s(8 downto 0);
   pal_cs_s      <= internal_cs_s when internal_addr_s(16 downto 9) = "11111101" else '0';
   pal_wr_en_o   <= internal_wr_en_s and pal_cs_s;
   pal_wr_data_o <= wr_data_i;

   -- Multiplex CPU read
   rd_data_o <= pal_rd_data_i  when pal_cs_s      = '1' else
                vram_rd_data_i when internal_cs_s = '1' else   -- Must be after PAL
                config_rd_data_r;

   irq_o <= or (config_r(6) and isr_r);

end architecture synthesis;

