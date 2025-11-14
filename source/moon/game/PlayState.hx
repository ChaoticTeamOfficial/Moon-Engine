package moon.game;

import moon.dependency.scripting.MoonScript;
import flixel.FlxObject;
import openfl.filters.ShaderFilter;
import moon.game.obj.Character;
import flixel.FlxSprite;
import flixel.FlxG;
import flixel.FlxState;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;

import moon.menus.*;
import moon.game.obj.Stage;
import moon.game.obj.PlayField;
import moon.toolkit.ChartConvert;
import moon.dependency.scripting.MoonEvent;
import moon.game.submenus.PauseScreen;
import moon.toolkit.level_editor.LevelEditor;

class PlayState extends FlxState
{	
	// Just a variable for the current instance so you can get all the vars.
	public static var instance:PlayState;

	//-- Gameplay main variables --//

	// The main gameplay interface
	public var playField:PlayField;

	// Just the conductor :P poor little guy,,
	public var conductor:Conductor;
	
	// Background (stage)
	public var stage:Stage;
	
	// Cameras
	public var camHUD:MoonCamera = new MoonCamera();
	public var camALT:MoonCamera = new MoonCamera();
	public var camGAME:MoonCamera = new MoonCamera();
	public var camFollower:FlxObject = new FlxObject();
	
	// -- Some other values --

	// Events (a array containing every MoonEvent, not the raw events from chart.)
	public static var events:Array<MoonEvent> = [];

	public var songScript:MoonScript = new MoonScript();

	// If the score is valid or not. Sets to false if on practice mode, botplay, or different pitch.
	public static var VALID_SCORE:Bool = true;

	public var song:String;
	public var difficulty:String;
	public var mix:String;

	public function new(?song:String = 'roses', ?difficulty:String = 'nightmare', ?mix:String = 'bf')
	{
		super();
		this.song = song;
		this.difficulty = difficulty;
		this.mix = mix;
		Global.allowInputs = true;
	}
	
	override public function create()
	{
		super.create();
		//Paths.clearStoredMemory();
		instance = this;

		Global.registerScript("songScript", songScript);
		songScript.load('songs/$song/$mix/script.hx');
		
		this.persistentUpdate = false;
		//this.persistentDraw = false;
		
		//< -- CAMERAS SETUP -- >//
		camGAME.bgColor = 0xFF000000;
		camHUD.bgColor = 0x00000000;
		camALT.bgColor = 0x00000000;

		FlxG.cameras.add(camGAME, true);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camALT, false);

		camFollower.setPosition(0, 0);
		camGAME.follow(camFollower, LOCKON, 1);
		camGAME.focusOn(camFollower.getPosition());
		
		//< -- PLAYFIELD SETUP -- >//
		playField = new PlayField(song, difficulty, mix);
		playField.camera = camHUD;
		playField.conductor.onBeat.add(beatHit);
		add(playField);
		this.conductor = playField.conductor;
		
		//< -- BACKGROUND SETUP -- >//
		stage = new Stage(playField.chart.content.meta.stage, conductor);
		add(stage);
		
		final chartMeta = playField.chart.content.meta;
		for (opp in chartMeta.opponents) stage.addCharTo(opp, stage.opponents, playField.inputHandlers.get('opponent'));
		for (plyr in chartMeta.players) stage.addCharTo(plyr, stage.players, playField.inputHandlers.get('p1'));
		for (spct in chartMeta.spectators) stage.addCharTo(spct, stage.spectators);

		setEvents();
		
		// call on post create for scripts
		Global.scriptSet('game', instance);
		Global.scriptCall('onPostCreate');

		playField.onSongRestart = () -> {
			events = [];
			setEvents();
			Global.scriptCall('onSongRestart');
		};
		
		playField.onGhostTap = (keyDir) -> Global.scriptCall('onGhostTap', [keyDir]);
		playField.onNoteHit = (playerID, note, timing, isSustain) -> 
		{
			final combo = playField.inputHandlers.get('p1').stats.combo;

			if((playerID == 'p1') && (combo == 50 || combo == 200))
				for(spectator in stage.spectators.members)
					cast(spectator, Character).playAnim((combo == 50) ? 'combo50' : 'combo200',true);

			Global.scriptCall('onNoteHit', [playerID, note, timing, isSustain]);
		};

		playField.onNoteMiss = (playerID, note) -> 
		{
			if(playerID == 'p1')
				for(spectator in stage.spectators.members)
					cast(spectator, Character).playAnim('comboBreak', true);
			
			Global.scriptCall('onNoteMiss', [playerID, note]);
		};
		playField.onSongCountdown = (number) -> Global.scriptCall('onSongCountdown', [number]);

		playField.onSongStart = () -> Global.scriptCall('onSongStart');

		playField.inCutscene = (callScriptField('onCutsceneStart'));
		if(playField.inCutscene)Global.scriptCall('onCutsceneStart');
		playField.playback.onFinish.add(()->endSong());

