package moon.toolkit.level_editor;

import lime.system.System;

// atp everything here are flxspritegroups '-'

using StringTools;
class LeftPanel extends FlxSpriteGroup
{
    var panelBehind:MoonSprite;
    var bg:MoonSprite;
    var buttons:Array<IconButton> = [];
    var buttonMap:Map<String, IconButton> = [];
    var keybinds:Array<{modifiers:Array<String>, key:String, action:String}> = [];

    var editor:LevelEditor = null;
    public var panelOpen:Bool = false;
    public function new(editor:LevelEditor, ?list:Array<String>)
    {
        super();

        this.editor = editor;

        panelBehind = new MoonSprite().makeGraphic(360, FlxG.height, 0xFF0b0b0b);
        add(panelBehind);
        panelBehind.x = -panelBehind.width;

        bg = new MoonSprite().makeGraphic(80, FlxG.height, 0xFF181818);
        add(bg);
        bg.active = panelBehind.active = false;

        if(list == null || list.length <= 0)
        {
            list = [
                'menu', 'separator', 'joystick', 'videoSettings', 'separator',
                'editDocument', 'openFolder', 'lightbulb', 'space-196', 'settings', 'openDoor', 'space-399999', 'saveL'
            ];
        }

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
                thing.invertShader = editor?.invertColors ?? new InvertColor();
                add(thing);
                thing.setPosition(bg.x + bg.width / 2 - thing.width / 2, curY);

                thing.callback = () -> selectButton(thing, list[i]);
                buttons.push(thing);
                buttonMap.set(list[i], thing);

                curY += 48 + gap;
            }
        }

        panelOpen = false;

        // define keybinds combo here! They work as cute shortcuts.
        // modifiers are held down, while the key is justPressed to trigger the action.
        // but remember! actions must match button names from the list.
        // and make sure to check your key/modifier match the existing ones at FlxKey!!
        keybinds = [
            {modifiers: ["CONTROL"], key: "O", action: "openFolder"},
            {modifiers: ["CONTROL"], key: "S", action: "saveL"}
        ];
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        if (panelOpen && curPanel != "")
        {
            final btn = buttonMap.get(curPanel);
            if (btn != null && !btn.isPressed)
                close();
        }

        panelBehind.x = FlxMath.lerp(panelBehind.x, panelOpen ? bg.x + bg.width : -panelBehind.width, 0.2);

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
            case 'menu', 'layers', 'designServices': 
                updatePanel(name);

            case 'openFolder':
                new FlxTimer().start(0.1, _-> selected.isPressed = false);

                if(editor != null)
                {
                    editor.sfx('popupSMALL', true);

                    System.openFile(System.applicationDirectory + Paths.getPath('songs/${editor.song}/${editor.mix}'));
                }
                else
                {
                    Paths.playSFX('toolkit/general/popupSMALL.wav', false);

                    //TODO: get the correct stage as well
                    System.openFile('${System.applicationDirectory}assets/stages/stage');
                }
            case 'saveL':
                if(editor != null)
                    editor.saveLevel();
        }

        //TODO FOR WHEN I HAVE THE  MENUS WORKING: IT SHOULD CLOSE ONE BEFORE OPENING ANOTHER!
        // and dont forget to editor.updates = false or smth
    }

    public var curPanel:String = '';
    public function updatePanel(name:String)
    {
        curPanel = name;
        panelOpen = true;
    }

    public function close()
    {
        for (btn in buttons)
            btn.isPressed = false;

        panelOpen = false;

        //TODO!!!!!
    }
}