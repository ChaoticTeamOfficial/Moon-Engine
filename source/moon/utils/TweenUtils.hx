package moon.utils;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.FlxG;

using StringTools;

@:publicFields
/**
 * A class meant for tween utilities.
 */
class TweenUtils
{
	/**
	 * An array containing all the available easings.
	 */
	static var easeList:Array<String> = [
		// I tried using reflect but didn't quite work weirdly.
		// so yea
		// absolute cinema
		'INSTANT',
		'linear',
		'smoothStepIn',
		'smoothStepOut',
		'smoothStepInOut',
		'smootherStepIn',
		'smootherStepOut',
		'smootherStepInOut',
		'sineIn',
		'sineOut',
		'sineInOut',
		'quadIn',
		'quadOut',
		'quadInOut',
		'cubeIn',
		'cubeOut',
		'cubeInOut',
		'quartIn',
		'quartOut',
		'quartInOut',
		'quintIn',
		'quintOut',
		'quintInOut',
		'circIn',
		'circOut',
		'circInOut',
		'expoIn',
		'expoOut',
		'expoInOut',
		'backIn',
		'backOut',
		'backInOut',
		'elasticIn',
		'elasticOut',
		'elasticInOut',
		'bounceIn',
		'bounceOut',
		'bounceInOut'
	];

	/**
	 * Function that resolve an ease string to a FlxEase.
	 * @param easeName the ease name.
	 */
	static function resolveEase(easeName:String):EaseFunction
	{
		if (easeName == null || easeName == "" || easeName.toLowerCase().contains('linear')) return FlxEase.linear; // safechecks are nice!

		var name:String = easeName;
		switch (name.toLowerCase())
		{
			case "instant":
				return null;
			default:
				if (
					name.toLowerCase() != "linear"
					&& !StringTools.endsWith(name, "In")
					&& !StringTools.endsWith(name, "Out")
					&& !StringTools.endsWith(name, "InOut")
				) name += "InOut";

				var func = Reflect.field(FlxEase, name);

				// just some last failsafes
				if (func == null)
				{
					name = StringTools.replace(name, "InOut", "Out");
					func = Reflect.field(FlxEase, name);
				}

				if (func == null) func = FlxEase.expoInOut;

				// trace('resolved ease: $name', "DEBUG");

				return func;
		}
	}

	/**
	 * Cancels a tween that's active, preventing overlapping tweens if you're going to play another.
	 * @param tween The active tween.
	 */
	static function cancelTwn(tween:FlxTween) if (tween != null && tween.active) tween.cancel();

	/**
	 * Cancels a timer that's active, preventing overlapping timers if you're going to play another.
	 * @param timer The active timer.
	 */
	static function cancelTmr(timer:FlxTimer) if (timer != null && timer.active) timer.cancel();
}
