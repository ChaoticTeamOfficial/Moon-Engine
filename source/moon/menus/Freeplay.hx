package moon.menus;

import moon.game.PlayState;
import moon.menus.obj.freeplay.*;
import flixel.FlxG;
import flixel.FlxSubState;
import moon.backend.data.Chart;

using StringTools;

enum FreeplayTransition
{
    FADE;
    STICKERS;
    RANK;
    NONE;
}

// TODO: Document Freeplay.
class Freeplay extends FlxSubState
{
    public static var appearType:FreeplayTransition = NONE;
    public static var instance:Freeplay;

    public var character:String; // this is used as the preferred mix (e.g. "bf")

    public var songVolume:Float = MoonSettings.callSetting('Music Volume') / 100;
    static var curSelected:Int = 0;
    var songList:Array<SongBase> = [];

    public var conductor:Conductor;
    public var mainBG:FreeplayBG;
    public var weekBG:MoonSprite;
    public var thisDJ:FreeplayDJ;
    public var selector:FreeplaySongSelector;
    public var stars:DifficultyStars;

    public function new(character:String = 'bf')
    {
        super();
        this.character = character;
        Global.allowInputs = false;
        instance = this;

        mainBG = new FreeplayBG(character);
        add(mainBG.behindBG);

        thisDJ = new FreeplayDJ(character);
        add(thisDJ);

        Global.scriptSet('behindBG', mainBG.behindBG);
        Global.scriptSet('frontBG', mainBG.frontBG);
        Global.scriptSet('foreground', mainBG.foreground);
        Global.scriptSet('dj', thisDJ);

        weekBG = new MoonSprite();
        weekBG.loadGraphic(Paths.image('menus/freeplay/bgs/random-bf'));
        weekBG.scale.set(1.4, 1.4);
        weekBG.antialiasing = true;
        weekBG.updateHitbox();
        weekBG.skew.x = -20;
        weekBG.x = FlxG.width + weekBG.width + 360;
        weekBG.brightness = -1;
        add(weekBG);

        FlxTween.tween(weekBG, {x: FlxG.width - weekBG.width + 360, "skew.x": 5}, 0.7, {ease: FlxEase.expoOut, onComplete: _->{
            weekBG.brightness = 0.69;
            FlxTween.tween(weekBG, {brightness: -0.45}, 0.35);
            Global.scriptCall('onTransitionEnd', []);
        }});

        add(mainBG.frontBG);

        Global.scriptSet('freeplay', this);

        conductor = new Conductor(0, 4, 4);
        conductor.onBeat.add((beat) ->
        {
            if ((beat % 2 == 0 || conductor.bpm < 120) && thisDJ.canDance)
                thisDJ.playAnim('idle', true);

            Global.scriptCall('onBeat', [beat]);
        });

        add(mainBG.foreground);

        songList = getMixSonglist('all', character);
        //trace(songList);

        stars = new DifficultyStars(0, 632, 24, 0.055);
        stars.screenCenter(X);
        stars.x += 280;
        stars.difficulty = 0;

        selector = new FreeplaySongSelector();
        selector.loadSongs(songList, curSelected);
        add(selector);
        add(stars);

        Global.scriptCall('onCreate');
    }

    /**
     * Gets the song list for a week, preferring the given mix.
     * @param week The week name. It can also be 'all' if you want all available songs.
     * @param preferredMix The character mix.
     */
    public function getMixSonglist(week:String, preferredMix:String):Array<SongBase>
    {
        final filtered:Array<SongBase> = [];

        for (song in SongLibrary.get().weekSonglist(week))
            if (song.mix == preferredMix)
                filtered.push(song);

        return filtered;
    }

    function change(num:Int = 0)
    {
        curSelected = flixel.math.FlxMath.wrap(curSelected + num, 0, songList.length - 1);
        selector.changeSelection(num);
        Paths.playSFX('ui/scrollMenu.ogg');

        Global.scriptCall('onScroll');
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        if(FlxG.sound.music != null)
        {
            if(FlxG.sound.music.playing) conductor.time = FlxG.sound.music.time;
            if(FlxG.sound.music.fadeTween == null || (FlxG.sound.music.fadeTween != null && !FlxG.sound.music.fadeTween.active)) 
                FlxG.sound.music.volume = FlxMath.lerp(FlxG.sound.music.volume, songVolume, elapsed * 8);
        }

        if (MoonInput.justPressed(UI_DOWN)) change(1);
        if (MoonInput.justPressed(UI_UP)) change(-1);       

        if (MoonInput.justPressed(ACCEPT))
        {
            final selected = selector.getSelected();
            Global.allowInputs = false;

            //reset the AFK timer and the "canDance" so it doesn't fuck out the anims 
            thisDJ.canDance = false;
            thisDJ.AFK_TIMER = 0;
            thisDJ.playAnim('confirm', true);

            Paths.playSFX('ui/confirmMenu.ogg');

            selector.getSelectedItem().doConfirm();
            Global.scriptCall('onConfirm');

            new FlxTimer().start(1.79, _->{
                if (selected != null)
                {
                    PlayState.songData = {
                        song: selected.song,
                        difficulty: selected.difficulty,
                        mix: selected.mix
                    };
                    FlxG.switchState(() -> new LoadingScreen());
                    Global.allowInputs = true;
                }
            });
        }

        Global.scriptCall('onUpdate', [elapsed]);
    }
}