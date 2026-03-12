package moon.menus;

import moon.game.PlayState;
import moon.menus.obj.freeplay.*;
import flixel.addons.effects.FlxSkewedSprite;
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

    public var character:String;

    public var songVolume:Float = 1;
    private var conductor:Conductor;

    public var mainBG:FreeplayBG;
    public var weekBG:FlxSkewedSprite;
    public var thisDJ:FreeplayDJ;

    static var curSelected:Int = 0;

    var songList:Array<SongBase> = [];
    var selector:FreeplaySongSelector;

    public function new(character:String = 'bf')
    {
        super();
        this.character = character;

        mainBG = new FreeplayBG(character);
        add(mainBG.behindBG);

        thisDJ = new FreeplayDJ(character);
        add(thisDJ);

        // TODO: Week-based BG.
        weekBG = new FlxSkewedSprite();
        weekBG.loadGraphic(Paths.image('menus/freeplay/bgs/weekend1'));
        weekBG.scale.set(1.4, 1.4);
        weekBG.antialiasing = true;
        weekBG.updateHitbox();
        weekBG.skew.x = 5;
        weekBG.x = FlxG.width - weekBG.width + 360;
        add(weekBG);

        add(mainBG.frontBG);

        mainBG.script.set('freeplay', this);
        thisDJ.script.set('freeplay', this);

        conductor = new Conductor(0, 4, 4);
        conductor.onBeat.add(function(beat)
        {
            if ((beat % 2 == 0 || conductor.bpm < 120) && thisDJ.canDance)
                thisDJ.anim.play('idle', true);

            if (mainBG.script.exists('onBeat'))
                mainBG.script.get('onBeat')(beat);
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
                        final c = new Chart(song, diff, mix);

                        // Your requested 0-20 difficulty rating (p1 lane notes only)
                        final rating = Chart.calculateDifficultyRating(c.content?.notes ?? []);
                        trace('Difficulty rating for ${song} (${mix}/${diff}): ${rating}/20');

                        songList.push({
                            song: song,
                            mix: mix,
                            difficulty: diff,
                            displayName: c.content?.meta?.displayName ?? song
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

        selector = new FreeplaySongSelector();
        selector.loadSongs(songList, curSelected);
        add(selector);

        if (mainBG.script.exists('onCreate'))
            mainBG.script.call('onCreate');
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

        if (mainBG.script.exists('onUpdate'))
            mainBG.script.get('onUpdate')(elapsed);
    }
}