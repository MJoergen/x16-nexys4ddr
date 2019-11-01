library ieee;
use ieee.std_logic_1164.all;

-- This is the top level module of the X16. The ports on this entity are mapped
-- directly to pins on the FPGA.

entity x16 is
   port (
      clk_i      : in    std_logic;                       -- 100 MHz

      rstn_i     : in    std_logic;                       -- CPU reset, active low

      sw_i       : in    std_logic_vector(7 downto 0);    -- Used for debugging.
      led_o      : out   std_logic_vector(7 downto 0);    -- Used for debugging.

      ps2_clk_i  : in    std_logic;                       -- Keyboard
      ps2_data_i : in    std_logic;

      vga_hs_o   : out   std_logic;                       -- VGA
      vga_vs_o   : out   std_logic;
      vga_col_o  : out   std_logic_vector(11 downto 0)    -- 4 bits for each colour RGB.
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

begin

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
         vga_clk_i     => vga_clk_s,
         vga_hs_o      => vga_hs_o,
         vga_vs_o      => vga_vs_o,
         vga_col_o     => vga_col_o
      ); -- i_vera


   --------------------------------------------------
   -- Instantiate main computer (CPU,RAM,ROM,etc.)
   --------------------------------------------------

   i_main : entity work.main
      generic map (
         G_ROM_INIT_FILE => C_ROM_INIT_FILE
      )
      port map (
         clk_i          => main_clk_s,
         vera_addr_o    => main_addr_s(2 downto 0),
         vera_wr_en_o   => main_wr_en_s,
         vera_wr_data_o => main_wr_data_s,
         vera_rd_en_o   => main_rd_en_s,
         vera_rd_data_i => main_rd_data_s
      ); -- i_main
      

   --------------------------
   -- Connect unused signals 
   --------------------------

   led_o <= (others => '0');

end architecture structural;

