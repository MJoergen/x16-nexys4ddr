set fp [open x16.mmi w]

puts $fp "<MemInfo Version=\"1\" Minor=\"1\">"
puts $fp "   <Processor Endianness=\"Little\" InstPath=\"i_main/i_rom\">"
puts $fp "      <AddressSpace Name=\"ROM\" Begin=\"0\" End=\"16383\">"
puts $fp "         <BusBlock>"

set memInsts [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.* && NAME =~ *i_rom*}]
set memSort [lsort -decreasing $memInsts]

foreach memInst $memSort {
   set loc              [get_property LOC              $memInst]
   set loc              [string trimleft $loc RAMB36_]
   set bram_addr_begin  [get_property bram_addr_begin  $memInst]
   set bram_addr_end    [get_property bram_addr_end    $memInst]
   set bram_slice_begin [get_property bram_slice_begin $memInst]
   set bram_slice_end   [get_property bram_slice_end   $memInst]
   puts $fp "            <BitLane MemType=\"RAMB36\" Placement=\"$loc\">"
   puts $fp "               <DataWidth MSB=\"$bram_slice_end\" LSB=\"$bram_slice_begin\"/>"
   puts $fp "               <AddressRange Begin=\"$bram_addr_begin\" End=\"$bram_addr_end\"/>"
   puts $fp "               <Parity ON=\"false\" NumBits=\"0\"/>"
   puts $fp "            </BitLane>"
}

puts $fp "        </BusBlock>"
puts $fp "      </AddressSpace>"
puts $fp "   </Processor>"
puts $fp "   <Config>"
puts $fp "      <Option Name=\"Part\" Val=\"xc7a100tcsg324-1\"/>"
puts $fp "   </Config>"
puts $fp "</MemInfo>"
close $fp

