ifdef ed_stop_cmd run_cmd_script editor/cmds/stop.cmd
set ed_go_cmd run_cmd_script editor/cmds/cable_segment.cmd
set ed_go2_cmd run_cmd_script editor/cmds/cable_redo_last.cmd
set ed_stop_cmd run_cmd_script editor/cmds/cable_finish.cmd
script_ping Ed,cable_start
find_obj EdCursor
