# This tcl script is to be called from within Vivado.
#
# It generates a MMI file, that can be used together with an associated
# memory file to update a bit-file.
#
# A suggested invocation is:
#   updatemem -debug  -meminfo x16.mmi  -data rom.mem  -proc dummy  -bit x16.bit  -out x16-rom.bit
#
# This script assumes the total ROM size is 128 kB.
#
# This script is based on information in the document:
# https://www.xilinx.com/support/documentation/sw_manuals/xilinx2018_1/ug898-vivado-embedded-design.pdf

# Get a list of the BRAMs for the ROM. There are 32 in total.
set memInsts [get_cells -hier -filter {PRIMITIVE_TYPE =~ BMEM.*.* && NAME =~ *i_rom*}]

# Extract the relevant information associated with each BRAM
set memProps {}; # clear list, in case you are running this script interactively.
foreach memInst $memInsts {
   set bram_addr_begin  [get_property bram_addr_begin  $memInst]
   set bram_addr_end    [get_property bram_addr_end    $memInst]
   set bram_slice_begin [get_property bram_slice_begin $memInst]
   set bram_slice_end   [get_property bram_slice_end   $memInst]
   set loc              [get_property LOC              $memInst]
   set loc              [string trimleft $loc RAMB36_]

   # build a list in a format which is close to the output we need
   set x "$bram_addr_begin $bram_addr_end $bram_slice_begin $bram_slice_end $loc"
   lappend memProps $x
}

# The next step is important.  The BRAMs need to be sorted.  This is because
# the corresponding memory file is processed in order.
# Furthermore, the comparison order must be:
# 1. increasing order of bram_addr_begin
# 2. decreasing order of bram_slice_begin
proc compare {a b} {
   # compare bram_addr_begin in increasing order
   set a0 [lindex $a 0]
   set b0 [lindex $b 0]
   if {$a0 < $b0} {
      return -1
   } elseif {$a0 > $b0} {
      return 1
   }

   # compare bram_slice_begin in decreasing order
   set a2 [lindex $a 2]
   set b2 [lindex $b 2]
   if {$a2 < $b2} {
      return 1
   } elseif {$a2 > $b2} {
      return -1
   }
   return 0
}
set memSorted [lsort -command compare $memProps]

# Generate output file
set fp [open build/x16.mmi w]

# preamble
puts $fp "<MemInfo Version=\"1\" Minor=\"1\">"
puts $fp "   <Processor Endianness=\"Little\" InstPath=\"dummy\">"
puts $fp "      <AddressSpace Name=\"ROM\" Begin=\"0\" End=\"131071\">"

foreach memInst $memSorted {
   set bram_addr_begin  [lindex $memInst 0]
   set bram_addr_end    [lindex $memInst 1]
   set bram_slice_begin [lindex $memInst 2]
   set bram_slice_end   [lindex $memInst 3]
   set loc              [lindex $memInst 4]
   if {$bram_slice_begin == 7} {
      puts $fp "         <BusBlock>"
   }
   puts $fp "            <BitLane MemType=\"RAMB36\" Placement=\"$loc\">"
   puts $fp "               <DataWidth MSB=\"$bram_slice_end\" LSB=\"$bram_slice_begin\"/>"
   puts $fp "               <AddressRange Begin=\"$bram_addr_begin\" End=\"$bram_addr_end\"/>"
   puts $fp "               <Parity ON=\"false\" NumBits=\"0\"/>"
   puts $fp "            </BitLane>"
   if {$bram_slice_begin == 0} {
      puts $fp "         </BusBlock>"
   }
}

# postamble
puts $fp "      </AddressSpace>"
puts $fp "   </Processor>"
puts $fp "   <Config>"
puts $fp "      <Option Name=\"Part\" Val=\"xc7a100tcsg324-1\"/>"
puts $fp "   </Config>"
puts $fp "</MemInfo>"
close $fp

