library ieee;
use ieee.std_logic_1164.all;

entity main is
   generic (
      G_ROM_INIT_FILE : string
   );

   port (
      clk_i          : in  std_logic;
      vera_addr_o    : out std_logic_vector(2 downto 0);
      vera_wr_en_o   : out std_logic;
      vera_wr_data_o : out std_logic_vector(7 downto 0);
      vera_rd_en_o   : out std_logic;
      vera_rd_data_i : in  std_logic_vector(7 downto 0)
   );
end main;

architecture structural of main is

   signal cpu_addr_s    : std_logic_vector(15 downto 0);
   signal cpu_wr_en_s   : std_logic;
   signal cpu_wr_data_s : std_logic_vector( 7 downto 0);
   signal cpu_rd_en_s   : std_logic;
   signal cpu_rd_data_s : std_logic_vector( 7 downto 0);

   signal rom_rd_data_s : std_logic_vector( 7 downto 0);
   signal ram_rd_data_s : std_logic_vector( 7 downto 0);
   signal rom_rd_en_s   : std_logic;
   signal ram_rd_en_s   : std_logic;
   signal ram_wr_en_s   : std_logic;
   signal ram_wr_data_s : std_logic_vector( 7 downto 0);

   signal rom_cs_s      : std_logic;   -- 0xC000 - 0xFFFF
   signal ram_cs_s      : std_logic;   -- 0x0000 - 0x3FFF
   signal vera_cs_s     : std_logic;   -- 0x9F60 - 0x9F6F

begin

   --------------------------------------------------
   -- Instantiate 65C02 CPU module
   --------------------------------------------------

   i_cpu_dummy : entity work.cpu_dummy
      port map (
         clk_i     => clk_i,
         addr_o    => cpu_addr_s,
         wr_en_o   => cpu_wr_en_s,
         wr_data_o => cpu_wr_data_s,
         rd_en_o   => cpu_rd_en_s,
         rd_data_i => cpu_rd_data_s
      ); -- i_cpu_dummy


   --------------------
   -- Address decoding      
   --------------------

   rom_cs_s  <= '1' when cpu_addr_s(15 downto 14) = "11" else '0';
   ram_cs_s  <= '1' when cpu_addr_s(15 downto 14) = "00" else '0';
   vera_cs_s <= '1' when cpu_addr_s(15 downto  4) = X"9F2" else '0';

   cpu_rd_data_s <= rom_rd_data_s  when rom_cs_s  = '1' else
                    ram_rd_data_s  when ram_cs_s  = '1' else
                    vera_rd_data_i when vera_cs_s = '1' else
                    (others => '0');

   rom_rd_en_s  <= cpu_rd_en_s and rom_cs_s;

   vera_rd_en_o   <= cpu_rd_en_s and vera_cs_s;
   vera_wr_en_o   <= cpu_wr_en_s and vera_cs_s;
   vera_wr_data_o <= cpu_wr_data_s;
   vera_addr_o    <= cpu_addr_s(2 downto 0);

   ram_rd_en_s   <= cpu_rd_en_s and ram_cs_s;
   ram_wr_en_s   <= cpu_wr_en_s and ram_cs_s;
   ram_wr_data_s <= cpu_wr_data_s;

   -------------------
   -- Instantiate ROM
   -------------------

   i_rom : entity work.rom
      generic map (
         G_INIT_FILE => G_ROM_INIT_FILE,
         G_ADDR_BITS => 14                   -- 2^14 = 16 kB
      )
      port map (
         clk_i     => clk_i,
         addr_i    => cpu_addr_s(13 downto 0),
         rd_en_i   => rom_rd_en_s,
         rd_data_o => rom_rd_data_s
      ); -- i_rom
      
      
   -------------------
   -- Instantiate RAM
   -------------------

   i_ram : entity work.ram
      generic map (
         G_ADDR_BITS => 14                   -- 2^14 = 16 kB
      )
      port map (
         clk_i     => clk_i,
         addr_i    => cpu_addr_s(13 downto 0),
         wr_en_i   => ram_wr_en_s,
         wr_data_i => ram_wr_data_s,
         rd_en_i   => ram_rd_en_s,
         rd_data_o => ram_rd_data_s
      ); -- i_ram
      
      
end architecture structural;