		//trace(SongData.retrieveData(song, difficulty, mix));
	}
	
	/**
	 * Calls a field in the script if it exists.
	 * @param field The field's name.
	 * @return true or false depending if the field exists or not.
	 */
	public function callScriptField(field:String, ?args:Null<Array<Dynamic>>):Bool
	{
		if (songScript != null && songScript.exists(field)) 
		{
			songScript.call(field, args);
			return true;
		}

		return false;
	}

	public function setEvents()
	{
		//< -- EVENTS SETUP -- >//
		for(event in playField.chart.events)
		{
			var ev = new MoonEvent(event.tag, event.values);
			ev.PRESET_VARIABLES = [
				'game' => this,
				'stage' => stage,
				'playField' => playField
			];
			ev.time = event.time;
			events.push(ev);
		}
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// EVENTS CHECK
		for (event in events)
		{
			if (event.time <= conductor.time)
			{
				Global.scriptCall('onEvent', [event.tag]);
				(event.valid) ? event.exec() : onHardcodedEvent(event);
				events.remove(event);
			}
		}
		
		//camGAME.zoom = FlxMath.lerp(camGAME.zoom, gameZoom, elapsed * 6);
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, elapsed * 6);
		
		if(FlxG.keys.justPressed.NINE) FlxG.switchState(()->new ChartConvert());
		if(FlxG.keys.justPressed.SEVEN) FlxG.switchState(() -> new LevelEditor());

		if(MoonInput.justPressed(PAUSE))
		{
			openSubState(new PauseScreen(camALT));
			playField.playback.state = PAUSE;
		}

		//TODO: REMOVE, THIS IS DEBUGGIN
		if(FlxG.keys.justPressed.EIGHT)
			endSong();

		Global.scriptCall('onUpdate', [elapsed]);
	}

	var camMov:FlxTween;
	var	camZoom:FlxTween;
	public function onHardcodedEvent(event:MoonEvent)
	{
		switch(event.tag)
		{
			case 'SetCameraFocus': setCameraFocus(
				event.values.character, 
				[event.values?.x ?? 0, event.values?.y ?? 0],
				conductor.stepCrochet / 1000 * event.values.duration,
				{ease: Reflect.field(FlxEase, event.values.ease)},
				event.values.ease == 'INSTANT'
			);
			
			case 'SetCameraZoom':/*setCameraZoom(
				event.values?.zoom ?? 0, 
				(event.values.ease != 'INSTANT' || event.values.duration != 0) ? conductor.stepCrochet / 1000 * event.values.duration: 0.001, 
				{ease: Reflect.field(FlxEase, event.values.ease)}
			);*/
			// TODO: fix this lol
			
			case 'ChangeBPM': conductor.changeBpmAt(event.time, event.values.bpm, event.values.timeSignature[0], event.values.timeSignature[1]);
		}
	}

	public function setCameraFocus(char:String, ?offsets:Array<Int>, ?duration:Float = 2, 
		?options:Null<TweenOptions>, ?isInstant:Bool = false)
	{
		MoonUtils.cancelActiveTwn(camMov);
		final charPos = getCamPos(char);

		if(!isInstant)
			camMov = FlxTween.tween(camFollower, {x: (charPos[0] ?? 0) + (offsets[0] ?? 0), y: (charPos[1] ?? 0) + (offsets[1] ?? 0)}, 
			duration, options);
		else
			camFollower.setPosition(charPos[0] + (offsets[0] ?? 0), charPos[1] + (offsets[1] ?? 0));
	}

	public function setCameraZoom(zoom:Float, duration:Float, ?options:Null<TweenOptions>)
	{
		MoonUtils.cancelActiveTwn(camZoom);
		camZoom = FlxTween.tween(camGAME, {zoom: zoom}, 
		duration, options);
	}

	var awa:Character;
	function getCamPos(charName:String):Array<Float>
	{
		final chars = stage.chars;
		for (c in chars)
		{
			if (c.character + ('-${c.ID}') == charName)
				return [c.getMidpoint().x + c.data.camOffsets[0], c.getMidpoint().y + c.data.camOffsets[1]];
			else
			{
				//these are for mainly converted charts, since its the possibly best way to get them working haha :'3
				switch(charName)
				{
					case 'opponent': awa = cast stage.opponents.members[0];
					case 'spectator': awa = cast stage.spectators.members[0];
					case 'player': awa = cast stage.players.members[0];
				}
				return [awa.getMidpoint().x + awa.data.camOffsets[0], awa.getMidpoint().y + awa.data.camOffsets[1]];
			}
		}
		return [0, 0];
	}

	public function beatHit(curBeat:Float)
	{
		Global.scriptCall('onBeat', [curBeat]);
		if (((curBeat % playField.conductor.numerator) == 0) && !playField.inCountdown)
		{
			//camGAME.zoom += 0.010;
			camHUD.zoom += 0.020;
		}
	}

	public function endSong()
	{
		Global.scriptCall('onSongEnd');
		final stat = playField.inputHandlers.get('p1').stats;
		if(VALID_SCORE)
			SongData.saveData(song, difficulty, mix, stat.score, stat.misses, stat.accuracy);

		Global.clearScriptList();
		FlxG.switchState(() -> new ResultsState(stat));
	}

	override function closeSubState()
	{
		super.closeSubState();
	}
}
