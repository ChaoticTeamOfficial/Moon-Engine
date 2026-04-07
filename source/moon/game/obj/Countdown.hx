package moon.game.obj;

using StringTools;
@:publicFields
/**
 * Static class that triggers a countdown. Don't forget to `init()` it first!
 */
class Countdown
{
	static var audioSuffix:String = "";
	static var graphicSuffix:String = "";
	static var countdownActive:Bool = false;
	static var countdownNum:Int = 4;
	static var group:FlxGroup;
	private static var conductor:Conductor;

	static function init(conductor:Conductor, grp:FlxGroup)
	{
		Countdown.group = grp;
		Countdown.conductor = conductor;

		conductor.onBeat.add(checkBeats);
	}

	/**
	 * Allows the countdown to start on the next beat.
	 * @param graphicSuffix a suffix for the countdown image, useful for skins.
	 * @param audioSuffix a suffix for the countdown sfx, useful for skins.
	 */
	static function performCountdown(graphicSuffix:String = "", audioSuffix:String = "")
	{
		Countdown.graphicSuffix = graphicSuffix;
		Countdown.audioSuffix = audioSuffix;
		countdownNum = 4;

		countdownActive = true;
	}

	static function checkBeats(beat:Float)
	{
		if(!countdownActive) return;

		countdownNum--;
		if(countdownNum >= 0)
		{
			trace('[COUNTDOWN] Performing! ($countdownNum)', "INFO");
			Paths.playSFX('game/countdown/intro-$countdownNum$audioSuffix.ogg');

			final path = 'ingame/UI/countdown/graphic-$countdownNum$graphicSuffix';
			if(Paths.exists('images/$path.png'))
			{
				var countdownSpr = new MoonSprite().loadGraphic(Paths.image(path));
				countdownSpr.screenCenter();
				group.add(countdownSpr);
				countdownSpr.antialiasing = (path.contains('pixel'));

				FlxTween.tween(countdownSpr, {alpha: 0}, conductor.crochet / 1500, {onComplete: _->countdownSpr.destroy()});
			}
		}
		else
		{
			trace('[COUNTDOWN] The countdown has finished.', "INFO");
			countdownActive = false;
		}
	}
}