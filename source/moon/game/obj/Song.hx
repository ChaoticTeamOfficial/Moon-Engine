package moon.game.obj;

import flixel.FlxG;
import moon.backend.data.SongLibrary;
import moon.dependency.MoonSound.MusicType;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxSignal;

enum SongState
{
	PLAY;
	PAUSE;
	STOP;
	KILL;
}

class Song extends FlxTypedGroup<MoonSound>
{
	/**
	 * The song's state, those being: `PLAY`, `PAUSE`, `STOP` & `KILL`.
	 */
	public var state(default, set):SongState = PLAY;

	/**
	 * The song's pitch.
	 */
	public var pitch(default, set):Float = 1;

	/**
	 * The song's current time.
	 */
	@:isVar
	public var time(get, set):Float = 0;

	/**
	 * Get the song's full time.
	 */
	@:isVar
	public var fullLength(get, never):Float = 0;

	public var inst:Array<MoonSound> = [];
	public var voices:Array<MoonSound> = [];
	public final onFinish = new FlxTypedSignal<Void->Void>();

	private var conductor:Conductor;
	private var finished:Bool = false;

	/**
	 * Creates a song instance, useful for gameplay Inst & Voices.
	 * @param song        The name of the song
	 * @param char        The character mix
	 * @param difficulty  The difficulty name
	 * @param conductor   
	 */
	public function new(song:String, char:String, difficulty:String = 'hard', conductor:Conductor)
	{
		super();
		this.conductor = conductor;

		// Determine suffixes from the difficulty config
		final instSfx = SongLibrary.getInstSuffix(difficulty);
		final voicesSfx = SongLibrary.getVoicesSuffix(difficulty);

		var audList = [Voices_Opponent, Voices_Player, Inst];

		for (i in 0...audList.length)
		{
			final item = audList[i];
			final sfx = (item == Inst) ? instSfx : voicesSfx;

			// Try with suffix first, then fall back to non-suffixed
			var path = '$song/$char/${audList[i]}$sfx';
			if (sfx != '' && !Paths.exists('songs/$path.ogg')) path = '$song/$char/${audList[i]}';

			if (Paths.exists('songs/$path.ogg'))
			{
				this.recycle(MoonSound, function():MoonSound
				{
					var aud = cast new MoonSound().loadEmbedded(Paths.sound('$path.ogg', 'songs'), false, true);
					aud.type = audList[i];
					aud.strID = song;
					aud.onComplete = finish;
					FlxG.sound.list.add(cast aud);

					(aud.type == Inst) ? inst.push(aud) : voices.push(aud);
					return aud;
				});
			}
		}

		if (conductor != null) conductor.onStep.add(steps);
		finished = false;
	}

	override public function update(dt:Float)
	{
		super.update(dt);
		if (conductor.time >= fullLength) finish();
	}

	/**
	 * Mutes/Unmutes certain audio types.
	 * @param type The music type (e.g. Inst)
	 * @param mute Whether it should be mute or not
	 */
	public function muteStatus(type:MusicType, mute:Bool)
	{
		for (aud in this.members) if (aud.type == type) aud.volume = mute ? 0 : MoonSettings.callSetting(
			type == Inst ? 'Instrumental Volume' : 'Voices Volume'
		) / 100;
	}

	public function updateVolume()
	{
		for (aud in this.members) aud.volume = MoonSettings.callSetting(aud.type == Inst ? 'Instrumental Volume' : 'Voices Volume') / 100;
	}

	function finish()
	{
		if (!finished)
		{
			onFinish.dispatch();
			finished = true;
		}
	}

	final threshold = 30;

	private function steps(step)
	{
		if (this.state == PLAY)
		{
			// resync if its off compared to conductor
			for (i in inst) if ((i.time >= conductor.time + threshold || i.time <= conductor.time - threshold)) resync();

			// resync if the vocals are off compared to inst
			if (voices.length > 0) for (v in voices) for (i in inst) if (Math.abs(v.time - i.time) > 5 && v.playing) v.time = i.time;
		}
	}

	/**
	 * Resyncs every member in this instance to their supposed time position based on conductor.
	 */
	public function resync():Void
	{
		for (i in inst)
		{
			if (i.playing) conductor.time = i.time;
			if (voices.length > 0) for (v in voices) if (v.playing) v.time = i.time;
		}
	}

	override public function kill()
	{
		super.kill();

		for (member in this.members)
		{
			FlxG.sound.list.remove(member, true);
			remove(member);
			member.destroy();
		}
		inst = voices = null;
	}

	////////////////////////////////////////////////////////////////////////////////////

	@:noCompletion
	public function set_state(state:SongState = PLAY):SongState
	{
		this.state = state;
		for (i in 0...members.length)
		{
			switch (state)
			{
				case PLAY:
					members[i].play();
				case PAUSE:
					members[i].pause();
				case STOP:
					members[i].stop();
				case KILL:
					FlxG.sound.list.remove(this.members[i]);
					members[i].kill();
			}
		}
		return state;
	}

	@:noCompletion
	public function set_pitch(value:Float):Float
	{
		pitch = value;

		for (i in 0...members.length) members[i].pitch = pitch;

		return value;
	}

	@:noCompletion
	public function get_time():Float
	{
		var lastTime:Float = 0;
		for (i in 0...members.length) lastTime = members[i].time;

		return lastTime;
	}

	@:noCompletion
	public function set_time(value:Float):Float
	{
		time = value;
		for (i in 0...members.length) members[i].time = value;

		return value;
	}

	@:noCompletion
	public function get_fullLength():Float
	{
		var lastLength:Float = 0;
		for (i in 0...members.length) lastLength = members[i].length;

		return lastLength;
	}
}
