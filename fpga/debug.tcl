# This extra tcl-script enables ILA debugging.

# First determine which nets are marked for debugging.
set_property mark_debug true [get_nets [list {i_main/i_via2/porta_i[1]} {i_main/i_via2/porta_i[0]}]]

create_debug_core u_ila_0 ila
set_property C_DATA_DEPTH 16384 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 5 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL false [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 1 [get_debug_cores u_ila_0]

startgroup
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0 ]
set_property C_ADV_TRIGGER true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0 ]
set_property ALL_PROBE_SAME_MU_CNT 4 [get_debug_cores u_ila_0 ]
endgroup

set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list i_clk/cpu_clk ]]
set_property port_width 2 [get_debug_ports u_ila_0/probe0]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {i_main/i_via2/porta_i[0]} {i_main/i_via2/porta_i[1]} ]]

