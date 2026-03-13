package moon.menus.obj.freeplay;

import sys.thread.Mutex;

@:publicFields

/**
 * A simple class that loads a song preview.
 */
class SongPreview
{
	static function loadAndPlay(chart:Chart)
	{
		//TODO: check why the game still lags :thinking:
		new lime.app.Future(() ->
        {
			if(FlxG.sound.music != null)
			{
				if(FlxG.sound.music.playing) FlxG.sound.music.stop();
				MoonUtils.cancelActiveTwn(FlxG.sound.music.fadeTween);

				FlxG.sound.music.destroy();
				FlxG.sound.music = null;

				//trace('destroying');
			}

			FlxG.sound.music = new MoonSound();

			start = chart?.content?.meta?.preview[0] ?? 0;

			//TODO: update this for the new custom difficulties system.
			FlxG.sound.playMusic(Paths.exists('songs/${chart.song}/${chart.mix}/Inst.ogg') ? Paths.sound('${chart.song}/${chart.mix}/Inst.ogg', 'songs') : Paths.sound('menus/freeplayRandom.ogg'));
			FlxG.sound.music.time = start;

			//trace(start + ' ' + end);

			end = chart?.content?.meta?.preview[1] ?? FlxG.sound.music.length;
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.play();
			FlxG.sound.music.fadeIn(1, 0, Freeplay.instance.songVolume);

			//TODO: get the uhh metadata for the random song.
			if(Freeplay.instance.conductor != null) 
				Freeplay.instance.conductor.changeBpmAt(0, chart?.content?.meta?.bpm ?? 145, chart?.content?.meta?.timeSignature[0] ?? 4, chart?.content?.meta?.timeSignature[0] ?? 4);

			resetting = false;

			//trace('playing song');
		}, true);
	}

	static var start:Float;
	static var end:Float;
	static var resetting:Bool = false;
	static function update(elapsed:Float)
	{
		if(FlxG.sound.music != null)
		{
			//trace(FlxG.sound.music.time);
			if(FlxG.sound.music.playing && FlxG.sound.music.time >= end && !resetting)
			{
				//trace('ending');
				resetting = true;
				FlxG.sound.music.fadeOut(1, 0, _->{
					resetting = false;
					FlxG.sound.music.time = start;
					FlxG.sound.music.fadeIn(1, 0, Freeplay.instance.songVolume);
				});
			}
		}
	}
}