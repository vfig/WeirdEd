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

editor_cmd_cable_swap_ends_help <- "Swap EdMarker1 and EdMarker2, and reposition EdCursor."
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

class EdCable
{
    static function FindBestDef(width, length) {
        local result = {
            model="",
            width=0,
            length=0,
        };
        local bestLength = 99999;
        foreach (def in EDITOR_CABLE_DEFS) {
            if (def.width!=width)
                continue;
            if (abs(def.length-length)<abs(bestLength-length)) {
                bestLength = def.length;
                result.model = def.model;
                result.width = def.width;
                result.length = def.length;
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

        local result = FindBestDef(width, distance);
        if (result.width==0) {
            print("Error: No matching cable models with width:"+width+".");
            return 0;
        }

        local pos = fromPos+delta*0.5;
        local scale = distance/result.length;
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
        Property.SetSimple(o, "ModelName", result.model);
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
            +" width:"+result.width
            +" length:"+result.length
            +" from:"+fromPos
            +" to:"+toPos
            +" (a distance of "+distance+")");
        return o;
    }
}
