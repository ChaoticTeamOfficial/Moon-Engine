package moon.menus.obj.freeplay;

import moon.backend.data.SongLibrary;

@:publicFields
/**
 * Handles loading and looping song previews in the freeplay menu.
 */
class SongPreview
{
	static var previewStart:Float;
	static var previewEnd:Float;
	static var isLooping:Bool = false;
	static var isActive:Bool = false;
	static var songVolume:Float = 0.75;
	private static var loadGeneration:Int = 0;
	private static var currentSoundKey:String = null;

	/**
	 * Loads and plays a song preview based on the provided chart data.
	 */
	static function loadAndPlay(chart:Chart)
	{
		cancelCurrentFade();
		isLooping = false;
		songVolume = MoonSettings.callSetting('Music Volume') / 100;

		final gen = ++loadGeneration;

		new lime.app.Future(() ->
		{
			if (gen != loadGeneration) return null;

			destroyCurrentMusic();

			// another request may have arrived during the destroy above, so we need to check again!
			if (gen != loadGeneration) return null;

			unloadPreviousSound();
			FlxG.sound.music = new MoonSound();
			previewStart = chart?.content?.meta?.preview[0] ?? 0;
			final soundKey = resolveSoundKey(chart?.song ?? '', chart?.mix ?? '', SongLibrary.getInstSuffix(chart?.difficulty ?? ''));

			FlxG.sound.playMusic(Paths.getSound(soundKey));
			currentSoundKey = soundKey;

			FlxG.sound.music.time = previewStart;
			previewEnd = chart?.content?.meta?.preview[1] ?? FlxG.sound.music.length;

			FlxG.sound.music.volume = 0;
			FlxG.sound.music.play();
			FlxG.sound.music.fadeIn(1, 0, songVolume);

			updateConductor(chart);

			isLooping = false;
			isActive = true;

			return null;
		}, true);
	}

	static function update(elapsed:Float)
	{
		if (!isActive || FlxG.sound.music == null) return;
		if (!FlxG.sound.music.playing || isLooping) return;

		if (FlxG.sound.music.time >= previewEnd)
		{
			isLooping = true;

			// Capture reference to ensure we target the correct sound object
			final loopTarget = FlxG.sound.music;
			loopTarget.fadeOut(1, 0, _ ->
			{
				// Bail if this sound was replaced during the fade-out
				if (FlxG.sound.music != loopTarget) return;

				isLooping = false;
				loopTarget.time = previewStart;
				loopTarget.fadeIn(1, 0, songVolume);
			});
		}
	}

	static function destroy()
	{
		if (FlxG.sound.music != null)
		{
			cancelCurrentFade();
			FlxG.sound.music.destroy();
			FlxG.sound.music = null;
		}

		unloadPreviousSound();
		isActive = false;
		isLooping = false;
		loadGeneration = 0;
	}

	/**
	 * Resolves the correct sound path based on difficulty suffixes.
	 */
	static function resolveSoundKey(song:String, mix:String, instSuffix:String):String
	{
		if (song.length == 0 || mix.length == 0) return 'music/menus/freeplayRandom.ogg';

		if (instSuffix != null && instSuffix.length > 0)
		{
			final diffPath = 'songs/$song/$mix/Inst$instSuffix.ogg';
			if (Paths.exists(diffPath)) return diffPath;
		}

		final defaultPath = 'songs/$song/$mix/Inst.ogg';
		if (Paths.exists(defaultPath)) return defaultPath;

		return 'music/menus/freeplayRandom.ogg';
	}

	static function updateConductor(chart:Chart):Void
	{
		if (Freeplay.instance.conductor == null) return;

		final bpm:Float = chart?.content?.meta?.bpm ?? 145;
		final ts = chart?.content?.meta?.timeSignature;

		final tsNum:Int = (ts != null && ts.length > 0) ? ts[0] : 4;
		final tsDen:Int = (ts != null && ts.length > 1) ? ts[1] : 4;

		Freeplay.instance.conductor.changeBpmAt(0, bpm, tsNum, tsDen);
	}

	static function destroyCurrentMusic():Void
	{
		if (FlxG.sound.music == null) return;

		if (FlxG.sound.music.playing) FlxG.sound.music.stop();

		cancelCurrentFade();
		FlxG.sound.music.destroy();
		FlxG.sound.music = null;
	}

	static function unloadPreviousSound():Void
	{
		if (currentSoundKey != null)
		{
			AssetManager.unloadSound(currentSoundKey);
			currentSoundKey = null;
		}
	}

	static function cancelCurrentFade():Void
	{
		if (FlxG.sound.music != null && FlxG.sound.music.fadeTween != null) TweenUtils.cancelTwn(FlxG.sound.music.fadeTween);
	}
}
