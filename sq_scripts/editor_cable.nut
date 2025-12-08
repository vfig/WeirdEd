// Editor-only Cable generator. Use `script_ping EditorMakeCable` for help.
//
if (Version.IsEditor()!=1) {
    Debug.MPrint("editor_cable.nut: not loading in game mode.");
    return;
}

editor_cmd_cable_start_help <- "Place EdMarker1 at EdCursor position.";
function editor_cmd_cable_start(_ignored1, _ignored2) {
    local cursor = EditorTool.GetCursor();
    local marker1 = EditorTool.GetMarker(1);
    local marker3 = EditorTool.GetMarker(3);
    if (cursor==0 || marker1==0 || marker3==0)
        return;
    local pos = Object.Position(cursor);
    if (pos.x==0 && pos.y==0 && pos.z==0) {
        // We just got a cursor spawned in at the origin, probably not really
        // meant to start here.
        print("## Move cursor to cable origin point and start again.");
        return;
    }
    Object.Teleport(marker1, vector(), vector(), cursor);
    Object.Teleport(marker3, vector(), vector(), cursor);
    print("## Move cursor to cable endpoint and press go (G)");
}

editor_cmd_cable_segment_help <- "Create a Cable between EdMarker1 and EdCursor."
function editor_cmd_cable_segment(param1, _ignored2) {
    local width = config_get_int("ed_cable_width", 1);

    local adjustid = 0;
    if (param1=="redo") {
        adjustid = config_get_int("ed_make_last_id", 0);
        if (adjustid==0)
            return;
    }
    local isRedo = (adjustid!=0);

    local cursor = EditorTool.GetCursor();
    local marker1 = EditorTool.GetMarker(1);
    local marker2 = EditorTool.GetMarker(2);
    if (cursor==0 || marker1==0 || marker2==0)
        return;

    local fromPos = isRedo? Object.Position(marker2) : Object.Position(marker1);
    local toPos = Object.Position(cursor);
    local objid = EdCable.MakeSegment(fromPos, toPos, width, adjustid);

    if (! isRedo) {
        Debug.Command("set ed_make_last_id "+objid);
        Object.Teleport(marker2, vector(), vector(), marker1);
    }
    Object.Teleport(marker1, vector(), vector(), cursor);

    print("## Press go (G) for next, redo (Shift+G) to adjust last, stop (Ctrl+G) to finish.");
}

editor_cmd_cable_segment_help <- "Clean up EdMarker1 and EdMarker2."
function editor_cmd_cable_finish(_ignored1, _ignored2) {
    local marker1 = EditorTool.GetMarker(1, false);
    local marker2 = EditorTool.GetMarker(2, false);
    local marker3 = EditorTool.GetMarker(3, false);
    if (marker1) Object.Destroy(marker1);
    if (marker2) Object.Destroy(marker2);
    if (marker3) Object.Destroy(marker3);

    print("## Cable stopped. Have a nice day!");
}

editor_cmd_cable_swap_ends_help <- "Swap EdMarker1 and EdMarker3, and reposition EdCursor."
function editor_cmd_cable_swap_ends(_ignored1, _ignored2) {
    local cursor = EditorTool.GetCursor();
    local marker1 = EditorTool.GetMarker(1, false);
    local marker3 = EditorTool.GetMarker(3, false);
    if (cursor==0 || marker1==0 || marker3==0)
        return;

    // Redo won't work after a swap, so prevent it.
    local marker2 = EditorTool.GetMarker(2, false);
    if (marker2) Object.Destroy(marker2);
    Debug.Command("unset ed_make_last_id");

    Object.Teleport(cursor, vector(), vector(), marker3);
    Object.Teleport(marker3, vector(), vector(), marker1);
    Object.Teleport(marker1, vector(), vector(), cursor);
}

editor_cmd_cable_resume_help <- "Set markers around selected Cable.";
function editor_cmd_cable_resume(_ignored1, _ignored2) {
    local objid = EditorTool.FindSelectedObj();
    local info = EdCable.GetSegmentInfo(objid);
    if (info==null) {
        Debug.Command("set ed_abort");
        return;
    }

    local cursor = EditorTool.GetCursor();
    local marker1 = EditorTool.GetMarker(1);
    local marker2 = EditorTool.GetMarker(2);
    local marker3 = EditorTool.GetMarker(3);
    if (cursor==0 || marker1==0 || marker2==0 || marker3==0)
        return;

    Object.Teleport(cursor, info.position[1], info.facing[1], 0);
    Object.Teleport(marker1, info.position[1], info.facing[1], 0);
    Object.Teleport(marker2, info.position[0], info.facing[0], 0);
    Object.Teleport(marker3, info.position[0], info.facing[0], 0);

    Debug.Command("set ed_make_last_id "+objid);
    Debug.Command("set ed_cable_width "+info.width);

    print("## Move cursor to cable endpoint and press go (G)");
}

