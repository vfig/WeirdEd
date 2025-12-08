ifdef ed_stop_cmd run_cmd_script editor/cmds/stop.cmd
run_cmd_script editor/cmds/begin_objid
script_ping Ed,cable_resume
run_cmd_script editor/cmds/end_objid
ifndef ed_abort set ed_go_cmd run_cmd_script editor/cmds/cable_segment.cmd
ifndef ed_abort set ed_go2_cmd run_cmd_script editor/cmds/cable_redo_last.cmd
ifndef ed_abort set ed_stop_cmd run_cmd_script editor/cmds/cable_finish.cmd
ifndef ed_abort find_obj EdCursor
unset ed_abort
