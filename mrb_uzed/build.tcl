
set design_name mrb_uzed
set vivado_dir $::env(XILINX_VIVADO)
set origin_dir [file dirname [info script]]

create_project -force proj $origin_dir/proj -part xc7z020clg400-1
set proj_dir [get_property directory [current_project]]

set obj [get_projects proj]
set_property board_part "em.avnet.com:microzed_7020:part0:1.1" $obj
set_property default_lib xil_defaultlib $obj
set_property simulator_language Mixed $obj
set_property ip_cache_permissions "read write" $obj
set_property ip_output_repo "$proj_dir/proj.cache/ip" $obj
set_property sim.ip.auto_export_scripts 1 $obj

if {[string equal [get_filesets -quiet sources_1] ""]} {
    create_fileset -srcset sources_1
}

set obj [get_filesets sources_1]
set path1 "[file normalize "$origin_dir/../ip_repo"]"
set_property ip_repo_paths "$path1" $obj
update_ip_catalog -rebuild

source $origin_dir/src/bd/bd.tcl
set design_name [get_bd_designs]
# make_wrapper -files [get_files ${design_name}.bd] -top -import
# don't import: just make_wrapper for comparison with my version
make_wrapper -files [get_files ${design_name}.bd] -top

set obj [get_filesets sources_1]
set src "$origin_dir/src"
# set file "$src/bd/$design_name/bd/$design_name/${design_name}.bd"
# set file "[file normalize "$file"]"
# add_files -norecurse -fileset $obj $file

set file "$src/hdl/mrb_uzed.v"
set file "[file normalize "$file"]"
add_files -norecurse -fileset $obj $file

set file "$src/hdl/${design_name}_wrapper.v"
set file "[file normalize "$file"]"
add_files -norecurse -fileset $obj $file
set_property top "${design_name}_wrapper" $obj

if {[string equal [get_filesets -quiet constrs_1] ""]} {
    create_fileset -constrset constrs_1
}

set obj [get_filesets constrs_1]
set file "[file normalize "$src/bd/bd.xdc"]"
add_files -norecurse -fileset $obj $file

if {[string equal [get_runs -quiet synth_1] ""]} {
    create_run \
	-name synth_1 \
	-part xc7z020clg400-1 \
	-flow {Vivado Synthesis 2017} \
	-strategy "Vivado Synthesis Defaults" \
	-constrset constrs_1
} else {
    set_property strategy "Vivado Synthesis Defaults" [get_runs synth_1]
    set_property flow "Vivado Synthesis 2017" [get_runs synth_1]
}
set obj [get_runs synth_1]
set_property part xc7z020clg400-1 $obj
current_run -synthesis [get_runs synth_1]

if {[string equal [get_runs -quiet impl_1] ""]} {
    create_run \
	-name impl_1 \
	-part xc7z020clg400-1 \
	-flow {Vivado Implementation 2017} \
	-strategy "Vivado Implementation Defaults" \
	-constrset constrs_1 \
	-parent_run synth_1
} else {
    set_property strategy "Vivado Implementation Defaults" [get_runs impl_1]
    set_property flow "Vivado Implementation 2017" [get_runs impl_1]
}
set obj [get_runs impl_1]
set_property part xc7z020clg400-1 $obj
set_property steps.write_bitstream.args.readback_file 0 $obj
set_property steps.write_bitstream.args.verbose 0 $obj
current_run -implementation [get_runs impl_1]
