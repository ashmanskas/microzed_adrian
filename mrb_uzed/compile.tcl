open_project proj/proj.xpr
update_compile_order -fileset sources_1
reset_run synth_1
launch_runs impl_1 -to_step write_bitstream

# wait for compilation to complete (it runs asynchronously)
wait_on_run -timeout 30 impl_1

