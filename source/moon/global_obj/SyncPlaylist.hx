package moon.global_obj;

import flixel.sound.FlxSound;
import moon.backend.Paths;
import haxe.ds.StringMap;

using StringTools;

/**
 * Advanced music player for layered/variation tracks (Think on the char select screen, for example!)
 */
class SyncPlaylist
{
	public var sounds:StringMap<MoonSound> = new StringMap<MoonSound>();
	public var focusSong(default, set):String = null;
	public var volume(default, set):Float = 1.0;
	public var time(get, set):Float;

	public var fadeDuration:Float = 0.4;

	public function new() {}

	/**
	 * Directories won't include assets, something like this: "music/coolPath/variations"
	 * only reads from the music directory currently.
	 */
	public function loadFromDirectory(dir:String):SyncPlaylist
	{
		sounds = new StringMap<MoonSound>();

		for (file in Paths.readDir(dir, [".ogg"], true))
		{
			if (file.length == 0) continue;

			final sound = Paths.sound('${dir.startsWith("music/") ? dir.substr(6) : dir}/$file.ogg', "music");
			if (sound == null) continue;

			final snd = new MoonSound().loadEmbedded(sound, true);
			snd.strID = file;
			FlxG.sound.list.add(snd);

			trace('Loaded $file into the Playlist.', "DEBUG");
			sounds.set(file, snd);
		}

		if (sounds.keys().hasNext())
		{
			for (snd in sounds)
			{
				snd.time = snd.volume = 0;
				snd.play(true);
			}

			final keyArray = [for (k in sounds.keys()) k];
			if (keyArray.length > 0)
				focusSong = keyArray[0];
		}

		return this;
	}

	function set_focusSong(newSong:String):String
	{
		if (newSong == focusSong || !sounds.exists(newSong))
			return focusSong;

		final oldSound = focusSong != null ? sounds.get(focusSong) : null;
		final newSound = sounds.get(newSong);

		if (newSound != null)
		{
			newSound.volume = 0;
			newSound.fadeIn(fadeDuration, 0, volume);
			newSound.time = oldSound?.time ?? 0;
		}

		if (oldSound != null)
			oldSound.fadeOut(fadeDuration, 0, _ -> oldSound.volume = 0); // Ensure it ends at 0

		focusSong = newSong;
		return newSong;
	}

	function set_volume(v:Float):Float
	{
		volume = v < 0 ? 0 : (v > 1 ? 1 : v);

		if (focusSong != null && sounds.exists(focusSong))
			sounds.get(focusSong).volume = volume;

		return volume;
	}

	function get_time():Float
		return (focusSong != null && sounds.exists(focusSong)) ? sounds.get(focusSong).time : 0;

	function set_time(t:Float):Float
	{
		for (s in sounds)
			s.time = (s.length > 0) ? t % s.length : t;
		
		return t;
	}

	public function play()
	{
		for (snd in sounds)
			snd.resume();
	}

	public function pause()
	{
		for (snd in sounds)
			snd.pause();
	}

	public function stop()
	{
		for (snd in sounds)
		{
			snd.stop();
			snd.volume = 0;
		}
	}

	public function getSongList():Array<String>
	{
		return [for (k in sounds.keys()) k];
	}
}