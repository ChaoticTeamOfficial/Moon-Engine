package moon.game.obj;

import flixel.group.FlxSpriteGroup;
import openfl.display.BlendMode;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
#if !doc
import funkin.vis.dsp.SpectralAnalyzer;
import funkin.vis.audioclip.frontends.LimeAudioClip;
#end
import lime.media.AudioSource;

//TODO: Softcode this?

@:publicFields
class ABotVisualizer extends FlxSpriteGroup
{
	#if !doc
    var analyzer:SpectralAnalyzer;
	#end
    var barCount:Int = 7;
    var currentLevels:Array<Float> = [];

    public function new()
    {
        super();

        var positionX:Array<Float> = [0, 59, 56, 66, 54, 52, 51];
        var positionY:Array<Float> = [0, -8, -3.5, -0.4, 0.5, 4.7, 7];

        for (index in 1...(barCount + 1))
        {
            var posX:Float = 0;
            var posY:Float = 0;
            for (j in 0...index)
            {
                posX += positionX[j];
                posY += positionY[j];
            }

            var spr = new MoonSprite(posX, posY);
            spr.frames = Paths.getSparrowAtlas('abot/aBotViz', 'characters');
            spr.antialiasing = true;
            spr.animation.addByPrefix('VIZ', 'viz${index}0', 0, false);
            spr.animation.play('VIZ');
            spr.animation.curAnim.curFrame = 5;
            add(spr);
            currentLevels.push(0.0);
        }
		
		resetVis();
    }
	
    public function setAudioSource(sound:MoonSound)
    {
		#if !doc
    	@:privateAccess
        analyzer = new SpectralAnalyzer(new LimeAudioClip(sound._channel.__audioSource), barCount, 0.1, 60);
        analyzer.minDb = -75;
        analyzer.maxDb = -30;
        analyzer.maxFreq = 22000;
        analyzer.minFreq = 10;

        #if sys
        analyzer.fftN = 256;
        #end
		#end
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
		
		#if !doc

        if (analyzer == null) return;

        var levels = analyzer.getLevels();

        for (i in 0...barCount)
        {
        	// so the first two bars are both about the low frequencies
        	// makes them more powerful... somehow!
            var rawValue = levels[(i < 2) ? 0 : i].value;

            // boost low frequencies more (i=0 is lowest freq iirc)
            // i mean, it looks waaayy too boring if I don't boost em!
            // so might as well do this :)
            rawValue *= 1.5 - (i / (barCount - 1)) * 0.6;
            rawValue = rawValue > 1.0 ? 1.0 : rawValue;

            currentLevels[i] = rawValue;

            var preFrame:Int = Math.round(currentLevels[i] * 6) - 1;
            preFrame = Std.int(Math.max(0, Math.min(5, preFrame)));

            members[i].animation.curAnim.curFrame = Std.int(Math.abs(preFrame - 5));
            members[i].visible = true;
        }
		
		#end
    }
	
	public function resetVis()
	{
		for(i in 0...members.length)
		{
			final spr = members[i];
			spr.animation.curAnim.curFrame = 5;
			
			FlxTween.tween(spr.animation.curAnim, {curFrame: 0}, 0.1, {startDelay: 0.05 * i, onComplete:_->{
				FlxTween.tween(spr.animation.curAnim, {curFrame: 5}, 0.1, {startDelay: 0.2});
			}});
		}
	}
}