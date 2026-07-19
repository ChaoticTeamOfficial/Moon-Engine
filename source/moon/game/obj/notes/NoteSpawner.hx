package moon.game.obj.notes;

import moon.backend.gameplay.modifiers.Modifiers.ModifierIds;
import moon.backend.gameplay.modifiers.ModifierManager;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import moon.backend.data.Chart.NoteStruct;
import flixel.group.FlxGroup;
import moon.game.notetypes.*;

class NoteSpawner extends FlxGroup
{
	public var notes(get, never):Array<Note>;

	final _notes:Array<Note> = [];
	final _strumlineMap:Map<String, Strumline> = new Map();
	var conductor:Conductor;
	var nextNoteIndex:Int = 0;

	public var scrollSpeed(default, set):Float = 1.0;
	public var spawnThreshold:Float = 700;

	var _noteOffset:Float = 0;

	public var noteOffset(get, set):Float;

	var _downscroll:Bool = false;
	final _shuffleLastDir:Map<String, Int> = new Map();
	final _shuffleLastTime:Map<String, Float> = new Map();
	final _shuffleHistory:Map<String, Array<Int>> = new Map();

	/**
	 * How many preivous directions to keep discouraging jacks on shuffling.
	 */
	static inline var SHUFFLE_HISTORY_SIZE:Int = 3;

	/**
	 * How much to shrink the weight of a direction that was just used.
	 */
	static inline var SHUFFLE_REPEAT_PENALTY_FAST:Float = 0.05;

	static inline var SHUFFLE_HISTORY_PENALTY:Float = 0.6;

	public function new(noteStructs:Array<NoteStruct>, strumlines:Array<Strumline>, conductor:Conductor)
	{
		super();
		this.conductor = conductor;

		// build strumline lookup map
		for (strum in strumlines) _strumlineMap[strum.playerID] = strum;

		noteStructs = noteStructs.copy();
		noteStructs.sort((a, b) -> Std.int(a.time - b.time));

		// create and sort notes
		for (struct in noteStructs)
		{
			final note = createNoteFromStruct(struct);
			if (note != null) _notes.push(note);
		}
		_notes.sort((a, b) -> Std.int(a.time - b.time));
		updateCachedSettings();
	}

	override function update(dt:Float):Void
	{
		updateCachedSettings();
		updateSpawnThreshold();

		super.update(dt);

		final spawnTime = conductor.time + spawnThreshold;
		var i = nextNoteIndex;
		while (i < _notes.length && _notes[i].time <= spawnTime)
			recycleNote(_notes[i++]);

		nextNoteIndex = i;
	}

	inline function updateCachedSettings():Void
	{
		noteOffset = MoonSettings.callSetting('Note Offset');
		_downscroll = MoonSettings.callSetting('Downscroll');
	}

	inline function updateSpawnThreshold():Void
	{
		final newThreshold = (scrollSpeed <= 0.9) ? 3000 : (scrollSpeed <= 0.4) ? 5000 : 700;
		if (spawnThreshold != newThreshold) spawnThreshold = newThreshold;
	}

	function recycleNote(note:Note):Void
	{
		final strum = _strumlineMap[note.lane];
		if (strum == null) return;

		final group = strum.members[note.direction];
		if (group?.notesGroup == null) return;

		group.notesGroup.recycle(Note, () ->
		{
			note.receptor = strum.members[note.direction];
			note.visible = false;
			note.speed = scrollSpeed;
			note.state = NONE;
			if (note.duration > 0) recycleSustain(note, group.sustainsGroup);
			return note;
		});
	}

	function recycleSustain(note:Note, sustainGroup:FlxTypedSpriteGroup<NoteSustain>):Void
	{
		sustainGroup.recycle(NoteSustain, () ->
		{
			var sustain = note.child;
			if (sustain == null)
			{
				sustain = new NoteSustain(note);
				note.child = sustain;
			}
			sustain.downscroll = _downscroll;
			return sustain;
		});
	}

	function createNoteFromStruct(struct:NoteStruct):Note
	{
		final strum = _strumlineMap[struct.lane];
		if (strum == null || strum.members[struct.data] == null) return null;

		final keyCount = strum.members.length;
		var dir = struct.data;

		if (ModifierManager.isActive(ModifierIds.SHUFFLE)) dir = getShuffleDir(struct.lane, struct.time, keyCount);
		else if (ModifierManager.isActive(ModifierIds.MIRROR)) dir = getMirrorDir(struct.data, keyCount);

		final note = new Note(dir, struct.time + _noteOffset, struct.type, strum.members[struct.data].skin, struct.duration, conductor);
		note.values = struct.values;
		note.speed = scrollSpeed;
		note.lane = struct.lane;
		note.quantColor = getQuantColor(struct.time, conductor);
		NoteTypeRegistry.executeSpawn(note);
		return note;
	}

	inline function getMirrorDir(dir:Int, keyCount:Int):Int return keyCount - 1 - dir;

	function getShuffleDir(lane:String, time:Float, keyCount:Int):Int
	{
		final lastDir = _shuffleLastDir.exists(lane) ? _shuffleLastDir.get(lane) : -1;
		final lastTime = _shuffleLastTime.exists(lane) ? _shuffleLastTime.get(lane) : -999999.0;
		final history = _shuffleHistory.exists(lane) ? _shuffleHistory.get(lane) : [];

		final gap = time - lastTime;

		// Anything closer together than a 16th note is treated as "fast"...
		// soo... alr...
		final fastThreshold = conductor.stepCrochet * 1.5;
		final weights:Array<Float> = [for (i in 0...keyCount) 1.0];

		if (lastDir >= 0 && lastDir < keyCount && gap < fastThreshold) weights[lastDir] *= SHUFFLE_REPEAT_PENALTY_FAST;

		for (d in history) if (d >= 0 && d < keyCount) weights[d] *= SHUFFLE_HISTORY_PENALTY;

		final dir = weightRandomIdx(weights);

		_shuffleLastDir.set(lane, dir);
		_shuffleLastTime.set(lane, time);

		final newHistory = history.copy();
		newHistory.push(dir);
		if (newHistory.length > SHUFFLE_HISTORY_SIZE) newHistory.shift();
		_shuffleHistory.set(lane, newHistory);

		return dir;
	}

	function weightRandomIdx(weights:Array<Float>):Int
	{
		var total = 0.0;
		for (w in weights) total += w;

		if (total <= 0.0001) return FlxG.random.int(0, weights.length - 1);

		final r = FlxG.random.float(0, total);
		var acc = 0.0;
		for (i in 0...weights.length)
		{
			acc += weights[i];
			if (r <= acc) return i;
		}
		return weights.length - 1;
	}

	/**
	 * Returns 0-9 based on how the note is snapped inside the current beat/step
	 */
	public static function getQuantColor(time:Float, conductor:Conductor):Int return Std.int(
		(Math.round((time % conductor.crochet) / (conductor.crochet / 32)) * 10) / 32
	);

	public function updateNoteScroll()
	{
		for (note in _notes) note.updateNotePos();
	}

	inline function get_notes():Array<Note> return _notes;

	function get_noteOffset():Float return _noteOffset;

	function set_scrollSpeed(sp:Float):Float
	{
		scrollSpeed = sp / 2.4; // adoro sao paulo...
		for (note in _notes) note.speed = scrollSpeed;
		return scrollSpeed;
	}

	function set_noteOffset(value:Float):Float
	{
		final diff = value - _noteOffset;
		_noteOffset = value;

		for (note in _notes) note.time += diff;

		return value;
	}
}
