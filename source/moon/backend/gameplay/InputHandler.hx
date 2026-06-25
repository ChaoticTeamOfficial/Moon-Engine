package moon.backend.gameplay;

import moon.backend.gameplay.Timings.Judgement;
import moon.game.obj.Character;
import moon.game.obj.notes.Note.NoteState;
import moon.game.obj.notes.*;
import lime.system.System;
import moon.backend.gameplay.Replay.ReplayInput;
import moon.game.notetypes.NoteTypeRegistry;
import flixel.util.FlxSignal;

/**
 * Class meant to handle note inputs and player stats in a gameplay scene.
**/
class InputHandler
{
	/**
	 * The player's stats, which holds accuracy, score, etc.
	 */
	public var stats:PlayerStats;

	/**
	 * The player ID, used for many things, but mainly note reading.
	 */
	public var playerID:String;

	/**
	 * Wheter is a CPU or not, used for checking inputs.
	 */
	public var CPUMode:Bool = false;

	/**
	 * The strumline, used for triggering animations and maybe more.
	 */
	public var strumline:Strumline;

	/**
	 * The conductor class, used for many things among with note timings.
	 */
	public var conductor:Conductor;

	@:dox(hide)
	public var heldSustains:Map<Int, Note> = new Map<Int, Note>();

	/**
	 * Array for the notes in this class, needed for reading their timings and such.
	 */
	public var thisNotes:Array<Note> = [];

	/**
	 * Signal dispached whenever a note gets hit (Good Hit.)
	 */
	public final onNoteHit = new FlxTypedSignal<(note:Note, timing:Judgement, isSustain:Bool) -> Void>();

	/**
	 * Signal dispached whenever a note is missed (Bad Hit.)
	 */
	public final onNoteMiss = new FlxTypedSignal<Note->Void>();

	/**
	 * Signal dispatched whenever a key is pressed (if ghost tapping is off, it'll call onNoteMiss right after.)
	 */
	public final onGhostTap = new FlxTypedSignal<Int->Void>();

	/**
	 * Signal dispatched whenever a key is released.
	 */
	public final onKeyRelease = new FlxTypedSignal<Int->Void>();

	/**
	 * Signal dispatched whenever a sustain gets completed (held till the end.)
	 */
	public final onSustainComplete = new FlxTypedSignal<Note->Void>();

	/**
	 * A character which will play sing animations automatically.
	 */
	public var attachedChar:Character;

	/**
	 * Array for all the the keys on the 'justPressed' state.
	 */
	public var justPressed:Array<Bool> = [];

	/**
	 * Array for all the the keys on the 'pressed' state.
	 */
	public var pressed:Array<Bool> = [];

	/**
	 * Array for all the the keys on the 'justReleased' state.
	 */
	public var released:Array<Bool> = [];

	// -- REPLAY SYSTEM STUFF

	/**
	 * Whether is the input on replay mode or not.
	 */
	public var isReplay:Bool = false;

	/**
	 * Whether is the input recording a replay or not.
	 */
	public var recording:Bool = false;

	/**
	 * An array of replay inputs.
	 */
	public var replayInputs:Array<ReplayInput> = [];

	/**
	 * An array of all recorded inputs for replays.
	 */
	public var recordedInputs:Array<ReplayInput> = [];

	/**
	 * The current replay index.
	 */
	public var currentReplayIndex:Int = 0;

	/**
	 * The state for all four keys.
	 */
	public var replayKeyStates:Array<Bool> = [false, false, false, false];

	/**
	 * Whether or not should ghost tapping be enabled.
	 */
	public var ghostTapping:Bool = MoonSettings.callSetting('Ghost Tapping');

	/**
	 * A reference to PlayState, needed to dispatch note type behaviours.
	 */
	public var game:moon.game.PlayState = null;

	/**
	 * Creates input handler instance, all this does is handling inputs for a player you choose.
	 * @param thisNotes The notes array that it will read.
	 * @param playerID  The ID for the player. currently supported are [`opponent, p1`]
	 * @param strumline The strumline, used for triggering animations on it.
	 * @param conductor The conductor instance, used for many things.
	 */
	public function new(thisNotes:Array<Note>, playerID:String, strumline:Strumline, conductor:Conductor)
	{
		this.thisNotes = thisNotes;
		this.playerID = playerID;
		this.strumline = strumline;
		this.conductor = conductor;
		this.stats = new PlayerStats(playerID);

		// it is always recording by default BUT maybe I'll make like...
		// something that disables by default idk.
		replayKeyStates = [false, false, false, false];
		recording = true;
	}

