package moon.menus;

import moon.menus.obj.main.*;
import moon.toolkit.ChartConvert;
import moon.dependency.scripting.MoonEvent;
import moon.game.submenus.PauseScreen;
import moon.game.*;
import moon.toolkit.level_editor.LevelEditor;

class MainMenu extends FlxTransitionableState
{
    final opt:Array<String> = ['story mode', 'freeplay', 'convert chart yeah', 'mods', 'toolbox', 'settings', 'exit', 'blabla', 'as you know, YOU are welcome here.'];
    var buttons:Array<UIButton> = [];
    var curSelected:Int = 0;
    var maxVisible:Int = 2;

    override public function create()
    {
        super.create();
        
        var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.GRAY);
        add(bg);

        for (i in 0...opt.length)
        {
            var btn = new UIButton(20, 128 + 64 * i, opt[i].toUpperCase());
            add(btn);
            buttons.push(btn);
        }

        changeSelection(0);
        
        if(PlayState.instance != null) PlayState.instance.destroy();
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);
        if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
        if (MoonInput.justPressed(UI_UP)) changeSelection(-1);

        if (MoonInput.justPressed(ACCEPT))
        {
            switch(opt[curSelected].toLowerCase())
			{
				case 'freeplay': openSubState(new Freeplay('bf'));
                case 'settings': openSubState(new Settings());
                case 'convert chart yeah': FlxG.switchState(()->new ChartConvert());
                case 'blabla': openSubState(new JudgementsComboCustomize());
			}
        }

        if(FlxG.keys.justPressed.NINE)
        {
            //test out sticker transition
            openSubState(new StickerSubState(new MainMenu()));
        }
    }

    function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, opt.length - 1);
        Paths.playSFX('ui/scrollMenu.ogg');
        
        for(i in 0...buttons.length)
            buttons[i].selected = i == curSelected;
    }
}