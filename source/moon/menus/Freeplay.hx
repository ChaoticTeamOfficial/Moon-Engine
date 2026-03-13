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

    public var character:String;

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
        instance = this;

        mainBG = new FreeplayBG(character);
        add(mainBG.behindBG);

        thisDJ = new FreeplayDJ(character);
        add(thisDJ);

        Global.scriptSet('behindBG', mainBG.behindBG);
        Global.scriptSet('frontBG', mainBG.frontBG);
        Global.scriptSet('foreground', mainBG.foreground);
        Global.scriptSet('dj', thisDJ);

        // TODO: Week-based BG.
        weekBG = new MoonSprite();
        weekBG.loadGraphic(Paths.image('menus/freeplay/bgs/weekend1'));
        weekBG.scale.set(1.4, 1.4);
        weekBG.antialiasing = true;
        weekBG.updateHitbox();
        weekBG.skew.x = 5;
        weekBG.x = FlxG.width - weekBG.width + 360;
        weekBG.brightness = -0.45;
        add(weekBG);

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
        for (song in Paths.readDir('songs/'))
        {
            for (mix in Paths.readDir('songs/$song/'))
            {
                if (mix == 'events' || !Paths.exists('songs/$song/$mix/', null)) continue;

                for (chart in Paths.readDir('songs/$song/$mix/', ['.json'], true))
                {
                    if (chart.startsWith('chart-'))
                    {
                        final diff = chart.substr(6);
                        songList.push({
                            song: song,
                            mix: mix,
                            difficulty: diff
                        });
                    }
                }
            }
        }

        songList.sort(function(a, b)
        {
            final aL = a.song.toLowerCase();
            final bL = b.song.toLowerCase();
            return (aL < bL) ? -1 : (aL > bL) ? 1 : 0;
        });

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

    function change(num:Int = 0)
    {
        curSelected = flixel.math.FlxMath.wrap(curSelected + num, 0, songList.length - 1);
        selector.changeSelection(num);
        Paths.playSFX('ui/scrollMenu.ogg');
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
            if (selected != null)
            {
                PlayState.songData = {
                    song: selected.song,
                    difficulty: selected.difficulty,
                    mix: selected.mix
                };
                FlxG.switchState(() -> new LoadingScreen());
            }
        }

        Global.scriptCall('onUpdate', [elapsed]);
    }
}