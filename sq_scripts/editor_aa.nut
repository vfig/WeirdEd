// Editor-only definitions that must be available at script load time.
//
if (Version.IsEditor()!=1) {
    Debug.MPrint("editor_aa.nut: not loading in game mode.");
    return;
}

class EditorTool extends SqRootScript
{
    static function GetCursor() {
        local o = Object.Named("EdCursor");
        if (o==0) {
            o = Object.Create("fnord");
            Object.SetName(o, "EdCursor");
            Property.SetSimple(o, "ModelName", "edcursor");
            Property.SetSimple(o, "RenderType", 2); // Unlit
            Property.Set(o, "DiffPermit", "quest var values", 0);
        }
        return o;
    }

    static function GetMarker(num=1, create=true) {
        local name = "EdMarker"+num;
        local o = Object.Named(name);
        if (o==0 && create) {
            o = Object.Create("fnord");
            Object.SetName(o, name);
            Property.SetSimple(o, "ModelName", "edmarker"+num);
            Property.SetSimple(o, "RenderType", 2); // Unlit
            Property.Set(o, "DiffPermit", "quest var values", 0);
        }
        return o;
    }

    static function FindSelectedObj() {
        // Return the selected objid, or 0 if no object is selected. Requires the
        // `begin_objid` cmd script to be run immediately before, and the `end_objid`
        // cmd script to be run immediately after.

        if (Engine.ConfigIsDefined("ed_debug")) {
            if (! Engine.ConfigIsDefined("ed_do_objid")) {
                print("WARNING: begin_objid setup script was not run!");
                return 0;
            }
        }

        local selected = 0;
        for (local o=1; o<9000; ++o) {
            if (Object.Exists(o)
            && Property.PossessedSimple(o, "HTHModeOverride")) {
                selected = o;
                break;
            }
        }
        return selected;
    }

    static function MarkMultibrushObj(o, mark=true) {
        // Mark the given object for multibrush creation. Requires the
        // `multibrush_objids` cmd script to be run immediately after.
        if (mark) {
            Property.Add(o, "HTHModeOverride");
        } else {
            Property.Remove(o, "HTHModeOverride");
        }
    }

    function OnBeginScript() {
        if (Version.IsEditor()==1) {
            // Cleanup variables that refer to object ids when
            //  going back to edit mode.
            Debug.Command("run_cmd_script editor/cmds/cleanup");
        } else {
            // Self-destruct in game mode.
            Object.Destroy(self);
        }
    }

    function OnPing() {
        local command = message().data;
        if (command==null) {
            print("Error: script command must be first parameter.");
            return;
        }
        local key = "editor_cmd_"+command;
        if (! getroottable().rawin(key)) {
            print("Error: no such script command '"+key+"'.");
            return;
        }
        local fn = getroottable().rawget(key);
        if (typeof(fn)!="function") {
            print("Error: '"+key+"' is not a function.");
            return;
        }
        local result;
        local success = false;
        // try {
            result = fn(message().data2, message().data3);
            success = true;
        // } catch(e) {
        //     result = null;
        //     print("Error running "+key+": "+e);
        // }
        if (success) {
            if (result!=null) {
                Debug.Command("set ed_result "+result);
            } else {
                Debug.Command("unset ed_result");
            }
        }
    }
}

editor_cmd_help_help <- "help,<command>: print help text for a script command.";
function editor_cmd_help(command, param2) {
    if(command==null) {
        editor_cmd_list_commands(null, null);
        return;
    }
    local key = "editor_cmd_"+command+"_help";
    if (getroottable().rawin(key)) {
        print(command+": "+getroottable().rawget(key));
    } else {
        print(command+": No help text available.");
    }
}

editor_cmd_list_commands_help <- "list_commands: list all script commands.";
function editor_cmd_list_commands(_ignored1, _ignored2) {
    local include_re = regexp("^editor_cmd_\\w+$");
    local exclude_re = regexp("^editor_cmd_\\w+(_help)$"); // Weird: this fails to match if i dont parenthesize the _!
    local commands = [];
    foreach (k,v in getroottable()) {
        if (include_re.match(k) && ! exclude_re.match(k)) {
            commands.append(k.slice(11));
        }
    }
    commands.sort();
    print("Available editor script commands:")
    foreach (s in commands) {
        print("  "+s);
    }
}
