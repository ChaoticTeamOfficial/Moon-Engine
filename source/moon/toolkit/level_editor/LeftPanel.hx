package moon.toolkit.level_editor;

import lime.system.System;

// atp everything here are flxspritegroups '-'

using StringTools;
class LeftPanel extends FlxSpriteGroup
{
    var bg:MoonSprite;
    var buttons:Array<IconButton> = [];
    var buttonMap:Map<String, IconButton> = [];
    var keybinds:Array<{modifiers:Array<String>, key:String, action:String}> = [];

    var editor:LevelEditor = null;
    public function new(editor:LevelEditor)
    {
        super();

        this.editor = editor;

        bg = new MoonSprite().makeGraphic(80, FlxG.height, 0xFF080808);
        add(bg);

        final list = [
            'menu', 'separator', 'joystick', 'videoSettings', 'separator',
            'editDocument', 'openFolder', 'lightbulb', 'space-196', 'settings', 'openDoor'
        ];

        var curY:Float = 24;
        final gap:Float = 10;

        for (i in 0...list.length)
        {
        	// I wish I could switch() this augh
            if (list[i].startsWith('space-'))
                curY += Std.parseFloat(list[i].split('-')[1]);
            else if (list[i] == 'separator')
            {
                var separator = new MoonSprite().makeGraphic(60, 1, FlxColor.WHITE);
                separator.setPosition(bg.x + bg.width / 2 - separator.width / 2, curY);
                separator.active = false;
                separator.alpha = 0.15;
                add(separator);

                curY += 2 + gap;
            }
            else
            {
                var thing = new IconButton(0, 0, 48, 48, list[i]);
                thing.invertShader = editor.invertColors;
                add(thing);
                thing.setPosition(bg.x + bg.width / 2 - thing.width / 2, curY);

                thing.callback = () -> selectButton(thing, list[i]);
                buttons.push(thing);
                buttonMap.set(list[i], thing);

                curY += 48 + gap;
            }
        }

        // define keybinds combo here! They work as cute shortcuts.
        // modifiers are held down, while the key is justPressed to trigger the action.
        // but remember! actions must match button names from the list.
        // and make sure to check your key/modifier match the existing ones at FlxKey!!
        keybinds = [
            {modifiers: ["CONTROL", "SHIFT"], key: "O", action: "openFolder"}
        ];
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // check for keybind triggers
        for (kb in keybinds)
        {
            var modsPressed:Bool = true;
            for (mod in kb.modifiers)
            {
                // checks pressed state for each modifier
                if (!Reflect.getProperty(FlxG.keys.pressed, mod))
                {
                    modsPressed = false;
                    break;
                }
            }

            // check justPressed for the main key
            if (modsPressed && Reflect.getProperty(FlxG.keys.justPressed, kb.key))
            {
                final btn = buttonMap.get(kb.action);
                if (btn != null)
                    selectButton(btn, kb.action);
            }
        }

        if(FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this, this.camera)) close();
    }

    public function selectButton(selected:IconButton, name:String):Void
    {
        for (btn in buttons)
            if (btn != selected)
                btn.isPressed = false;

        switch(name)
        {
        	case 'openFolder':
        		new FlxTimer().start(0.1, _-> selected.isPressed = false);
        		editor.sfx('popupSMALL', true);
        		System.openFile('${System.applicationDirectory}assets/songs/${editor.song}/${editor.mix}');
        }

        //TODO FOR WHEN I HAVE THE  MENUS WORKING: IT SHOULD CLOSE ONE BEFORE OPENING ANOTHER!
        // and dont forget to editor.updates = false or smth
    }

    public function close()
    {
        for (btn in buttons)
            btn.isPressed = false;

        //TODO!!!!!
    }
}