	/**
	 * Loads a Replay.
	 * @param replay The replay class to be loaded.
	 */
	public function loadReplay(replay:Replay)
	{
		isReplay = true;
		replayInputs = replay.inputs.copy();

		currentReplayIndex = 0;
		replayKeyStates = [false, false, false, false];

		recording = false;
		stats.reset();
		forcedJudgements = [];
	}

	private var forcedJudgements:Map<Int, String> = [];

	@:dox(hide)
	public function update():Void
	{
		if (isReplay) processReplayInputs();
		else if (!CPUMode) processInputs();
		else
			processCPUInputs();

		checkSustains();
		onLateMiss();
		// stats.health = FlxMath.bound(stats.health, 0, 101);
	}

	private function processReplayInputs():Void
	{
		// clears every input so you cant press on replays.
		for (i in 0...4)
		{
			justPressed[i] = false;
			released[i] = false;
		}

		// process every input that should have happened by now
		while (currentReplayIndex < replayInputs.length && replayInputs[currentReplayIndex].time <= conductor.time)
		{
			final input = replayInputs[currentReplayIndex];
			final dir = input.dir;

			if (input.press)
			{
				justPressed[dir] = true;
				replayKeyStates[dir] = true;

				if (input.judgement != null) forcedJudgements.set(dir, input.judgement);
			}
			else
			{
				released[dir] = true;
				replayKeyStates[dir] = false;
			}

			currentReplayIndex++;
		}

		// keeps pressed state for holds/sustains
		for (i in 0...4) pressed[i] = replayKeyStates[i];

		// then process regular inputs.
		processInputs();
	}

	private function processCPUInputs():Void
	{
		for (i in 0...4)
		{
			// get the possible notes thats in the... perfect timing
			final possibleNotes = thisNotes.filter(
				note -> return (note.direction == i && note.lane == playerID && note.time - conductor.time <= 0 && note.state == NONE)
			);

			// then call onhit
			if (possibleNotes.length > 0) onHit(possibleNotes[0], i, SICK, true);
		}
	}

	private function processInputs():Void
	{
		for (i in 0...justPressed.length)
		{
			if (justPressed[i])
			{
				final possibleNotes = thisNotes.filter(
					note -> return (note.direction == i && note.lane == playerID && isWithinTiming(note, i) && note.state == NONE)
				);

				possibleNotes.sort((a, b) -> Std.int(a.time - b.time));

				if (possibleNotes.length > 0)
				{
					final note = possibleNotes[0];
					// use forced judgement when replaying, recalculates when live
					final timing = (isReplay && forcedJudgements.exists(i)) ? forcedJudgements.get(i) : checkTiming(note);

					// clear the forced judgement slot now that it's been consumed
					// why that lowkey sounded funny lmao
					forcedJudgements.remove(i);

					if (timing != null)
					{
						// record AFTER we know the timing so we can store the judgement
						if (recording) recordedInputs.push({
							time: conductor.time,
							dir: i,
							press: true,
							judgement: timing
						});

						onHit(note, i, timing, false);
						stats.totalNotes++;
						stats.accuracyCount += Timings.get(timing).accuracyCount;
					}
				}
				else
				{
					if (recording) recordedInputs.push({
						time: conductor.time,
						dir: i,
						press: true,
						judgement: null
					});
					forcedJudgements.remove(i);

					onGhostTap.dispatch(i);
					strumline.members[i].strumNote.playAnim('${MoonUtils.intToDir(i)}-press', true);
					if (!ghostTapping)
					{
						if (attachedChar != null) attachedChar.playAnim('sing${MoonUtils.intToDir(i).toUpperCase()}-miss', true);
						onMiss(null);
					}
				}
			}
		}

		for (i in 0...released.length)
		{
			if (released[i])
			{
				if (recording) recordedInputs.push({
					time: conductor.time,
					dir: i,
					press: false,
					judgement: null
				});

				onKeyRelease.dispatch(i);
				strumline.members[i].strumNote.playAnim('${MoonUtils.intToDir(i)}-static', true);

				if (heldSustains.exists(i))
				{
					strumline.members[i].sustainSplash.despawn(true);
					final heldNote = heldSustains.get(i);
					heldSustains.remove(i);

					if (heldNote != null && heldNote.state == GOT_HIT && heldNote.child != null) heldNote.child.visible = heldNote.child.active = false;
				}
			}
		}
	}

