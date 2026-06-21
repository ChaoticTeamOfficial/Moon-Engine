package moon.menus;

import moon.menus.obj.main.*;
import moon.toolkit.ChartConvert;
import moon.dependency.scripting.MoonEvent;
import moon.game.submenus.PauseScreen;
import moon.game.*;
import moon.toolkit.level_editor.LevelEditor;

class MainMenu extends FlxTransitionableState
{
    final opt:Array<String> = ['test replay','test playlist', 'story menu', 'freeplay', 'convert chart yeah', 'mods', 'settings', 'test script state'];
    var buttons:Array<UIButton> = [];
    var curSelected:Int = 0;
    var maxVisible:Int = 2;

    override public function create()
    {
        super.create();

        Global.clearScriptList();
        Global.allowInputs = true;

        var bg = new MoonSprite().loadGraphic(Paths.image('menus/menuDesat'));
        bg.color = 0xFFffd863;
        bg.x += 132;
        add(bg);

        var blackBar = new MoonSprite().makeGraphic(564, FlxG.height, FlxColor.BLACK);
        blackBar.skew.x = 10;
        blackBar.x -= 100;
        add(blackBar);

        var welcome = new FlxText();
        welcome.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 48, CENTER);
        welcome.text = '- WELCOME TO FUNKIN\'! -';
        add(welcome);
        welcome.color = 0xFFffd863;
        welcome.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
        welcome.letterSpacing = -2;
        welcome.y = 116;

        for (i in 0...opt.length)
        {
            var btn = new UIButton(20, 128 + 64 * i, opt[i].toUpperCase());
            add(btn);
            buttons.push(btn);
        }
        
        changeSelection(0);

        // TODO: remove this and make the title state window dance stop there.
        // its here due to the gf easter egg being able to window dance.
        //MoonSettings.updateWindow();
        
        PlayState.replaysToSave = [];
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
                case 'test replay':
                    /*PlayState.songData = {
                        song: 'darnell',
                        difficulty: 'nightmare',
                        mix: 'pico'
                    }

                    final rep = PlayState.loadReplay('replays/darnell_nightmare_pico_1772948785000.mrp');
                    if (rep != null)
                        FlxG.switchState(() -> new PlayState(rep));
                    FlxG.sound.music.stop();*/
                    openSubState(new ReplayMenu());

                case 'test playlist':
                    /*PlayState.queuePlaylist([
                        { song: "blammed", difficulty: "erect", mix: "bf" },
                        { song: "cocoa", difficulty: "nightmare", mix: "bf" },
                        { song: "green skies", difficulty: "hard", mix: "bf" }
                    ]);
                    FlxG.switchState(() -> new LoadingScreen());
                    */
                    openSubState(new PlaylistMode());

                case 'mods': FlxG.switchState(() -> new ModMenu());
				case 'freeplay': openSubState(new Freeplay('bf'));
                case 'settings': openSubState(new Settings());
                case 'convert chart yeah': //FlxG.switchState(()->new ChartConvert());
                    openSubState(new moon.toolkit.ChartConverterSubState());
                case 'blabla': openSubState(new JudgementsComboCustomize());
                case 'test script state': FlxG.switchState(()->new MoonScriptedState('MyCoolScriptedState'));
                case 'story menu': FlxG.switchState(()->new Story());
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