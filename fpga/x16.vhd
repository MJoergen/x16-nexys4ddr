library ieee;
use ieee.std_logic_1164.all;

-- This is the top level module of the X16. The ports on this entity are mapped
-- directly to pins on the FPGA.

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

   constant C_ROM_INIT_FILE : string := "main/rom.txt";       -- ROM contents.

   signal vga_clk_s         : std_logic;   -- 25.2 MHz

   signal main_clk_s        : std_logic;   --  8.33 MHz
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

begin

   -----------------------------------
   -- Generate PS/2 tristate buffers.
   -----------------------------------

   ps2_data_in_s <= ps2_data_io;
   ps2_clk_in_s  <= ps2_clk_io;
   ps2_data_io   <= ps2_data_out_s when ps2_dataen_s = '1' and ps2_data_out_s = '0' else 'Z';
   ps2_clk_io    <= ps2_clk_out_s  when ps2_clken_s  = '1' else 'Z';


   p_main_rst : process (main_clk_s)
   begin
      if rising_edge(main_clk_s) then
         main_rst_s <= main_rst_s(2 downto 0) & "0";  -- Shift left one bit
         if rstn_i = '0' then
            main_rst_s <= (others => '1');
         end if;
      end if;
   end process p_main_rst;


   --------------------------------------------------
   -- Instantiate Clock generation
   --------------------------------------------------

   i_clk : entity work.clk_wiz_0_clk_wiz
      port map (
         clk_in1 => clk_i,      -- 100 MHz
         vga_clk => vga_clk_s,  --  25.2 MHz
         cpu_clk => main_clk_s  --   8.33 MHz
      ); -- i_clk


   --------------------------------------------------
   -- Instantiate VERA module
   --------------------------------------------------

   i_vera : entity work.vera
      port map (
         cpu_clk_i     => main_clk_s,
         cpu_addr_i    => main_addr_s(2 downto 0),
         cpu_wr_en_i   => main_wr_en_s,
         cpu_wr_data_i => main_wr_data_s,
         cpu_rd_en_i   => main_rd_en_s,
         cpu_rd_data_o => main_rd_data_s,
         cpu_debug_o   => main_vera_debug_s,
         cpu_irq_o     => main_vera_irq_s,
         vga_clk_i     => vga_clk_s,
         vga_hs_o      => vga_hs_o,
         vga_vs_o      => vga_vs_o,
         vga_col_o     => vga_col_o
      ); -- i_vera

   sd_reset_o <= '0';   


   --------------------------------------------------
   -- Instantiate main computer (CPU,RAM,ROM,etc.)
   --------------------------------------------------

   i_main : entity work.main
      generic map (
         G_ROM_INIT_FILE => C_ROM_INIT_FILE
      )
      port map (
         clk_i          => main_clk_s,
         rst_i          => main_rst_s(3),
         nmi_i          => '0',
         irq_i          => main_vera_irq_s,
         ps2_data_in_i  => ps2_data_in_s,
         ps2_data_out_o => ps2_data_out_s,
         ps2_dataen_o   => ps2_dataen_s,
         ps2_clk_in_i   => ps2_clk_in_s,
         ps2_clk_out_o  => ps2_clk_out_s,
         ps2_clken_o    => ps2_clken_s,
         vera_addr_o    => main_addr_s(2 downto 0),
         vera_wr_en_o   => main_wr_en_s,
         vera_wr_data_o => main_wr_data_s,
         vera_rd_en_o   => main_rd_en_s,
         vera_rd_data_i => main_rd_data_s,
         vera_debug_o   => main_debug_s
      ); -- i_main
      

   --------------------------------
   -- Connect debug output signals 
   --------------------------------

   led_o <= main_vera_debug_s(15 downto 0) when sw_i(0) = '1' else
            main_debug_s;

end architecture structural;

