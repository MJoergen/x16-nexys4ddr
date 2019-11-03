library ieee;
use ieee.std_logic_1164.all;

entity tb is
end entity tb;

architecture simulation of tb is

   signal clk_s          : std_logic;
   signal rst_s          : std_logic;
   signal nmi_s          : std_logic;
   signal irq_s          : std_logic;
   signal vera_addr_s    : std_logic_vector(2 downto 0);
   signal vera_wr_en_s   : std_logic;
   signal vera_wr_data_s : std_logic_vector(7 downto 0);
   signal vera_rd_en_s   : std_logic;
   signal vera_rd_data_s : std_logic_vector(7 downto 0);
   signal vera_debug_s   : std_logic_vector(15 downto 0);

begin

   --------------------
   -- Clock generation
   --------------------

   p_clk : process
   begin
      clk_s <= '1', '0' after 3*2 ns;
      wait for 3*4 ns; -- 8.3 MHz
   end process p_clk;

   rst_s <= '1', '0' after 30*4 ns;
   nmi_s <= '0';
   irq_s <= '0';


   --------------------------
   -- Instantiate MAIN block
   --------------------------

   i_main : entity work.main
      generic map (
         G_ROM_INIT_FILE => "rom.txt"
      )
      port map (
         clk_i          => clk_s,
         rst_i          => rst_s,
         nmi_i          => nmi_s,
         irq_i          => irq_s,
         vera_addr_o    => vera_addr_s,
         vera_wr_en_o   => vera_wr_en_s,
         vera_wr_data_o => vera_wr_data_s,
         vera_rd_en_o   => vera_rd_en_s,
         vera_rd_data_i => vera_rd_data_s,
         vera_debug_o   => vera_debug_s
      ); -- i_main


   ------------------------------
   -- Instantiate VERA interface
   ------------------------------

   i_vera : entity work.cpu
      port map (
         clk_i          => clk_s,
         addr_i         => vera_addr_s,
         wr_en_i        => vera_wr_en_s,
         wr_data_i      => vera_wr_data_s,
         rd_en_i        => vera_rd_en_s,
         rd_data_o      => vera_rd_data_s,
         vram_addr_o    => open,
         vram_wr_en_o   => open,
         vram_wr_data_o => open,
         vram_rd_en_o   => open,
         vram_rd_data_i => (others => '0'),
         pal_addr_o     => open,
         pal_wr_en_o    => open,
         pal_wr_data_o  => open,
         pal_rd_en_o    => open,
         pal_rd_data_i  => (others => '0'),
         map_base_o     => open,
         tile_base_o    => open
      ); -- i_vera

end architecture simulation;