	private function onHit(note:Note, ID:Int, timing:Judgement, isCPU:Bool, ?isSustain:Bool = false):Void
	{
		final convertedDir = MoonUtils.intToDir(note.direction);
		final isTyped = note.type != null && note.type != 'default';

		if (!isSustain)
		{
			note.state = GOT_HIT;
			note.visible = note.active = false;
			stats.judgementsCounter.set(timing, stats.judgementsCounter.get(timing) + 1);
			stats.noSustainCombo++;
			// trace(stats.judgementsCounter, "DEBUG");
			if (note.duration > 0)
			{
				heldSustains.set(ID, note);
				lastSustainStep.set(ID, conductor.curStep);
			}
		}

		stats.health += (!isSustain) ? Timings.get(timing).healthGain : 0.5;
		stats.score += (!isSustain) ? Timings.get(timing).score : 2;
		stats.combo++;
		strumline.members[note.direction].onNoteHit(note, timing, isSustain);
		stats.updtAccuracy();
		// trace(stats.judgementsCounter, "DEBUG");

		// even though this is here, notetypes can play a specific
		if (attachedChar != null && !isTyped) attachedChar.playAnim('sing${convertedDir.toUpperCase()}', true);

		// dispatch a note hit on the note registry!
		if (isTyped && game != null) NoteTypeRegistry.executeHit(game, note, timing, isSustain);

		if ((timing == 'good' || timing == 'bad' || timing == 'shit' || timing == 'miss') && stats.isGold) stats.isGold = false;

		(timing != 'miss') ? onNoteHit.dispatch(note, timing, isSustain) : (timing == 'miss') ? onMiss(note) : null;
	}

	private function onMiss(note:Note):Void
	{
		if (note != null)
		{
			note.state = TOO_LATE;
			note.visible = note.active = false;

			final isTyped = note.type != null && note.type != 'default';

			if (attachedChar != null && !isTyped) attachedChar.playAnim('sing${MoonUtils.intToDir(note.direction).toUpperCase()}-miss', true);

			if (isTyped && game != null) NoteTypeRegistry.executeMiss(game, note);
		}

		stats.isGold = false;
		stats.accuracyCount += Timings.get(MISS).accuracyCount;
		stats.score += Timings.get(MISS).score;
		stats.health += Timings.get(MISS).healthGain;
		stats.misses++;
		stats.combo = 0;
		stats.noSustainCombo = 0;
		stats.updtAccuracy();

		onNoteMiss.dispatch(note);
	}

	private var lastSustainStep:Map<Int, Float> = new Map<Int, Float>();

	private function checkSustains():Void
	{
		for (direction in heldSustains.keys())
		{
			final heldNote = heldSustains.get(direction);

			if (heldNote != null && heldNote.state == GOT_HIT && heldNote.child != null && heldNote.child.active)
			{
				if (lastSustainStep.exists(direction))
				{
					final last = lastSustainStep.get(direction);

					// fire once per every step we may have skipped due to lag
					if (conductor.curStep > last)
					{
						var step = last + 1;
						while (step <= conductor.curStep)
						{
							onHit(heldNote, direction, null, CPUMode, true);
							stats.score += 2;
							step++;
						}
						lastSustainStep.set(direction, conductor.curStep);
					}
				}

				if (conductor.time >= heldNote.time + heldNote.duration)
				{
					heldNote.child.visible = heldNote.child.active = false;

					strumline.members[direction].sustainSplash.despawn(CPUMode);

					onSustainComplete.dispatch(heldNote);

					heldSustains.remove(direction);
					lastSustainStep.remove(direction);
				}
			}
			else
			{
				heldSustains.remove(direction);
				if (heldNote != null) strumline.members[direction].sustainSplash.despawn(CPUMode);
			}
		}
	}

	private function onLateMiss():Void for (note in thisNotes) if (
		note.state != GOT_HIT
		&& note.state != TOO_LATE
		&& note.lane == playerID
		&& conductor.time > note.time + Timings.get(MISS).maxMs
	) onMiss(note);

	/**
	 * Checks if the note is within timing,
	 * @param note The note it'll check the timing 
	 * returns checkTiming(note) != null
	 */
	private function isWithinTiming(note:Note, ?dir:Int = -1):Bool
	{
		// during replay, if a forced judgement is waiting for this direction,
		// always allow the note through regardless of current time.
		// needed due to toffee's (old) pc being trash and sometimes lag spiking.

		// OKAY I JUST FOUND OUT THAT IT STILL APPLIES THE WRONG JUDGEMENT IF THE GAME LAGSSS
		// ugh I'll figure this out l8r...
		if (isReplay && dir >= 0 && forcedJudgements.exists(dir)) return true;

		return checkTiming(note) != null;
	}

	/**
	 * Checks the timing for a note, then it'll return its appropriate judgement.
	 * @param note 
	 * @return String
	 */
	private function checkTiming(note:Note):String
	{
		final timeDifference = Math.abs(note.time - conductor.time);
		for (jt in Timings.values) if (timeDifference <= Timings.get(jt).maxMs) return jt;

		return null;
	}
}
