#!/usr/bin/env python3
"""Pull the in-game HUD pieces out of Spider.swf into a small standalone SWF.

  ffdec-cli -swf2xml Spider.swf spider.xml
  extract_ui.py spider.xml ui.xml        # then: ffdec-cli -xml2swf ui.xml src/_assets/ui.swf

Exports (SymbolClass names, all scripts stripped so they are pure artwork):
  UI_PlayerBox    mcPortrait        player frame: portrait ring, HP / MP / SP bars, name, class, level
  UI_TargetBox    mcPortraitTarget  target frame (used for the boss)
  UI_PartyPanel   PartyPanel        compact party member frame (HP / MP, name)
  UI_ActBar       actBar            the six round skill slots with their cooldown texts
  UI_HitDisplay   hitDisplay        floating damage / heal number      (World.showHitDisplay: hit)
  UI_CritDisplay  critDisplay       floating critical damage number    (crit)
  UI_AvoidDisplay avoidDisplay      "Miss!" / "Dodge!" style text      (miss, dodge, parry, block)
  UI_AutoIcon     sprite 2811       default auto-attack icon (crossed swords)
  UI_SlotBg       ib1               the round skill-slot background (also used behind buff icons)
  UI_OptBg        (Options window) the gold-framed dark window with its close button (350 x 432)
  UI_RedBtn       (Options window) the red glossy button (109 x 28), without its text
  UI_OptTab       GeneralTab        an Options tab (2 frames: tab, selected tab), without its text
  UI_GearBtn      btnOption         the in-game menu bar's gear (Options) button
  UI_CloseX       RedXCloseButton   the round red close button
  UI_TabGameplay  GameTab           the Options tab "Gameplay" (UI_OptTab is "General")
  UI_Arrow        btnLeftQual       the red arrow of the option rows (points up; the game turns it 90 degrees to either side)
  UI_PlayBtn      btnLogin          the ornate red and gold button of the login screen, WITHOUT its "Login" text (STRIP below)
"""
import sys
import xml.etree.ElementTree as ET

ROOTS = {"UI_PlayerBox": 3861, "UI_TargetBox": 3875, "UI_PartyPanel": 3446, "UI_ActBar": 3978,
         "UI_HitDisplay": 3449, "UI_CritDisplay": 3419, "UI_AvoidDisplay": 3494, "UI_AutoIcon": 2811, "UI_SlotBg": 2747,
         "UI_OptBg": 760, "UI_RedBtn": 764, "UI_OptTab": 808, "UI_GearBtn": 3937,
         "UI_TabGameplay": 806, "UI_Arrow": 784, "UI_PlayBtn": 3573, "UI_CloseX": 142}
# text / shapes taken out of a sprite: {sprite id: [character ids placed in it]}
STRIP = {3572: [3566]}
ID_KEYS = ("shapeId", "spriteId", "characterID", "characterId", "buttonId", "fontId", "fontID", "bitmapId", "imageId", "soundId", "videoId")


def tag_id(t):
    if not t.get("type", "").startswith("Define"):
        return None
    for k in ("shapeId", "spriteId", "characterID", "characterId", "buttonId", "fontId", "fontID", "bitmapId", "imageId", "soundId"):
        if t.get(k) is not None:
            return int(t.get(k))
    return None


def main():
    tree = ET.parse(sys.argv[1])
    root = tree.getroot()
    tags = root.find("tags")
    by = {}  # id -> every tag that defines/describes it (a font is DefineFont + DefineFontName + ...)
    for t in tags:
        i = tag_id(t)
        if i is not None:
            by.setdefault(i, []).append(t)

    need, stack = set(), list(ROOTS.values())
    while stack:
        i = stack.pop()
        if i in need or i not in by:
            continue
        need.add(i)
        for tg in by[i]:
            for el in tg.iter():
                for k, v in el.attrib.items():
                    if k in ID_KEYS and v.isdigit() and int(v) in by and int(v) != i:
                        stack.append(int(v))

    out = ET.Element(root.tag, dict(root.attrib, frameCount="1"))
    for child in root:
        if child.tag != "tags":
            out.append(child)
    new_tags = ET.SubElement(out, "tags")
    for t in tags:
        ty = t.get("type", "")
        if ty in ("FileAttributesTag", "SetBackgroundColorTag"):
            new_tags.append(t)
    for t in tags:
        i = tag_id(t)
        if i in need:
            # drop frame scripts / class references: the art only
            for sub in t.iter():
                for k in list(sub.attrib):
                    if k == "className":
                        del sub.attrib[k]
            if i in STRIP:
                for sub in t.iter("subTags"):
                    for tg in list(sub):
                        if tg.get("characterId") and int(tg.get("characterId")) in STRIP[i]:
                            sub.remove(tg)
            new_tags.append(t)
    sc = ET.SubElement(new_tags, "item", {"type": "SymbolClassTag", "forceWriteAsLong": "true"})
    ids = ET.SubElement(sc, "tags")
    names = ET.SubElement(sc, "names")
    for name, i in ROOTS.items():
        ET.SubElement(ids, "item").text = str(i)
        ET.SubElement(names, "item").text = name
    ET.SubElement(new_tags, "item", {"type": "ShowFrameTag", "forceWriteAsLong": "false"})
    ET.ElementTree(out).write(sys.argv[2])
    print(len(need), "characters kept")


if __name__ == "__main__":
    main()
