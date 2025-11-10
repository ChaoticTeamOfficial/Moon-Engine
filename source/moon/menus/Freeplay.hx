package moon.menus;

import flixel.util.FlxColor;
import flixel.text.FlxText;
import moon.game.PlayState;
import moon.menus.obj.freeplay.*;
import flixel.addons.effects.FlxSkewedSprite;
import flixel.FlxG;
import flixel.FlxSubState;

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

    // placeholder song list >:3
    // song => mi
    var s:Map<String, String> = [
        'gerson' => 'gerson',
        'amusia' => 'bf',
        'blammed' => 'pico',
        'darnell' => 'bf',
        'monochrome' => 'bf',
        'senpai' => 'noimix',
        'roses' => 'noimix',
        'thorns' => 'noimix',
        'shitno' => 'bf',
        'silly billy' => 'bf',
        'nacreous-snowmelt' => 'bf'
    ];
    var texts:Array<FlxText> = [];
    
    public var character:String;

    public var songVolume:Float = 1;
    private var conductor:Conductor;

    public var mainBG:FreeplayBG;
    public var weekBG:FlxSkewedSprite;
    public var thisDJ:FreeplayDJ;
    var curSelected:Int = 0;

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

        var yPos = 0.0;
        for (song => mix in s)
        {
            var text = new FlxText(0, yPos, 0, '$song-$mix', 32);
            text.font = Paths.font('vcr.ttf');
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
            for(song => mix in s)
                if(texts[curSelected].text == '$song-$mix') FlxG.switchState(()->new PlayState(song, 'hard', mix));
        }
        
        if(mainBG.script.exists('onUpdate')) mainBG.script.get('onUpdate')(elapsed);
    }
    
    function changeSelection(change:Int = 0):Void
    {
        curSelected = flixel.math.FlxMath.wrap(curSelected + change, 0, texts.length - 1);
        Paths.playSFX('ui/scrollMenu');

        for(i in 0...texts.length)
            texts[i].color = (i == curSelected) ? FlxColor.CYAN : FlxColor.WHITE;
    }
}