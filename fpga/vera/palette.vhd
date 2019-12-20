library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is a file containing the palette memory.
-- It performs a mapping from 8-bit values to 12-bit colours.

entity palette is
   port (
      -- CPU port
      cpu_clk_i     : in  std_logic;
      cpu_rst_i     : in  std_logic;
      cpu_addr_i    : in  std_logic_vector( 8 downto 0);
      cpu_wr_en_i   : in  std_logic;
      cpu_wr_data_i : in  std_logic_vector( 7 downto 0);
      cpu_rd_data_o : out std_logic_vector( 7 downto 0);
      -- VGA port
      vga_clk_i     : in  std_logic;
      vga_rd_addr_i : in  std_logic_vector( 7 downto 0);
      vga_rd_data_o : out std_logic_vector(11 downto 0)
   );
end palette;

architecture rtl of palette is

   -- This defines a type containing an array of bytes.
   type mem_t is array (0 to 255) of std_logic_vector(7 downto 0);

   signal mem_hi_r : mem_t := (others => X"00");
   signal mem_lo_r : mem_t := (others => X"00");

   signal cpu_rd_hi_r      : std_logic_vector(7 downto 0);
   signal cpu_rd_lo_r      : std_logic_vector(7 downto 0);

   signal cpu_rst_addr_r   : std_logic_vector(7 downto 0);
   signal cpu_rst_done_r   : std_logiC;
   signal cpu_addr_s       : std_logic_vector(7 downto 0);
   signal cpu_wr_data_hi_s : std_logic_vector(7 downto 0);
   signal cpu_wr_data_lo_s : std_logic_vector(7 downto 0);

   signal vga_rd_hi_r      : std_logic_vector(7 downto 0);
   signal vga_rd_lo_r      : std_logic_vector(7 downto 0);

   -- Encoding: 0000RRRR
   constant cpu_rst_data_hi_c : mem_t := (
      X"00", X"0F", X"08", X"0A", X"0C", X"00", X"00", X"0E",
      X"0D", X"06", X"0F", X"03", X"07", X"0A", X"00", X"0B",
      X"00", X"01", X"02", X"03", X"04", X"05", X"06", X"07",
      X"08", X"09", X"0A", X"0B", X"0C", X"0D", X"0E", X"0F",
      X"02", X"04", X"06", X"08", X"0A", X"0C", X"0F", X"02",
      X"04", X"06", X"08", X"0A", X"0C", X"0F", X"02", X"04",
      X"06", X"08", X"0A", X"0C", X"0F", X"02", X"04", X"06",
      X"08", X"0A", X"0C", X"0F", X"02", X"04", X"06", X"08",
      X"0A", X"0C", X"0F", X"02", X"04", X"06", X"08", X"0A",
      X"0C", X"0F", X"02", X"04", X"06", X"08", X"0A", X"0C",
      X"0F", X"02", X"04", X"06", X"08", X"0A", X"0C", X"0F",
      X"01", X"03", X"05", X"07", X"09", X"0B", X"0D", X"01",
      X"03", X"04", X"06", X"08", X"09", X"0B", X"01", X"02",
      X"04", X"05", X"06", X"08", X"09", X"01", X"02", X"03",
      X"04", X"05", X"06", X"07", X"01", X"03", X"04", X"06",
      X"08", X"09", X"0B", X"01", X"02", X"03", X"04", X"05",
      X"06", X"07", X"00", X"01", X"01", X"02", X"02", X"03",
      X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
      X"01", X"03", X"04", X"06", X"08", X"09", X"0B", X"01",
      X"02", X"03", X"04", X"05", X"06", X"07", X"00", X"01",
      X"01", X"02", X"02", X"03", X"03", X"00", X"00", X"00",
      X"00", X"00", X"00", X"00", X"01", X"03", X"04", X"06",
      X"08", X"09", X"0B", X"01", X"02", X"03", X"04", X"05",
      X"06", X"07", X"00", X"01", X"01", X"02", X"02", X"03",
      X"03", X"00", X"00", X"00", X"00", X"00", X"00", X"00",
      X"01", X"03", X"05", X"07", X"09", X"0B", X"0D", X"01",
      X"03", X"04", X"06", X"08", X"09", X"0B", X"01", X"02",
      X"04", X"05", X"06", X"08", X"09", X"01", X"02", X"03",
      X"04", X"05", X"06", X"07", X"02", X"04", X"06", X"08",
      X"0A", X"0C", X"0F", X"02", X"04", X"06", X"08", X"0A",
      X"0C", X"0F", X"02", X"04", X"06", X"08", X"0A", X"0C",
      X"0F", X"02", X"04", X"06", X"08", X"0A", X"0C", X"0F"
   );

   -- Encoding: GGGGBBBB
   constant cpu_rst_data_lo_c : mem_t := (
      X"00", X"FF", X"00", X"FE", X"4C", X"C5", X"0A", X"E7",
      X"85", X"40", X"77", X"33", X"77", X"F6", X"8F", X"BB",
      X"00", X"11", X"22", X"33", X"44", X"55", X"66", X"77",
      X"88", X"99", X"AA", X"BB", X"CC", X"DD", X"EE", X"FF",
      X"11", X"33", X"44", X"66", X"88", X"99", X"BB", X"11",
      X"22", X"33", X"44", X"55", X"66", X"77", X"00", X"11",
      X"11", X"22", X"22", X"33", X"33", X"00", X"00", X"00",
      X"00", X"00", X"00", X"00", X"21", X"43", X"64", X"86",
      X"A8", X"C9", X"EB", X"11", X"32", X"53", X"74", X"95",
      X"B6", X"D7", X"10", X"31", X"51", X"62", X"82", X"A3",
      X"C3", X"10", X"30", X"40", X"60", X"80", X"90", X"B0",
      X"21", X"43", X"64", X"86", X"A8", X"C9", X"FB", X"21",
      X"42", X"63", X"84", X"A5", X"C6", X"F7", X"20", X"41",
      X"61", X"82", X"A2", X"C3", X"F3", X"20", X"40", X"60",
      X"80", X"A0", X"C0", X"F0", X"21", X"43", X"65", X"86",
      X"A8", X"CA", X"FC", X"21", X"42", X"64", X"85", X"A6",
      X"C8", X"F9", X"20", X"41", X"62", X"83", X"A4", X"C5",
      X"F6", X"20", X"41", X"61", X"82", X"A2", X"C3", X"F3",
      X"22", X"44", X"66", X"88", X"AA", X"CC", X"FF", X"22",
      X"44", X"66", X"88", X"AA", X"CC", X"FF", X"22", X"44",
      X"66", X"88", X"AA", X"CC", X"FF", X"22", X"44", X"66",
      X"88", X"AA", X"CC", X"FF", X"12", X"34", X"56", X"68",
      X"8A", X"AC", X"CF", X"12", X"24", X"46", X"58", X"6A",
      X"8C", X"9F", X"02", X"14", X"26", X"38", X"4A", X"5C",
      X"6F", X"02", X"14", X"16", X"28", X"2A", X"3C", X"3F",
      X"12", X"34", X"46", X"68", X"8A", X"9C", X"BF", X"12",
      X"24", X"36", X"48", X"5A", X"6C", X"7F", X"02", X"14",
      X"16", X"28", X"2A", X"3C", X"3F", X"02", X"04", X"06",
      X"08", X"0A", X"0C", X"0F", X"12", X"34", X"46", X"68",
      X"8A", X"9C", X"BE", X"11", X"23", X"35", X"47", X"59",
      X"6B", X"7D", X"01", X"13", X"15", X"26", X"28", X"3A",
      X"3C", X"01", X"03", X"04", X"06", X"08", X"09", X"0B"
   );

   -- Debug
   constant DEBUG_MODE                      : boolean := false; -- TRUE OR FALSE

   attribute mark_debug                     : boolean;
   attribute mark_debug of vga_rd_addr_i    : signal is DEBUG_MODE;
   attribute mark_debug of vga_rd_data_o    : signal is DEBUG_MODE;
   attribute mark_debug of vga_rd_hi_r      : signal is DEBUG_MODE;
   attribute mark_debug of vga_rd_lo_r      : signal is DEBUG_MODE;

   attribute mark_debug of cpu_addr_i       : signal is DEBUG_MODE;
   attribute mark_debug of cpu_wr_en_i      : signal is DEBUG_MODE;
   attribute mark_debug of cpu_wr_data_i    : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rd_data_o    : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rd_hi_r      : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rd_lo_r      : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rst_addr_r   : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rst_done_r   : signal is DEBUG_MODE;
   attribute mark_debug of cpu_addr_s       : signal is DEBUG_MODE;
   attribute mark_debug of cpu_wr_data_hi_s : signal is DEBUG_MODE;
   attribute mark_debug of cpu_wr_data_lo_s : signal is DEBUG_MODE;

