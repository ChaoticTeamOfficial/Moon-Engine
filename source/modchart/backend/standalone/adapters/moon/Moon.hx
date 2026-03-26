package modchart.backend.standalone.adapters.moon;

import flixel.FlxBasic;
import moon.game.obj.notes.*;
import moon.game.obj.*;
import moon.game.*;
import modchart.Manager;
import modchart.backend.standalone.IAdapter;

class Moon implements IAdapter
{
	//TODO: also adapt this class once we have P2 support and everythin

	// FM reads cameras directly off each sprite. since we use FlxSpriteGroups
	// for receptors/notes/sustains, FM falls back to FlxG.camera (the game cam) instead
	// of camHUD. we store each sprite's original camera list here, force camHUD onto them
	// before FM processes the frame, then restore everything in postDraw.
	// huge thanks to axel for helping me figure this out!
	var _savedCameras:Map<FlxBasic, Array<FlxCamera>> = [];

	public function new()
	{}

	public function onModchartingDispose() {
		FlxG.signals.postDraw.remove(postDraw);
	}

	public function onModchartingInitialization() {
		trace('Moon Engine\'s modchart adapter initialized!');

		FlxG.signals.postDraw.add(postDraw);
		FlxG.signals.preStateSwitch.addOnce(() -> FlxG.signals.postDraw.remove(postDraw));
	}

	public function isTapNote(sprite:FlxSprite)
		return sprite is Note;

	public function getSongPosition():Float
		return PlayState.instance.conductor.time;

	public function getCurrentBeat():Float
		return PlayState.instance.conductor.curBeat;

	public function getCurrentCrochet():Float
		return PlayState.instance.conductor.crochet;

	public function getBeatFromStep(step:Float)
		return step * .25;

	public function arrowHit(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).state == GOT_HIT;
		return false;
	}

	public function isHoldEnd(arrow:FlxSprite)
	{
		if (arrow is NoteSustain)
		{
			final s = cast(arrow, NoteSustain);
			@:privateAccess return s.parent != null && s.height <= s.tileHeight() * 1.5;
		}
		return false;
	}

	public function getLaneFromArrow(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).direction;
		else if (arrow is StrumNote)
			return cast(arrow, StrumNote).data;
		else if (arrow is RegularSplash)
			return cast(arrow, RegularSplash).data;
		else if (arrow is SustainSplash)
			return cast(arrow, SustainSplash).data;

		return 0;
	}

	public function getPlayerFromArrow(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).lane == 'p1' ? 1 : 0;
		if (arrow is StrumNote) @:privateAccess
			return cast(arrow, StrumNote).isCPU ? 0 : 1;

		return 0;
	}

	public function getKeyCount(?player:Int = 0):Int
		return 4;

	public function getPlayerCount():Int
		return 2;

	public function getTimeFromArrow(arrow:FlxSprite)
	{
		if (arrow is Note)
			return cast(arrow, Note).time;

		return 0;
	}

	public function getHoldSubdivisions(hold:FlxSprite):Int
		return 4;

	public function getHoldLength(item:FlxSprite):Float
	{
		if(item is Note)
		{
			final note:Note = cast item;
			return note.duration;
		}

		return 0;
	}

	public function getDownscroll():Bool
		return MoonSettings.callSetting('Downscroll');

	inline function getStrumFromInfo(lane:Int, player:Int) {
		var group = player == 0 ? PlayState.instance.playField.oppStrum : PlayState.instance.playField.playerStrum;
		var strum = null;
		group.forEach(str -> {
			if (str.data == lane)
				strum = str.strumNote;
		});
		return strum;
	}

	public function getDefaultReceptorX(lane:Int, player:Int):Float
		return getStrumFromInfo(lane, player).x;

	public function getDefaultReceptorY(lane:Int, player:Int):Float
		return !getDownscroll() ? 46 : FlxG.height - getStrumFromInfo(lane, player).height - 46;

	public function getArrowCamera():Array<FlxCamera>
		return [PlayState.instance.camHUD];

	public function getCurrentScrollSpeed():Float
		return PlayState.instance.playField.noteSpawner.scrollSpeed;

	public function getHoldParentTime(arrow:FlxSprite) {
		if (arrow is NoteSustain) {
			final sustain = cast(arrow, NoteSustain);
			return sustain.parent != null ? sustain.parent.time : 0;
		}
		if (arrow is Note)
			return cast(arrow, Note).time;

		return 0;
	}

	// 0 receptors
	// 1 tap arrows
	// 2 hold arrows
	// 3 splashes
	public function getArrowItems()
	{
		var pspr:Array<Array<Array<FlxSprite>>> = [[[], [], [], []], [[], [], [], []]];
		// todo: figure out why the heck are the notes duplicated???

		final camHUD = PlayState.instance.camHUD;
		final strums = [PlayState.instance.playField.oppStrum, PlayState.instance.playField.playerStrum];

		_savedCameras.clear();

		for (player in 0...strums.length)
		{
			final strum = strums[player];
			if (strum == null) continue;

			for (receptor in strum.members)
			{
				if (receptor == null) continue;
				pspr[player][0].push(receptor.strumNote);
				forceCamera(receptor.strumNote, camHUD);

				receptor.notesGroup.forEachAlive(note -> {
					pspr[player][1].push(note);
					forceCamera(note, camHUD);
				});
				receptor.sustainsGroup.forEachAlive(sustain -> {
					pspr[player][2].push(sustain);
					forceCamera(sustain, camHUD);
				});

				receptor.splashGroup.forEachAlive(splash -> {
					pspr[player][3].push(splash);
					forceCamera(splash, camHUD);
				});
			}
		}

		return pspr;
	}

	inline function forceCamera(sprite:FlxBasic, cam:FlxCamera)
	{
		@:privateAccess _savedCameras.set(sprite, sprite._cameras);
		@:privateAccess sprite._cameras = [cam];
	}

	function postDraw()
	{
		for (sprite => oldCams in _savedCameras)
			@:privateAccess sprite._cameras = oldCams;

		_savedCameras.clear();
	}
}