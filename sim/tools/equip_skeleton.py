#!/usr/bin/env python3
"""Equip item SWFs (as FFDec XML) on the mcSkel skeleton (symbol 2408) the way
AQWorlds/AvatarMC.as does at runtime: each body-part holder's first child is swapped
for the item's class.

  equip_skeleton.py <assets.xml> <out.xml> Armor.xml:20000 Cape.xml:30000 Helm.xml:40000 Weapon.xml:50000

Each item's character ids are shifted by the given offset and merged into the output.
Parts hidden by AvatarMC.hideOptionalParts() stay hidden unless an item provides them.
"""
import sys
import xml.etree.ElementTree as ET

SKEL = "2408"
DEPTH = {  # instance depths in mcSkel (names assigned on first placement)
    "backhair": 11, "cape": 13, "weaponOff": 17, "weaponFistOff": 23, "backrobe": 25,
    "robe": 46, "shield": 55, "weapon": 61, "weaponFist": 79,
}
# AvatarMC.loadArmorPieces(): class-name suffix -> body parts whose holder child is replaced
SUFFIX_PARTS = {
    "Chest": ["chest"], "Hip": ["hip"], "FootIdle": ["idlefoot"], "Foot": ["frontfoot", "backfoot"],
    "Shoulder": ["frontshoulder", "backshoulder"], "Hand": ["fronthand", "backhand"],
    "Thigh": ["frontthigh", "backthigh"], "Shin": ["frontshin", "backshin"],
    "Robe": ["robe"], "RobeBack": ["backrobe"],
}


def is_def(tag):
    return tag.get("type", "").startswith("Define") and tag.get("type") not in ("DefineSceneAndFrameLabelDataTag",)


def def_id(tag):
    for k in ("shapeId", "spriteId", "characterID", "characterId", "buttonId", "fontId"):
        if tag.get(k):
            return int(tag.get(k))
    return None


def load_item(path, offset):
    root = ET.parse(path).getroot()
    tags = root.find("tags")
    defined = {def_id(t) for t in tags if is_def(t) and def_id(t) is not None}
    classes = {}
    for t in tags:
        if t.get("type") == "SymbolClassTag":
            for i, n in zip(t.find("tags"), t.find("names")):
                classes[n.text] = int(i.text) + offset
    defs = []
    for t in tags:
        if not is_def(t) or def_id(t) is None:
            continue
        for el in t.iter():
            for k, v in list(el.attrib.items()):
                if k.lower().endswith("id") and k != "depth" and v.isdigit() and int(v) in defined:
                    el.set(k, str(int(v) + offset))
        defs.append(t)
    return defs, classes


def main():
    tree = ET.parse(sys.argv[1])
    root = tree.getroot()
    tags = root.find("tags")
    by = {}
    for t in tags:
        if is_def(t) and def_id(t) is not None:
            by[def_id(t)] = t
    skel = by[int(SKEL)]
    sub = skel.find("subTags")

    first = {}
    for s in sub:
        if s.get("type", "").startswith("PlaceObject") and s.get("name") and s.get("name") not in first:
            first[s.get("name")] = (int(s.get("characterId")), int(s.get("depth")))

    classes, merged = {}, []
    for spec in sys.argv[3:]:
        path, off = spec.rsplit(":", 1)
        defs, cl = load_item(path, int(off))
        merged += defs
        classes.update(cl)
    insert_at = 1
    for i, d in enumerate(merged):
        tags.insert(insert_at + i, d)

    def swap_child(holder_id, new_id, named=None):
        for s in by[holder_id].find("subTags"):
            if s.get("type", "").startswith("PlaceObject") and s.get("characterId") and (named is None or s.get("name") == named):
                s.set("characterId", str(new_id))
                return True
        return False

    def find(suffix):
        hits = [n for n in classes if n.endswith(suffix) and "." not in n and "_fla" not in n]
        return classes[hits[0]] if hits else None

    equipped = []
    for suffix, parts in SUFFIX_PARTS.items():
        cid = find(suffix)
        if cid is None:
            continue
        for p in parts:
            swap_child(first[p][0], cid)
        equipped.append(suffix)
        if suffix == "Foot":  # frontfoot.visible = false
            hide = {first["frontfoot"][1]}
        if suffix == "Robe":
            DEPTH.pop("robe", None)
        if suffix == "RobeBack":
            DEPTH.pop("backrobe", None)
    head = find("Head")
    if head:
        swap_child(first["head"][0], head, named="face")
        equipped.append("Head")

    # Helm / Cape / Weapon items export one main class (the item itself)
    def main_class(path_hint):
        names = [n for n in classes if classes[n] >= path_hint and "." not in n and "_fla" not in n and not n.endswith("_backhair")]
        return names

    removed_hair = False
    for spec in sys.argv[3:]:
        path, off = spec.rsplit(":", 1)
        base = path.split("/")[-1].lower()
        off = int(off)
        names = [n for n, i in classes.items() if off <= i < off + 10000 and "." not in n and "_fla" not in n]
        if "helm" in base and names:
            item = [n for n in names if not n.endswith("_backhair")][0]
            # head.helm holder is shared with head.hair: swap its child, hide hair
            helm_holder = [int(s.get("characterId")) for s in by[first["head"][0]].find("subTags") if s.get("name") == "helm"][0]
            swap_child(helm_holder, classes[item])
            for s in list(by[first["head"][0]].find("subTags")):
                if s.get("name") == "hair":
                    by[first["head"][0]].find("subTags").remove(s)
            bh = [n for n in names if n.endswith("_backhair")]
            if bh:
                swap_child(first["backhair"][0], classes[bh[0]])
                DEPTH.pop("backhair", None)
            equipped.append("Helm:" + item)
        elif "cape" in base and names:
            swap_child(first["cape"][0], classes[names[0]], named="cape")
            DEPTH.pop("cape", None)
            equipped.append("Cape:" + names[0])
        elif "weapon" in base and names:
            swap_child(first["weapon"][0], classes[names[0]])
            DEPTH.pop("weapon", None)
            equipped.append("Weapon:" + names[0])

    drop = set(DEPTH.values())
    if "Foot" in equipped:
        drop.add(first["frontfoot"][1])
    n = 0
    for s in list(sub):
        t = s.get("type", "")
        if (t.startswith("PlaceObject") or t.startswith("RemoveObject")) and s.get("depth") and int(s.get("depth")) in drop:
            sub.remove(s)
            n += 1
    print("equipped:", equipped, "| removed placements:", n)
    tree.write(sys.argv[2])


if __name__ == "__main__":
    main()
