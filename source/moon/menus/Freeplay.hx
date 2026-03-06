package moon.menus;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import moon.game.PlayState;
import moon.menus.obj.freeplay.*;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSubState;

using StringTools;

enum FreeplayTransition
{
    FADE;
    STICKERS;
    RANK;
    NONE;
}

//TODO: Doccument freeplay.
class Freeplay extends FlxSubState
{
    public static var appearType:FreeplayTransition = NONE;

    var texts:Array<FlxText> = [];
    
    public var character:String;

    public var songVolume:Float = 1;
    private var conductor:Conductor;

    public var mainBG:FreeplayBG;
    public var weekBG:FlxSkewedSprite;
    public var thisDJ:FreeplayDJ;
    static var curSelected:Int = 0;
	var songList:Array<{song:String, mix:String, difficulty:String}> = [];
    public function new(character:String = 'bf')
    {
        //TODO: make animations for entering the freeplay
        super();
        this.character = character;

        mainBG = new FreeplayBG(character);

        add(mainBG.behindBG);

        thisDJ = new FreeplayDJ(character);
        add(thisDJ);

        //TODO: Week based BG.
        weekBG = new FlxSkewedSprite();
        weekBG.loadGraphic(Paths.image('menus/freeplay/bgs/weekend1'));
        weekBG.scale.set(1.4, 1.4);
        weekBG.antialiasing = true;
        weekBG.updateHitbox();
        weekBG.skew.x = 5;
        add(weekBG);

        weekBG.x = FlxG.width - weekBG.width + 360;
        add(mainBG.frontBG);

        mainBG.script.set('freeplay', this);
        thisDJ.script.set('freeplay', this);

        conductor = new Conductor(0, 4, 4);
        conductor.onBeat.add(function(beat)
        {
            if ((beat % 2 == 0 || conductor.bpm < 120) && thisDJ.canDance)
                thisDJ.anim.play("idle", true);

            if(mainBG.script.exists('onBeat')) mainBG.script.get('onBeat')(beat);
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
                        songList.push({song: song, mix: mix, difficulty: chart.substr(6)});
                }
            }
        }

        songList.sort(function(a, b) {
            final aLower = a.song.toLowerCase();
            final bLower = b.song.toLowerCase();
            return (aLower < bLower) ? -1 : (aLower > bLower) ? 1 : 0;
        });

        var yPos = 0.0;
        for (entry in songList)
        {
            var displayName = '(${entry.mix.toUpperCase()}) •-- ${entry.song}-${entry.difficulty}';
            var text = new FlxText(0, yPos, 0, displayName, 24);
            text.font = Paths.font('phantomuff/full.ttf');
			text.antialiasing = true;
            texts.push(text);
            text.screenCenter(X);
            text.x += 64;
            add(text);
            yPos += text.height;
        }

        if(mainBG.script.exists('onCreate')) mainBG.script.call('onCreate');
        
        changeSelection(0);
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if(MoonInput.justPressed(UI_DOWN)) changeSelection(1);
        if(MoonInput.justPressed(UI_UP)) changeSelection(-1);
        
        if(MoonInput.justPressed(ACCEPT))
        {
            // Get the selected entry directly
            final selectedEntry = songList[curSelected];
            if (selectedEntry != null)
            {
                PlayState.songData = {song: selectedEntry.song, difficulty: selectedEntry.difficulty, mix: selectedEntry.mix};
                FlxG.switchState(()->new LoadingScreen());
            }
        }
        
        if(mainBG.script.exists('onUpdate')) mainBG.script.get('onUpdate')(elapsed);
    }
    
    function changeSelection(change:Int = 0):Void
    {
        curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, texts.length - 1);
        Paths.playSFX('ui/scrollMenu.ogg');

        for(i in 0...texts.length)
            texts[i].color = (i == curSelected) ? FlxColor.CYAN : FlxColor.WHITE;
    }
}