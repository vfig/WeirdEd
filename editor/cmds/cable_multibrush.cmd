run_cmd_script editor/cmds/begin_objid
script_ping Ed,cable_find_group
ifndef ed_abort run_cmd_script editor/cmds/multibrush_objids
run_cmd_script editor/cmds/end_objid
unset ed_abort
