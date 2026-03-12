package moon.menus.obj.freeplay;

import sys.thread.Mutex;

@:publicFields

/**
 * A simple class that loads a song preview.
 */
class SongPreview
{
	static var instance:MoonSound;
	static var mutex:Mutex = new Mutex();
	static function loadAndPlay(chart:Chart)
	{
		//TODO: check why the game still lags :thinking:
		new lime.app.Future(() ->
        {
        	mutex.acquire();
			if(instance != null)
			{
				if(instance.playing) instance.stop();
				MoonUtils.cancelActiveTwn(instance.fadeTween);
				FlxG.sound.list.remove(instance);

				instance.destroy();
				instance = null;

				//trace('destroying');
			}

			instance = new MoonSound();

			start = chart?.content?.meta?.preview[0] ?? 0;

			//TODO: update this for the new custom difficulties system.
			instance.loadEmbedded(Paths.sound('${chart.song}/${chart.mix}/Inst.ogg', 'songs'));
			FlxG.sound.list.add(instance);
			instance.time = start;

			//trace(start + ' ' + end);

			end = chart?.content?.meta?.preview[1] ?? instance.length;
			instance.volume = 0;
			instance.play();
			instance.fadeIn(1, 0, MoonSettings.callSetting('Music Volume') / 100);
			resetting = false;

			//trace('playing song');
			mutex.release();
		});
	}

	static var start:Float;
	static var end:Float;
	static var resetting:Bool = false;
	static function update(elapsed:Float)
	{
		if(instance != null)
		{
			instance.update(elapsed);
			//trace(instance.time);
			if(instance.playing && instance.time >= end && !resetting)
			{
				//trace('ending');
				resetting = true;
				instance.fadeOut(1, 0, _->{
					resetting = false;
					instance.time = start;
					instance.fadeIn(1, 0, MoonSettings.callSetting('Music Volume') / 100);
				});
			}
		}
	}
}