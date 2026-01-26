package moon.menus;

import moon.menus.obj.charSelect.*;

class CharSelect extends FlxState
{
	var playlist:SyncPlaylist;

    final funkinChars = [
        'locked', 'locked', 'locked',
        'pico',   'bf',     'locked',
        'locked', 'locked', 'locked'
    ];

    var conductor:Conductor;

    var cursor:Cursor;
    var grid:CharGrid;

    public var isLightsOff:Bool = false;

    private var scrollSnd:MoonSound;
    override public function create():Void
    {
        super.create();
        generateBackground();

        playlist = new SyncPlaylist().loadFromDirectory("music/menus/charSelect");

        conductor = new Conductor(180);

        cursor = new Cursor();
        add(cursor);

        grid = new CharGrid(3, 100);
        grid.setupGrid(funkinChars);
        add(grid);
        grid.screenCenter();
        grid.x += 16;

        scrollSnd = new MoonSound().loadEmbedded(Paths.sound('menus/charSelect/CS_select.ogg', 'sounds'));
        scrollSnd.volume = MoonSettings.callSetting('SFX Volume') / 100;
        grid.onChange.add((dir)->{
            if(scrollSnd.playing) scrollSnd.stop();
            if(dir != 0) scrollSnd.play();

            final song = 'stayFunky-${CharGrid.curChar.toLowerCase()}'; 
            playlist.focusSong = playlist.sounds.exists(song) ? song : 'stayFunky';

            if(CharGrid.curChar.toLowerCase() == 'locked' && !isLightsOff)
            {
                isLightsOff = true;
                back.alpha = 0.2;
                FlxSpriteUtil.setBrightness(crowd, -0.8);
                FlxSpriteUtil.setBrightness(stage, -0.5);
                Paths.playSFX('menus/charSelect/lightsOff.wav');
            }
            else if (CharGrid.curChar.toLowerCase() != 'locked' && isLightsOff)
            {
                isLightsOff = false;
                back.alpha = 1;

                for(heh in [crowd, stage])
                FlxSpriteUtil.setBrightness(heh, 0);
            }

           // trace(song, "DEBUG");
        });
        FlxG.sound.list.add(scrollSnd);

        grid.scroll(0);
        conductor.onBeat.add(beatHit);
        playlist.play();
	}

    var back:MoonSprite;
    var crowd:MoonSprite;
    var stage:MoonSprite;
    var d2:MoonSprite;
	private function generateBackground():Void
    {
        back = new MoonSprite(-150, -160).loadGraphic(Paths.image('menus/charSelect/BG'));
        back.scale.set(1.2, 1.2);
        back.scrollFactor.set(0.2, 0.2);
        add(back);
        back.active = false;

        crowd = new MoonSprite(-75, FlxG.height / 2 - 130);
        crowd.frames = Paths.getSparrowAtlas('menus/charSelect/crowd');
        crowd.scale.set(0.8, 0.8);
        crowd.animation.addByPrefix('crowd', 'crowd', 24, true);
        crowd.animation.play('crowd');
        crowd.scrollFactor.set(0.5, 0.5);
        add(crowd);

        stage = new MoonSprite(-20, FlxG.height / 2 + 20);
        stage.frames = Paths.getSparrowAtlas('menus/charSelect/stage');
        stage.animation.addByPrefix('loopy', 'stage full instance 1', 16, true);
        stage.animation.play('loopy');
        add(stage);

        var d1 = new MoonSprite();
        d1.centerAnimations = true;
        d1.frames = Paths.getSparrowAtlas('menus/charSelect/dipshitBlur');
        d1.animation.addByPrefix('loop', 'CHOOSE vertical offset instance 1', 24, true);
        add(d1);
        d1.playAnim('loop', true);
        d1.screenCenter();

        d2 = new MoonSprite();
        d2.centerAnimations = true;
        d2.frames = Paths.getSparrowAtlas('menus/charSelect/dipshitBacking');
        d2.animation.addByPrefix('loop', 'CHOOSE horizontal offset instance 1', 24, true);
        add(d2);
        d2.playAnim('loop', true);
        d2.screenCenter();

        var d3 = new MoonSprite().loadGraphic(Paths.image('menus/charSelect/chooseDipshit'));
        d3.screenCenter();
        add(d3);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        conductor.time = playlist.time;
        
        // here for testing purposes.
        // dont forget to remove it, silly toffee!
        /*if(FlxG.keys.justPressed.Q)
        	playlist.focusSong = 'stayFunky';
        if(FlxG.keys.justPressed.W)
        	playlist.focusSong = 'stayFunky-pico';
        if(FlxG.keys.justPressed.E)
        	playlist.focusSong = 'stayFunky-luna';
        if(FlxG.keys.justPressed.R)
        	playlist.focusSong = 'stayFunky-mano';
        if(FlxG.keys.justPressed.T)
        	playlist.focusSong = 'stayFunky-locked';*/

        // not the best way to do this, but whatever,,
        if(MoonInput.justPressed(UI_LEFT)) grid.scroll(-1);
        if(MoonInput.justPressed(UI_RIGHT)) grid.scroll(1);
        if(MoonInput.justPressed(UI_UP)) grid.scroll(-grid.columns);
        if(MoonInput.justPressed(UI_DOWN)) grid.scroll(grid.columns);

        final sel = grid.members[CharGrid.curSelected];
        cursor.follow(sel.x + sel.width / 2, sel.y + sel.height / 2, elapsed);

        FlxG.camera.zoom = FlxMath.lerp(FlxG.camera.zoom, 1, elapsed * 2);
        d2.scale.x = d2.scale.y = FlxMath.lerp(d2.scale.x, 1, elapsed * 4);
    }

    function beatHit(beat:Float)
    {
        grid.beat(beat);
        if(beat % 4 == 0)
            FlxG.camera.zoom += 0.008;

        if(beat % 2 == 0)
            d2.scale.set(1.02, 1.02);
    }
}