begin

   ---------------
   -- CPU access.
   ---------------

   cpu_addr_s       <= cpu_addr_i(8 downto 1) when cpu_rst_done_r = '1' else cpu_rst_addr_r;
   cpu_wr_data_hi_s <= cpu_wr_data_i          when cpu_rst_done_r = '1' else cpu_rst_data_hi_c(to_integer(cpu_rst_addr_r));
   cpu_wr_data_lo_s <= cpu_wr_data_i          when cpu_rst_done_r = '1' else cpu_rst_data_lo_c(to_integer(cpu_rst_addr_r));

   p_cpu_reset : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         if cpu_rst_done_r = '0' then
            cpu_rst_addr_r <= cpu_rst_addr_r + 1;
            if cpu_rst_addr_r = X"FF" then
               cpu_rst_done_r <= '1';
            end if;
         end if;
         if cpu_rst_i = '1' then
            cpu_rst_addr_r <= (others => '0');
            cpu_rst_done_r <= '0';
         end if;
      end if;
   end process p_cpu_reset;

   p_cpu_write_hi : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         if (cpu_wr_en_i = '1' and cpu_addr_i(0) = '1') or cpu_rst_done_r = '0' then
            mem_hi_r(to_integer(cpu_addr_s)) <= cpu_wr_data_hi_s;
         end if;
      end if;
   end process p_cpu_write_hi;

   p_cpu_write_lo : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         if (cpu_wr_en_i = '1' and cpu_addr_i(0) = '0') or cpu_rst_done_r = '0' then
            mem_lo_r(to_integer(cpu_addr_s)) <= cpu_wr_data_lo_s;
         end if;
      end if;
   end process p_cpu_write_lo;

   p_cpu_read_hi : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         cpu_rd_hi_r <= mem_hi_r(to_integer(cpu_addr_i(8 downto 1)));
      end if;
   end process p_cpu_read_hi;

   p_cpu_read_lo : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         cpu_rd_lo_r <= mem_lo_r(to_integer(cpu_addr_i(8 downto 1)));
      end if;
   end process p_cpu_read_lo;

   cpu_rd_data_o <= cpu_rd_hi_r when cpu_addr_i(0) = '1' else cpu_rd_lo_r;


   ---------------
   -- VGA access.
   ---------------

   p_vga_read_hi : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         vga_rd_hi_r <= mem_hi_r(to_integer(vga_rd_addr_i));
      end if;
   end process p_vga_read_hi;

   p_vga_read_lo : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         vga_rd_lo_r <= mem_lo_r(to_integer(vga_rd_addr_i));
      end if;
   end process p_vga_read_lo;

   vga_rd_data_o <= vga_rd_hi_r(3 downto 0) & vga_rd_lo_r;

end rtl;

