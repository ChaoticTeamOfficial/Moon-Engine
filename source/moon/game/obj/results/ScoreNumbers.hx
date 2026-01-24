package moon.game.obj.results;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;

class ScoreNumbers extends FlxSpriteGroup
{
	public var digits:Array<MoonSprite> = [];

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		var currentX:Float = 0;
		for (i in 0...10)
		{
			var numSpr = new MoonSprite(currentX, 0);
			numSpr.frames = Paths.getSparrowAtlas('ingame/results/UI/score-digital-numbers');

			final yea = ['ZERO', 'ONE', 'TWO', 'THREE', 'FOUR', 'FIVE', 'SIX', 'SEVEN', 'EIGHT', 'NINE'];
			for (j in 0...10)
				numSpr.animation.addByPrefix('$j', '${yea[j]} DIGITAL', 24, false);

			numSpr.animation.addByPrefix('disabled', 'DISABLED');
			numSpr.centerAnimations = true;
			numSpr.playAnim('disabled');
			numSpr.antialiasing = true;

			add(numSpr);
			digits.push(numSpr);

			currentX += numSpr.width - 32;
		}
	}

	public function setScore(score:Int, skipAnims:Bool = false):Void
	{
		var correctDigits:Array<Int> = [for (_ in 0...10) -1];
		var tempScore:Int = score;
		var pos:Int = 9;

		while (true)
		{
			correctDigits[pos] = tempScore % 10;
			tempScore = Std.int(tempScore / 10);
			if (tempScore <= 0) break;

			pos--;
			if (pos < 0) break;
		}

		var scrambleTimers:Map<MoonSprite, FlxTimer> = [];

		for (digSpr in digits)
			scrambleTimers.set(digSpr, new FlxTimer().start( (skipAnims) ? 0.00001 : 0.04, _ -> digSpr.playAnim('${FlxG.random.int(0, 9)}', true), 0));

		new FlxTimer().start((skipAnims) ? 0.00001 : 1.4, _ ->
		{
			var delay:Float = 0;
			var step:Float = (skipAnims) ? 0.00001 : 0.05;

			for (i in 0...10)
			{
				new FlxTimer().start(delay, _ ->
				{
					final spr = digits[i];

					if (scrambleTimers.exists(spr))
					{
						scrambleTimers[spr].cancel();
						scrambleTimers.remove(spr);
					}

					spr.playAnim((correctDigits[i] == -1) ? "disabled" : '${correctDigits[i]}');

					if(!skipAnims)
					{	
						spr.y -= 12;
						FlxTween.tween(spr, {y: spr.y + 12}, 0.2, {ease: FlxEase.expoOut});
					}
				});

				delay += step;
			}
		});
	}
}