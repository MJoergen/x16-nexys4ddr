library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std_unsigned.all;

-- This is a file containing the palette memory.
-- It performs a mapping from 8-bit values to 12-bit colours.

entity palette is
   port (
      -- CPU port
      cpu_clk_i     : in  std_logic;
      cpu_addr_i    : in  std_logic_vector( 8 downto 0);
      cpu_wr_en_i   : in  std_logic;
      cpu_wr_data_i : in  std_logic_vector( 7 downto 0);
      cpu_rd_en_i   : in  std_logic;
      cpu_rd_data_o : out std_logic_vector( 7 downto 0);
      -- VGA port
      vga_clk_i     : in  std_logic;
      vga_rd_addr_i : in  std_logic_vector( 7 downto 0);
      vga_rd_en_i   : in  std_logic;
      vga_rd_data_o : out std_logic_vector(11 downto 0)
   );
end palette;

architecture rtl of palette is

   -- This defines a type containing an array of bytes.
   type mem_t is array (0 to 255) of std_logic_vector(11 downto 0);

   -- Default palette. Copied from x16-emulator.
   -- Format is GGGGBBBBRRRR
   signal mem_r : mem_t := ( 
      X"000", X"FFF", X"008", X"FEA",
      X"4CC", X"C50", X"0A0", X"E7E",
      X"85D", X"406", X"77F", X"333",
      X"777", X"F6A", X"8F0", X"BBB",
      X"000", X"111", X"222", X"333",
      X"444", X"555", X"666", X"777",
      X"888", X"999", X"AAA", X"BBB",
      X"CCC", X"DDD", X"EEE", X"FFF",
      X"112", X"334", X"446", X"668",
      X"88A", X"99C", X"BBF", X"112",
      X"224", X"336", X"448", X"55A",
      X"66C", X"77F", X"002", X"114",
      X"116", X"228", X"22A", X"33C",
      X"33F", X"002", X"004", X"006",
      X"008", X"00A", X"00C", X"00F",
      X"212", X"434", X"646", X"868",
      X"A8A", X"C9C", X"EBF", X"112",
      X"324", X"536", X"748", X"95A",
      X"B6C", X"D7F", X"102", X"314",
      X"516", X"628", X"82A", X"A3C",
      X"C3F", X"102", X"304", X"406",
      X"608", X"80A", X"90C", X"B0F",
      X"211", X"433", X"645", X"867",
      X"A89", X"C9B", X"FBD", X"211",
      X"423", X"634", X"846", X"A58",
      X"C69", X"F7B", X"201", X"412",
      X"614", X"825", X"A26", X"C38",
      X"F39", X"201", X"402", X"603",
      X"804", X"A05", X"C06", X"F07",
      X"211", X"433", X"654", X"866",
      X"A88", X"CA9", X"FCB", X"211",
      X"422", X"643", X"854", X"A65",
      X"C86", X"F97", X"200", X"411",
      X"621", X"832", X"A42", X"C53",
      X"F63", X"200", X"410", X"610",
      X"820", X"A20", X"C30", X"F30",
      X"221", X"443", X"664", X"886",
      X"AA8", X"CC9", X"FFB", X"221",
      X"442", X"663", X"884", X"AA5",
      X"CC6", X"FF7", X"220", X"441",
      X"661", X"882", X"AA2", X"CC3",
      X"FF3", X"220", X"440", X"660",
      X"880", X"AA0", X"CC0", X"FF0",
      X"121", X"343", X"564", X"686",
      X"8A8", X"AC9", X"CFB", X"121",
      X"242", X"463", X"584", X"6A5",
      X"8C6", X"9F7", X"020", X"141",
      X"261", X"382", X"4A2", X"5C3",
      X"6F3", X"020", X"140", X"160",
      X"280", X"2A0", X"3C0", X"3F0",
      X"121", X"343", X"465", X"687",
      X"8A9", X"9CB", X"BFD", X"121",
      X"243", X"364", X"486", X"5A8",
      X"6C9", X"7FB", X"021", X"142",
      X"164", X"285", X"2A6", X"3C8",
      X"3F9", X"021", X"042", X"063",
      X"084", X"0A5", X"0C6", X"0F7",
      X"122", X"344", X"466", X"688",
      X"8AA", X"9CC", X"BEF", X"112",
      X"234", X"356", X"478", X"59A",
      X"6BC", X"7DF", X"012", X"134",
      X"156", X"268", X"28A", X"3AC",
      X"3CF", X"012", X"034", X"046",
      X"068", X"08A", X"09C", X"0BF"
   );
 
   -- Debug
   constant DEBUG_MODE                   : boolean := false; -- TRUE OR FALSE

   attribute mark_debug                  : boolean;
   attribute mark_debug of vga_rd_addr_i : signal is DEBUG_MODE;
   attribute mark_debug of vga_rd_en_i   : signal is DEBUG_MODE;
   attribute mark_debug of vga_rd_data_o : signal is DEBUG_MODE;

   attribute mark_debug of cpu_addr_i    : signal is DEBUG_MODE;
   attribute mark_debug of cpu_wr_en_i   : signal is DEBUG_MODE;
   attribute mark_debug of cpu_wr_data_i : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rd_en_i   : signal is DEBUG_MODE;
   attribute mark_debug of cpu_rd_data_o : signal is DEBUG_MODE;

begin

   ---------------
   -- CPU access.
   ---------------

   p_cpu_write : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         if cpu_wr_en_i = '1' then
            case cpu_addr_i(0) is
               when '0' => mem_r(to_integer(cpu_addr_i(8 downto 1)))(7 downto 0) <= cpu_wr_data_i;
               when '1' => mem_r(to_integer(cpu_addr_i(8 downto 1)))(11 downto 8) <= cpu_wr_data_i(3 downto 0);
               when others => null;
            end case;
         end if;
      end if;
   end process p_cpu_write;

   p_cpu_read : process (cpu_clk_i)
   begin
      if rising_edge(cpu_clk_i) then
         if cpu_rd_en_i = '1' then
            case cpu_addr_i(0) is
               when '0' => cpu_rd_data_o <= mem_r(to_integer(cpu_addr_i(8 downto 1)))(7 downto 0);
               when '1' => cpu_rd_data_o <= "0000" & mem_r(to_integer(cpu_addr_i(8 downto 1)))(11 downto 8);
               when others => null;
            end case;
         end if;
      end if;
   end process p_cpu_read;


   ---------------
   -- VGA access.
   ---------------

   p_vga : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         if vga_rd_en_i = '1' then
            vga_rd_data_o <= mem_r(to_integer(vga_rd_addr_i));
         end if;
      end if;
   end process p_vga;

end rtl;

