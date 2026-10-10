package ui
{
    import flash.net.SharedObject;

    /**
     * The keys of the game's hotkeys and skills, changeable in Options > Keybinds and remembered in this browser (SharedObject).
     * Fixed keys: Enter (chat / Play), Esc (back), the numeric keypad 1-6 (extra skill keys).
     */
    public class Keys
    {
        public static const ACTIONS:Array = [
            {id: "s1", label: "Skill 1", key: 49}, {id: "s2", label: "Skill 2", key: 50}, {id: "s3", label: "Skill 3", key: 51},
            {id: "s4", label: "Skill 4", key: 52}, {id: "s5", label: "Skill 5", key: 53}, {id: "s6", label: "Skill 6", key: 54},
            {id: "sprint", label: "Sprint (hold, then click)", key: 32}, {id: "target", label: "Next target", key: 9},
            {id: "hints", label: "Hints on / off", key: 72}, {id: "party", label: "Party HP on / off", key: 71},
            {id: "chart", label: "Show / hide chart", key: 67}, {id: "music", label: "Music on / off", key: 77},
            {id: "fullscreen", label: "Fullscreen", key: 70}, {id: "pause", label: "Pause", key: 80},
            {id: "up", label: "Move up", key: 87}, {id: "left", label: "Move left", key: 65},
            {id: "down", label: "Move down", key: 83}, {id: "right", label: "Move right", key: 68}
        ];

        private static var map:Object = null;

        private static function load():void
        {
            if (map != null)
            {
                return;
            }
            map = {};
            for each (var a:Object in ACTIONS)
            {
                map[a.id] = a.key;
            }
            try
            {
                var so:SharedObject = SharedObject.getLocal("ultrasim_keys");
                for each (var b:Object in ACTIONS)
                {
                    var v:* = so.data[b.id];
                    if (v is Number && v > 0)
                    {
                        map[b.id] = int(v);
                    }
                }
            }
            catch (err:Error)
            {
            }
        }

        private static function save():void
        {
            try
            {
                var so:SharedObject = SharedObject.getLocal("ultrasim_keys");
                for (var id:String in map)
                {
                    so.data[id] = map[id];
                }
                so.flush();
            }
            catch (err:Error)
            {
            }
        }

        public static function code(id:String):int
        {
            load();
            return map[id];
        }

        /** the action a key press is bound to ("" when none) */
        public static function actionFor(key:int):String
        {
            load();
            for (var id:String in map)
            {
                if (map[id] == key)
                {
                    return id;
                }
            }
            return "";
        }

        /** bind a key; the action that had it gets the key this one had (a swap), so no key does two things */
        public static function bind(id:String, key:int):void
        {
            load();
            var other:String = actionFor(key);
            if (other != "" && other != id)
            {
                map[other] = map[id];
            }
            map[id] = key;
            save();
        }

        public static function reset():void
        {
            map = null;
            try
            {
                SharedObject.getLocal("ultrasim_keys").clear();
            }
            catch (err:Error)
            {
            }
            load();
        }

        /** a key's name as it is shown on a button */
        public static function name(key:int):String
        {
            if (key >= 48 && key <= 57)
            {
                return String.fromCharCode(key);
            }
            if (key >= 65 && key <= 90)
            {
                return String.fromCharCode(key);
            }
            if (key >= 96 && key <= 105)
            {
                return "Num " + (key - 96);
            }
            if (key >= 112 && key <= 123)
            {
                return "F" + (key - 111);
            }
            var names:Object = {8: "Backspace", 9: "Tab", 13: "Enter", 16: "Shift", 17: "Ctrl", 18: "Alt", 20: "Caps", 27: "Esc", 32: "Space",
                33: "PgUp", 34: "PgDn", 35: "End", 36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 45: "Ins", 46: "Del",
                106: "Num *", 107: "Num +", 109: "Num -", 110: "Num .", 111: "Num /", 186: ";", 187: "=", 188: ",", 189: "-", 190: ".",
                191: "/", 192: "`", 219: "[", 220: "\\", 221: "]", 222: "'"};
            return names[key] != undefined ? names[key] : "Key " + key;
        }
    }
}