function editor_cmd_cable_find_group(_ignored1, _ignored2) {
    local objid = EditorTool.FindSelectedObj();
    local group = EdCable.FindGroup(objid);
    if (group==null) {
        Debug.Command("set ed_abort");
        return;
    }

    foreach (o in group) {
        MarkMultibrushObj(o);
    }
}


class EdCable
{
    static function FindBestDef(width, length) {
        local result = null;
        local bestLength = 99999;
        foreach (def in EDITOR_CABLE_DEFS) {
            if (def.width!=width)
                continue;
            if (abs(def.length-length)<abs(bestLength-length)) {
                bestLength = def.length;
                result = clone def;
            }
        }
        return result;
    }

    static function FindDefByModel(model) {
        local result = null;
        foreach (def in EDITOR_CABLE_DEFS) {
            if (def.model==model) {
                result = clone def;
                break;
            }
        }
        return result;
    }

    static function MakeSegment(fromPos, toPos, width, adjustid=0) {
        local arch = Object.Named("Cable");
        if (arch==0) {
            print("Error: No 'Cable' archetype.");
            return 0;
        }

        local delta = (toPos-fromPos);
        local distance = delta.Length();
        if (fabs(distance)<1.0) {
            print("Error: Distance is too small.");
            return 0;
        }

        local def = FindBestDef(width, distance);
        if (def==null) {
            print("Error: No matching cable models with width:"+width+".");
            return 0;
        }

        local pos = fromPos+delta*0.5;
        local scale = distance/def.length;
        local dir = delta.GetNormalized();
        local dirxy = vector(dir.x,dir.y,0.0);
        local fac = vector();
        fac.y = -atan2(dir.z,dirxy.Length())*RADIANS_TO_DEGREES;
        fac.z = atan2(dir.y,dir.x)*RADIANS_TO_DEGREES;

        local didCreate = false;
        local o;
        if (adjustid!=0
        && Object.Exists(adjustid)
        && Object.InheritsFrom(adjustid, arch)) {
            o = adjustid;
        } else {
            o = Object.Create(arch);
            didCreate = true;
        }
        if (o==0) {
            print("Error: Failed to create concrete object.");
            return 0;
        }
        Object.Teleport(o, pos, fac, 0);
        Property.SetSimple(o, "ModelName", def.model);
        Property.SetSimple(o, "Scale", vector(1,1,1)*scale);

        // If it inherited PhysType, then it will have the wrong auto dimensions,
        // and even using BeginCreate/EndCreate doesn't fix it. So we reinitialise
        // physics now after model and scale are set.
        if (Physics.HasPhysics(o)) {
            Property.Remove(o, "PhysType");
            Property.Add(o, "PhysType");
        }

        local didWhat = (didCreate? "Created" : "Adjusted");
        print(didWhat+" a "+Object.GetName(arch)+" ("+o+")"
            +" width:"+def.width
            +" length:"+def.length
            +" from:"+fromPos
            +" to:"+toPos
            +" (a distance of "+distance+")");
        return o;
    }

    static function GetSegmentInfo(o) {
        if (o==0 || ! Object.InheritsFrom(o, "Cable"))
            return null;

        local model = Property.Get(o, "ModelName");
        local def = FindDefByModel(model)
        if (def==null)
            return null;

        local tail = Object.ObjectToWorld(o, vector(-0.5*def.length,0,0));
        local head = Object.ObjectToWorld(o, vector(0.5*def.length,0,0));

        return {
            width=def.width,
            position=[tail, head],
            facing=[vector(), vector()],
        };
    }

    static function FindGroup(o) {
        if (o==0 || ! Object.InheritsFrom(o, "Cable"))
            return null;

        local makeKey = function(v) {
            // Quantize to nearest half-foot.
            local x = (2*v.x+0.5).tointeger();
            local y = (2*v.y+0.5).tointeger();
            local z = (2*v.z+0.5).tointeger();
            return (""+x+","+y+","+z);
        }

        local lookup = {};
        local cableKeys = {};
        local allCables = AllConcretes("Cable");
        foreach (cable in allCables) {
            local info = GetSegmentInfo(cable);
            if (info==null) continue;
            local keys = [];
            for (local i=0; i<2; ++i) {
                local k = makeKey(info.position[i]);
                keys.append(k);
                if (k in lookup) {
                    lookup[k].append(cable);
                } else {
                    lookup[k] <- [cable];
                }
            }
            cableKeys[cable.tointeger()] <- keys;
        }

        local openKeys = [];
        local closedKeys = {};
        local connectedCables = {};
        local addCable = function(cable) {
            connectedCables[cable.tointeger()] <- true;
            foreach (k in cableKeys[cable.tointeger()]) {
                if (! (k in closedKeys)) {
                    openKeys.push(k);
                }
            }
        }
        addCable(o);
        while (openKeys.len()) {
            local k = openKeys.pop();
            closedKeys[k] <- true;
            foreach (cable in lookup[k]) {
                addCable(cable);
            }
        }

        local group = [];
        foreach (cable,_ in connectedCables) {
            group.append(cable);
        }
        return group;
    }
}
