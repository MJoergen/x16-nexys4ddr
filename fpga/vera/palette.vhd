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

   -- This defines a type containing an array of words.
   type mem_t is array (0 to 255) of std_logic_vector(15 downto 0);

   -- Default palette. Copied from x16-emulator.
   signal mem_r : mem_t := ( 
      X"0000", X"0FFF", X"0800", X"0AFE", X"0C4C", X"00C5", X"000A", X"0EE7",
      X"0D85", X"0640", X"0F77", X"0333", X"0777", X"0AF6", X"008F", X"0BBB",
      X"0000", X"0111", X"0222", X"0333", X"0444", X"0555", X"0666", X"0777",
      X"0888", X"0999", X"0AAA", X"0BBB", X"0CCC", X"0DDD", X"0EEE", X"0FFF",
      X"0211", X"0433", X"0644", X"0866", X"0A88", X"0C99", X"0FBB", X"0211",
      X"0422", X"0633", X"0844", X"0A55", X"0C66", X"0F77", X"0200", X"0411",
      X"0611", X"0822", X"0A22", X"0C33", X"0F33", X"0200", X"0400", X"0600",
      X"0800", X"0A00", X"0C00", X"0F00", X"0221", X"0443", X"0664", X"0886",
      X"0AA8", X"0CC9", X"0FEB", X"0211", X"0432", X"0653", X"0874", X"0A95",
      X"0CB6", X"0FD7", X"0210", X"0431", X"0651", X"0862", X"0A82", X"0CA3",
      X"0FC3", X"0210", X"0430", X"0640", X"0860", X"0A80", X"0C90", X"0FB0",
      X"0121", X"0343", X"0564", X"0786", X"09A8", X"0BC9", X"0DFB", X"0121",
      X"0342", X"0463", X"0684", X"08A5", X"09C6", X"0BF7", X"0120", X"0241",
      X"0461", X"0582", X"06A2", X"08C3", X"09F3", X"0120", X"0240", X"0360",
      X"0480", X"05A0", X"06C0", X"07F0", X"0121", X"0343", X"0465", X"0686",
      X"08A8", X"09CA", X"0BFC", X"0121", X"0242", X"0364", X"0485", X"05A6",
      X"06C8", X"07F9", X"0020", X"0141", X"0162", X"0283", X"02A4", X"03C5",
      X"03F6", X"0020", X"0041", X"0061", X"0082", X"00A2", X"00C3", X"00F3",
      X"0122", X"0344", X"0466", X"0688", X"08AA", X"09CC", X"0BFF", X"0122",
      X"0244", X"0366", X"0488", X"05AA", X"06CC", X"07FF", X"0022", X"0144",
      X"0166", X"0288", X"02AA", X"03CC", X"03FF", X"0022", X"0044", X"0066",
      X"0088", X"00AA", X"00CC", X"00FF", X"0112", X"0334", X"0456", X"0668",
      X"088A", X"09AC", X"0BCF", X"0112", X"0224", X"0346", X"0458", X"056A",
      X"068C", X"079F", X"0002", X"0114", X"0126", X"0238", X"024A", X"035C",
      X"036F", X"0002", X"0014", X"0016", X"0028", X"002A", X"003C", X"003F",
      X"0112", X"0334", X"0546", X"0768", X"098A", X"0B9C", X"0DBF", X"0112",
      X"0324", X"0436", X"0648", X"085A", X"096C", X"0B7F", X"0102", X"0214",
      X"0416", X"0528", X"062A", X"083C", X"093F", X"0102", X"0204", X"0306",
      X"0408", X"050A", X"060C", X"070F", X"0212", X"0434", X"0646", X"0868",
      X"0A8A", X"0C9C", X"0FBE", X"0211", X"0423", X"0635", X"0847", X"0A59",
      X"0C6B", X"0F7D", X"0201", X"0413", X"0615", X"0826", X"0A28", X"0C3A",
      X"0F3C", X"0201", X"0403", X"0604", X"0806", X"0A08", X"0C09", X"0F0B"
   );
 
   signal mem_rd_data_r : std_logic_vector(15 downto 0);
   signal cpu_addr_r    : std_logic;

begin

   ---------------
   -- CPU access.
   ---------------

   p_cpu : process (cpu_clk_i)
   begin
      if falling_edge(cpu_clk_i) then
         if cpu_wr_en_i = '1' then
            if cpu_addr_i(0) = '0' then
               mem_r(to_integer(cpu_addr_i(8 downto 1)))( 7 downto 0) <= cpu_wr_data_i;
            else
               mem_r(to_integer(cpu_addr_i(8 downto 1)))(15 downto 8) <= cpu_wr_data_i;
            end if;
         end if;
         if cpu_rd_en_i = '1' then
            mem_rd_data_r <= mem_r(to_integer(cpu_addr_i(8 downto 1)));
            cpu_addr_r    <= cpu_addr_i(0);
         end if;
      end if;
   end process p_cpu;

   -- This multiplexer must be outside the read process, in order to get
   -- the Vivado tool to infer a block RAM.
   cpu_rd_data_o <= mem_rd_data_r(7 downto 0) when cpu_addr_r = '0' else
                    mem_rd_data_r(15 downto 8);


   ---------------
   -- VGA access.
   ---------------

   p_vga : process (vga_clk_i)
   begin
      if rising_edge(vga_clk_i) then
         if vga_rd_en_i = '1' then
            vga_rd_data_o <= mem_r(to_integer(vga_rd_addr_i))(11 downto 0);
         end if;
      end if;
   end process p_vga;

end rtl;

