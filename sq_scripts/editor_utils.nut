// Editor-only global functions and utilities.
//
if (Version.IsEditor()!=1) {
    Debug.MPrint("editor_utils.nut: not loading in game mode.");
    return;
}

DEGREES_TO_RADIANS <- (3.14159/180.0);
RADIANS_TO_DEGREES <- (180.0/3.14159);

function getdefault(table, key, def=null) {
    // Return `table`[`key`], or `def` if the table does not have the key.
    if (key in table)
        return table[key];
    else
        return def;
}

function config_get_int(name, def=null) {
    local ref = int_ref();
    if (Engine.ConfigGetInt(name, ref)) {
        return ref.tointeger();
    }
    return def;
}

function config_get_float(name, def=null) {
    local ref = float_ref();
    if (Engine.ConfigGetFloat(name, ref)) {
        return ref.tofloat();
    }
    return def;
}

function config_get_str(name, def=null) {
    local ref = string();
    if (Engine.ConfigGetRaw(name, ref)) {
        return ref.tostring();
    }
    return def;
}

RE_INTEGER <- regexp("-?[0-9]+");
RE_DESIGNNOTEPARAM <- regexp("([A-Za-z_][A-Za-z_0-9]*)=(\"[^\"]*\"|[^;]*);\\s*");

function parseInteger(s) {
    // Return an integer parsed from string `s`, or null on failure.
    if (s==null) return null;
    if (s=="") return null;
    s = s.tostring();
    if (! RE_INTEGER.match(s)) return null;
    return s.tointeger();
}

function parseObject(s) {
    // Return an object id by name/id from string `s`, or 0 on failure.
    if (s==null) return 0;
    if (s=="") return 0;
    local objid;
    s = s.tostring();
    if (RE_INTEGER.match(s)) {
        objid = s.tointeger();
        if (! Object.Exists(objid)) return 0;
    } else {
        objid = Object.Named(s);
        if (objid==0) return 0;
    }
    return objid;
}

function parseArchetype(s) {
    // Return an archetype id by name/id from string `s`, or 0 on failure.
    local objid = parseObject(s);
    if (objid>0) return 0;
    return objid;
}

function parseConcrete(s) {
    // Return a concrete id by name/id from string `s`, or 0 on failure.
    local objid = parseObject(s);
    if (objid<0) return 0;
    return objid;
}

function parseDesignNote(s,lowercase=false) {
    // Return a table of key/value pairs from a Design Note style string `s`.
    // If `lowercase` is true, keys will be lowercased. Return an empty
    // table on failure.
    local params = {};
    if (s==null || (typeof s)!="string") return params;
    local start=0;
    local captures = RE_DESIGNNOTEPARAM.capture(s);
    while (captures!=null) {
        local k = s.slice(captures[1].begin,captures[1].end);
        if (lowercase)
            k = k.tolower();
        local v = s.slice(captures[2].begin,captures[2].end);
        params[k] <- v;
        captures = RE_DESIGNNOTEPARAM.capture(s, captures[0].end);
    }
    return params;
}

function AllSubArchetypes(arch) {
    // Return an array of all descendent archetypes of `arch`.
    local archetypes = [];
    local queue = [arch];
    local s = sLink();
    while (queue.len()>0) {
        local arch = queue.pop();
        foreach (link in Link.GetAll("~MetaProp", arch)) {
            s.LinkGet(link);
            arch = s.dest;
            if (arch<0) {
                archetypes.append(arch);
                queue.push(arch);
            }
        }
    }
    return archetypes;
}

function AllDirectConcretes(arch) {
    // Return an array of all direct concrete descendents of `arch`.
    local concretes = [];
    local s = sLink();
    foreach (link in Link.GetAll("~MetaProp", arch)) {
        s.LinkGet(link);
        local o = s.dest;
        if (o>0) {
            concretes.append(o);
        }
    }
    return concretes;
}

function AllConcretes(arch) {
    // Return an array of all direct concrete descendents of `arch`.
    local concretes = AllDirectConcretes(arch);
    local archetypes = AllSubArchetypes(arch);
    foreach (arch in archetypes) {
        concretes.extend(AllDirectConcretes(arch));
    }
    return concretes;
}
