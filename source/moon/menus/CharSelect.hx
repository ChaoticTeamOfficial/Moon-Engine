package moon.menus;

import moon.menus.obj.charSelect.*;
import moon.game.obj.*;

class CharSelect extends FlxState
{
	var playlist:SyncPlaylist;

    final funkinChars = [
        'locked', 'locked', 'locked',
        'pico',   'bf',     'locked',
        'locked', 'locked', 'locked'
    ];

    public var conductor:Conductor;
    public var cursor:Cursor;
    public var grid:CharGrid;
    public var player:Character;

    public var background:FlxGroup = new FlxGroup();

    public var isLightsOff:Bool = false;
    override public function create():Void
    {
        super.create();
        generateBackground();

        playlist = new SyncPlaylist().loadFromDirectory("music/menus/charSelect");

        conductor = new Conductor(180);

        player = new Character(0,0, 'bf/bfChill', conductor);
        background.add(player);
        player.screenCenter();
        player.overrideAnims = ['select', 'deselect', 'slide-in'];
        player.holdDuration = 4;

        cursor = new Cursor();
        add(cursor);

        grid = new CharGrid(3, 100);
        grid.setupGrid(funkinChars);
        add(grid);
        grid.screenCenter();
        grid.x += 16;

        var nametag = new Nametag(0, 0, 'bf');
        add(nametag);

        // on changing a selection...
        grid.onChange.add((dir)->{
            Paths.playSFX('menus/charSelect/CS_select.ogg', true);

            final song = 'stayFunky-${CharGrid.curChar.toLowerCase()}'; 
            playlist.focusSong = playlist.sounds.exists(song) ? song : 'stayFunky';

            nametag.character = CharGrid.curChar;
            nametag.scale.set(0.5, 0.5);
            nametag.updateHitbox();
            nametag.screenCenter(X);
            nametag.x += 400;
            nametag.y = barThing.y + barThing.height / 2 - nametag.height / 2;

            player.forcePlayAnim('slide-in', true);

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

        grid.scroll(0);
        conductor.onBeat.add(beatHit);
        playlist.play();
        playlist.volume = MoonSettings.callSetting("Music Volume") / 100;

        FlxG.camera.fade(FlxColor.BLACK, 1.5, true);
        FlxG.camera.scroll.y = -800;
        FlxG.camera.zoom = 7; //siete
        FlxTween.tween(FlxG.camera.scroll, {y: 0}, 2.8, {ease: FlxEase.circOut});
	}

    var back:MoonSprite;
    var crowd:MoonSprite;
    var stage:MoonSprite;
    var d2:MoonSprite;
    var barThing:MoonSprite;
    var speakers:MoonSprite;
	private function generateBackground():Void
    {
        back = new MoonSprite(-150, -160).loadGraphic(Paths.image('menus/charSelect/BG'));
        back.scale.set(1.4, 1.4);
        back.scrollFactor.set(0.8, 0.8);
        add(back);
        back.active = false;

        crowd = new MoonSprite(-75, FlxG.height / 2 - 140);
        crowd.frames = Paths.getSparrowAtlas('menus/charSelect/crowd');
        crowd.scale.set(0.9, 0.9);
        crowd.animation.addByPrefix('crowd', 'crowd', 24, true);
        crowd.animation.play('crowd');
        add(crowd);

        stage = new MoonSprite(-20, FlxG.height / 2 + 20);
        stage.frames = Paths.getSparrowAtlas('menus/charSelect/stage');
        stage.animation.addByPrefix('loopy', 'stage full instance 1', 16, true);
        stage.animation.play('loopy');
        add(stage);

        add(background);

        barThing = new MoonSprite(0, 50).makeGraphic(FlxG.width + 100, 100, 0xFF848214);
        barThing.alpha = 0.5;
        barThing.screenCenter(X);
        barThing.blend = SUBTRACT;
        barThing.active = false;
        add(barThing);

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
        d3.active = false;
        add(d3);

        speakers = new MoonSprite();
        speakers.centerAnimations = true;
        speakers.frames = Paths.getSparrowAtlas('menus/charSelect/speakers');
        speakers.animation.addByPrefix('bump', 'Speakers ALL', 24, false);
        add(speakers);
        speakers.screenCenter();
        speakers.y += 232;
    }

    var transitioning:Bool = false;
    var songTween:FlxTween;
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

        if(!transitioning)
        {
            if(MoonInput.justPressed(UI_LEFT)) grid.scroll(-1);
            if(MoonInput.justPressed(UI_RIGHT)) grid.scroll(1);
            if(MoonInput.justPressed(UI_UP)) grid.scroll(-grid.columns);
            if(MoonInput.justPressed(UI_DOWN)) grid.scroll(grid.columns);
            if(MoonInput.justPressed(ACCEPT) && !transitioning)
            {
                if(CharGrid.curChar.toLowerCase() == 'locked')
                {
                    FlxG.camera.shake(0.004, 0.2);
                    Paths.playSFX('menus/charSelect/CS_locked.ogg');
                }
                else
                {
                    transitioning = true;
                    Paths.playSFX('menus/charSelect/CS_confirm.ogg');
                    cast(grid.members[CharGrid.curSelected], PixelIcon).playAnim('select', true);

                    TweenUtils.cancelTwn(songTween);

                    player.forcePlayAnim('select', true);
                    songTween = FlxTween.tween(playlist, {pitch: 0}, 1.3, {ease: FlxEase.quadInOut, onComplete: _ ->{
                        playlist.volume = 0;
                        Global.allowInputs = false;

                        FlxG.camera.fade(FlxColor.BLACK, 0.6, false);
                        FlxTween.tween(FlxG.camera.scroll, {y: -340}, 1.3, {ease: FlxEase.backInOut, onComplete: _->{
                            FlxG.switchState(()-> new MainMenu());
                            Global.allowInputs = true;
                        }});
                    }});
                }
            }
        }

        if(MoonInput.justPressed(BACK) && transitioning)
        {
            transitioning = false;

            final ico = cast(grid.members[CharGrid.curSelected], PixelIcon);
            ico.playAnim('select', true, true);
            ico.animation.onFinish.addOnce(_ -> ico.playAnim('idle', true));

            player.forcePlayAnim('deselect', true);

            TweenUtils.cancelTwn(songTween);
            songTween = FlxTween.tween(playlist, {pitch: 1}, 0.6, {ease: FlxEase.quadInOut});
        }

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
        {
            speakers.playAnim('bump', true);
            d2.scale.set(1.02, 1.02);
        }
    }
}