library ieee;
use ieee.std_logic_1164.all;

-- This is the top level module of the X16. The ports on this entity are mapped
-- directly to pins on the FPGA.
--
-- Signal names are prefixed by the corresponding clock domain.

entity x16 is
   port (
      clk_i       : in    std_logic;                       -- 100 MHz

      rstn_i      : in    std_logic;                       -- CPU reset, active low

      sw_i        : in    std_logic_vector(15 downto 0);   -- Used for debugging.
      led_o       : out   std_logic_vector(15 downto 0);   -- Used for debugging.

      ps2_clk_io  : inout std_logic;                       -- Keyboard
      ps2_data_io : inout std_logic;

      sd_reset_o  : out   std_logic;                       -- SD card
      sd_dat_io   : inout std_logic_vector(3 downto 0);    -- miso, cs
      sd_cmd_io   : inout std_logic;                       -- mosi
      sd_sck_io   : inout std_logic;
      sd_cd_i     : in    std_logic;

      vga_hs_o    : out   std_logic;                       -- VGA
      vga_vs_o    : out   std_logic;
      vga_col_o   : out   std_logic_vector(11 downto 0)    -- 4 bits for each colour RGB.
   );
end x16;

architecture structural of x16 is

   constant C_ROM_INIT_FILE : string := "main/rom.txt";     -- ROM contents.

   signal vga_clk_s         : std_logic;                    -- 25.2 MHz

   signal main_clk_s        : std_logic;                    -- 8.33 MHz
   signal main_clkn_s       : std_logic;                    -- Inverted clock
   signal main_addr_s       : std_logic_vector(15 downto 0);
   signal main_wr_en_s      : std_logic;
   signal main_wr_data_s    : std_logic_vector( 7 downto 0);
   signal main_rd_en_s      : std_logic;
   signal main_rd_data_s    : std_logic_vector( 7 downto 0);
   signal main_debug_s      : std_logic_vector(15 downto 0);
   signal main_vera_debug_s : std_logic_vector(16 downto 0);
   signal main_vera_irq_s   : std_logic;
   signal main_rst_s        : std_logic_vector( 3 downto 0) := (others => '1');

   signal ps2_data_in_s     : std_logic;
   signal ps2_data_out_s    : std_logic;
   signal ps2_dataen_s      : std_logic;
   signal ps2_clk_in_s      : std_logic;
   signal ps2_clk_out_s     : std_logic;
   signal ps2_clken_s       : std_logic;

   signal spi_sclk_s        : std_logic;
   signal spi_mosi_s        : std_logic;
   signal spi_miso_s        : std_logic;
   signal spi_cs_s          : std_logic;

   -- Debug
   constant DEBUG_MODE                : boolean := false; -- TRUE OR FALSE

   attribute mark_debug               : boolean;
   attribute mark_debug of spi_sclk_s : signal is DEBUG_MODE;
   attribute mark_debug of spi_mosi_s : signal is DEBUG_MODE;
   attribute mark_debug of spi_miso_s : signal is DEBUG_MODE;
   attribute mark_debug of spi_cs_s   : signal is DEBUG_MODE;
   attribute mark_debug of sd_cd_i    : signal is DEBUG_MODE;

begin

   ----------------------------------------------------------------
   -- Generate SPI tristate buffers.
   ----------------------------------------------------------------

   -- The SD_RESET signal needs to be actively driven low by the FPGA to power
   -- the microSD card slot.
   sd_reset_o   <= '0';
   sd_dat_io(3) <= spi_cs_s;
   sd_dat_io(2) <= 'Z';
   sd_dat_io(1) <= 'Z';
   sd_dat_io(0) <= 'Z';
   spi_miso_s   <= sd_dat_io(0);
   sd_cmd_io    <= spi_mosi_s;
   sd_sck_io    <= spi_sclk_s;


   ----------------------------------------------------------------
   -- Generate PS/2 tristate buffers, simulating open-collector:
   -- Either drive low or tristate; never drive high.
   ----------------------------------------------------------------

   ps2_data_in_s <= ps2_data_io;
   ps2_clk_in_s  <= ps2_clk_io;
   ps2_data_io   <= ps2_data_out_s when ps2_dataen_s = '1' and ps2_data_out_s = '0' else 'Z';
   ps2_clk_io    <= ps2_clk_out_s  when ps2_clken_s  = '1' and ps2_clk_out_s  = '0' else 'Z';


   --------------------------------------------------
   -- Instantiate Clock generation
   --------------------------------------------------

   i_clk : entity work.clk_wiz_0_clk_wiz
      port map (
         clk_in1 => clk_i,      -- 100 MHz
         vga_clk => vga_clk_s,  --  25.2 MHz
         cpu_clk => main_clk_s  --   8.33 MHz
      ); -- i_clk


   -----------------------------------
   -- Generate reset signal.
   -----------------------------------

   p_main_rst : process (main_clk_s)
   begin
      if rising_edge(main_clk_s) then
         main_rst_s <= main_rst_s(2 downto 0) & "0";  -- Shift left one bit
         if rstn_i = '0' then
            main_rst_s <= (others => '1');
         end if;
      end if;
   end process p_main_rst;

   main_clkn_s <= not main_clk_s;


   --------------------------------------------------
   -- Instantiate VERA module
   --------------------------------------------------

   i_vera : entity work.vera
      port map (
         cpu_clk_i     => main_clkn_s,
         cpu_rst_i     => main_rst_s(3),
         cpu_addr_i    => main_addr_s(2 downto 0),
         cpu_wr_en_i   => main_wr_en_s,
         cpu_wr_data_i => main_wr_data_s,
         cpu_rd_en_i   => main_rd_en_s,
         cpu_rd_data_o => main_rd_data_s,
         cpu_debug_o   => main_vera_debug_s,
         cpu_irq_o     => main_vera_irq_s,
         --
         spi_sclk_o    => spi_sclk_s,
         spi_mosi_o    => spi_mosi_s,
         spi_miso_i    => spi_miso_s,
         spi_cs_o      => spi_cs_s,
         --
         vga_clk_i     => vga_clk_s,
         vga_hs_o      => vga_hs_o,
         vga_vs_o      => vga_vs_o,
         vga_col_o     => vga_col_o
      ); -- i_vera


   --------------------------------------------------------
   -- Instantiate main computer (CPU, RAM, ROM, VIA, etc.)
   --------------------------------------------------------

   i_main : entity work.main
      generic map (
         G_ROM_INIT_FILE => C_ROM_INIT_FILE
      )
      port map (
         clk_i          => main_clk_s,
         rst_i          => main_rst_s(3),
         nmi_i          => '0',
         irq_i          => main_vera_irq_s,
         vera_addr_o    => main_addr_s(2 downto 0),
         vera_wr_en_o   => main_wr_en_s,
         vera_wr_data_o => main_wr_data_s,
         vera_rd_en_o   => main_rd_en_s,
         vera_rd_data_i => main_rd_data_s,
         vera_debug_o   => main_debug_s,
         --
         ps2_data_in_i  => ps2_data_in_s,
         ps2_data_out_o => ps2_data_out_s,
         ps2_dataen_o   => ps2_dataen_s,
         ps2_clk_in_i   => ps2_clk_in_s,
         ps2_clk_out_o  => ps2_clk_out_s,
         ps2_clken_o    => ps2_clken_s
      ); -- i_main
      

   --------------------------------
   -- Connect debug output signals 
   --------------------------------

   led_o <= main_vera_debug_s(15 downto 0) when sw_i(0) = '1' else
            main_debug_s;

end architecture structural;

