package moon.menus.obj.freeplay;

@:publicFields
/**
 * A simple class that loads a song preview.
 */
class SongPreview
{
	static var start:Float;
	static var end:Float;
	static var resetting:Bool = false;
	static var active:Bool = false;
	private static var _loadGen:Int = 0;
	private static var _prevSoundKey:String = null;

	static function loadAndPlay(chart:Chart)
	{
		if (FlxG.sound.music != null) TweenUtils.cancelTwn(FlxG.sound.music.fadeTween);

		resetting = false;

		final gen = ++_loadGen;

		new lime.app.Future(() ->
		{
			if (gen != _loadGen) return null;

			if (FlxG.sound.music != null)
			{
				if (FlxG.sound.music.playing) FlxG.sound.music.stop();
				TweenUtils.cancelTwn(FlxG.sound.music.fadeTween);

				FlxG.sound.music.destroy();
				FlxG.sound.music = null;
				// trace('destroying');
			}

			// another request may have arrived during the destroy above, so we need to check again!
			if (gen != _loadGen) return null;

			// so I technically could just call AssetManager.clearUnused();
			// BUT! I wanna make sure I don't bump into any problems with it
			// so! I think manually removing the sound is better.
			clear();

			FlxG.sound.music = new MoonSound();

			start = chart?.content?.meta?.preview[0] ?? 0;

			// TODO: update this for the new custom difficulties system.
			final soundKey = Paths.exists(
				'songs/${chart.song}/${chart.mix}/Inst.ogg'
			) ? 'songs/${chart.song}/${chart.mix}/Inst.ogg' : 'music/menus/freeplayRandom.ogg';

			FlxG.sound.playMusic(Paths.getSound(soundKey));
			_prevSoundKey = soundKey;

			FlxG.sound.music.time = start;

			// trace(start + ' ' + end);

			end = chart?.content?.meta?.preview[1] ?? FlxG.sound.music.length;
			FlxG.sound.music.volume = 0;
			FlxG.sound.music.play();
			FlxG.sound.music.fadeIn(1, 0, Freeplay.instance.songVolume);

			// TODO: get the uhh metadata for the random song.
			if (Freeplay.instance.conductor != null) Freeplay.instance.conductor.changeBpmAt(
				0,
				chart?.content?.meta?.bpm ?? 145,
				chart?.content?.meta?.timeSignature[0] ?? 4,
				chart?.content?.meta?.timeSignature[0] ?? 4
			);

			resetting = false;
			active = true;

			// trace('playing song');
			return null;
		}, true);
	}

	static function update(elapsed:Float)
	{
		if (!active) return;
		if (FlxG.sound.music != null)
		{
			// trace(FlxG.sound.music.time);
			if (FlxG.sound.music.playing && FlxG.sound.music.time >= end && !resetting)
			{
				// trace('ending');
				resetting = true;

				// capture the music ref so the closure always targets the right object,
				// even if it swaps FlxG.sound.music mid a fade.
				final loopTarget = FlxG.sound.music;
				loopTarget.fadeOut(1, 0, _ ->
				{
					// Bail if this sound was replaced while fading out.
					if (FlxG.sound.music != loopTarget) return;

					resetting = false;
					loopTarget.time = start;
					loopTarget.fadeIn(1, 0, Freeplay.instance.songVolume);
				});
			}
		}
	}

	static function destroy()
	{
		if (FlxG.sound.music != null)
		{
			TweenUtils.cancelTwn(FlxG.sound.music.fadeTween);
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
		}

		clear();

		active = resetting = false;
		_loadGen = 0;
	}

	static function clear()
	{
		if (_prevSoundKey != null)
		{
			AssetManager.unloadSound(_prevSoundKey);
			_prevSoundKey = null;
		}
	}
}
