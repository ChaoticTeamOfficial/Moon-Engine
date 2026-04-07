package moon.menus.obj;

import flixel.group.FlxSpriteGroup;
import openfl.display.BlendMode;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.group.FlxGroup;
import flixel.util.FlxColor;
#if !doc
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.audioclip.frontends.LimeAudioClip;
#end
import lime.media.AudioSource;

@:publicFields
class BarsVisualizer extends FlxSpriteGroup
{
	#if !doc
    var analyzer:SpectralAnalyzer;
	#end
    var barCount:Int = 0;
    var debugMode:Bool = false;

    public function new(barCount:Int = 16)
    {
        super();
        this.barCount = barCount;

		for (i in 0...barCount)
		{
			var spr = new MoonSprite((i / barCount) * FlxG.width, 0).makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, FlxG.height, 0xffffffff);
            spr.origin.set(0, FlxG.height);
            spr.blend = ADD;
            spr.alpha = 0.6;
			add(spr);
            //spr = new FlxSprite((i / barCount) * FlxG.width, 0).makeGraphic(Std.int((1 / barCount) * FlxG.width) - 4, 1, 0xaaffffff);
            //peakLines.add(spr);
		}
    }
	
	public function setAudioSource(src:AudioSource)
    {
		#if !doc
		analyzer = new SpectralAnalyzer(new LimeAudioClip(src), barCount + 1, 0.1, 10);

        #if sys
        analyzer.fftN = 256;
        #end
		#end
    }

    @:generic
    static inline function min<T:Float>(x:T, y:T):T
        return x > y ? y : x;

    override function draw()
    {
		#if !doc
        var levels = analyzer.getLevels();

        for (i in 0...min(this.members.length, levels.length))
            this.members[i].scale.y = flixel.math.FlxMath.lerp(this.members[i].scale.y, levels[i].value, FlxG.elapsed * 24);
		#end
        super.draw();
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
    }
}