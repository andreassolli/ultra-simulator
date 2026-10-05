#!/usr/bin/env python3
"""Strip the optional parts AvatarMC.hideOptionalParts() hides (cape, backhair, robe,
backrobe, weapon, weaponOff, weaponFist, weaponFistOff, shield) from the mcSkel
timeline (symbol 2408) so exports show the same default character the recovered
project's TestMain displays.   clean_skeleton.py in.xml out.xml"""
import sys
import xml.etree.ElementTree as ET

HIDE_DEPTHS = {11, 13, 17, 23, 25, 46, 55, 61, 79}  # instance names at these depths in mcSkel
tree = ET.parse(sys.argv[1])
for tag in tree.getroot().find("tags"):
    if tag.get("type") == "DefineSpriteTag" and tag.get("spriteId") == "2408":
        sub = tag.find("subTags")
        for s in list(sub):
            t = s.get("type", "")
            if (t.startswith("PlaceObject") or t.startswith("RemoveObject")) and s.get("depth") and int(s.get("depth")) in HIDE_DEPTHS:
                sub.remove(s)
tree.write(sys.argv[2])
