package moon.game;

import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

import moon.dependency.scripting.MoonScript;
import openfl.filters.ShaderFilter;
import moon.game.obj.Character;

import moon.menus.*;
import moon.game.submenus.*;
import moon.game.obj.*;

import moon.toolkit.ChartConvert;
import moon.dependency.scripting.MoonEvent;
import moon.game.submenus.PauseScreen;
import moon.toolkit.level_editor.LevelEditor;
import moon.game.events.EventRegistry;

using StringTools;
class PlayState extends FlxTransitionableState
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

	public static var songData:{song:String, difficulty:String, mix:String} = {
		song: 'earworm',
		difficulty: 'hard',
		mix: 'bf'
	};

	public function new()
	{
		super();
		Global.allowInputs = true;
		
		EventRegistry.init();
	}
	
	var rpcString:String = "";
	override public function create()
	{
		super.create();
		activeTweens(true);
		//Paths.clearStoredMemory();
		instance = this;
		events = [];

		Global.registerScript("songScript", songScript);
		songScript.load('songs/${songData.song}/${songData.mix}/script.hx');
		
		this.persistentUpdate = false;
		//this.persistentDraw = false;
		
		//< -- CAMERAS SETUP -- >//
		camGAME.bgColor = FlxColor.GRAY;
		camHUD.bgColor = 0x00000000;
		camALT.bgColor = 0x00000000;

		FlxG.cameras.add(camGAME, true);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camALT, false);
		
		//< -- PLAYFIELD SETUP -- >//
		playField = new PlayField(songData.song, songData.difficulty, songData.mix);
		playField.camera = camHUD;
		playField.conductor.onBeat.add(beatHit);
		playField.conductor.onStep.add(stepHit);
		add(playField);
		this.conductor = playField.conductor;
		
		//< -- BACKGROUND SETUP -- >//
		stage = new Stage(playField.chart.content.meta.stage, conductor);
		add(stage);
		
		final chartMeta = playField.chart.content.meta;
		for (opp in chartMeta.opponents) stage.addCharTo(opp, stage.opponents, playField.inputHandlers.get('opponent'));
		for (plyr in chartMeta.players) stage.addCharTo(plyr, stage.players, playField.inputHandlers.get('p1'));
		for (spct in chartMeta.spectators) stage.addCharTo(spct, stage.spectators);
		
		Countdown.init(conductor, playField);
		Countdown.performCountdown();

		// call on post create for scripts
		Global.scriptSet('game', instance);
		Global.scriptCall('onPostCreate');
		setEvents();

		playField.onSongRestart = () -> {
			events = [];
			setEvents();
			Countdown.performCountdown();
			DiscordRPC.updatePresence(PLAYMODE, rpcString, "Restarting.", true);
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
		
		rpcString = 'Playing ${playField.chart.content.meta.displayName} on ${songData.difficulty.toUpperCase()}';
		DiscordRPC.updatePresence(PLAYMODE, rpcString, "", true);

		//alright.
		camHUD.fade(FlxColor.BLACK, conductor.crochet / 1000 * 2, true);
		camGAME.follow(camFollower, LOCKON, 1);
		camGAME.focusOn(camFollower.getPosition());
	}
	
	public function activeTweens(isActive:Bool)
	{
		FlxTimer.globalManager.forEach((t)-> if (!t.finished)t.active = isActive);
        FlxTween.globalManager.forEach((t)-> if (!t.finished)t.active = isActive);
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

		events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

		camFollower.setPosition(stage?.cameraSettings?.startX ?? 0, stage?.cameraSettings?.startY ?? 0);
		camGAME.zoom = stage?.cameraSettings?.zoom ?? 1;
		isDead = false;
	}

	var isDead:Bool = false;
	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// EVENTS CHECK
		if(events.length > 0)
		{
			for (event in events)
			{
				if (event.time <= conductor.time)
				{
					Global.scriptCall('onEvent', [event.tag]);
					
					if (event.valid) event.exec();
					else EventRegistry.executeEvent(this, event);
					
					events.remove(event);
				}
			}
		}
		
		//camGAME.zoom = FlxMath.lerp(camGAME.zoom, gameZoom, elapsed * 6);
		camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, elapsed * 6);
		
		if(FlxG.keys.justPressed.NINE) FlxG.switchState(()->new ChartConvert());
		if(FlxG.keys.justPressed.SEVEN) FlxG.switchState(() -> new LevelEditor(songData.song, songData.difficulty, songData.mix));

		if(MoonInput.justPressed(PAUSE))
		{
			activeTweens(false);
			openSubState(new PauseScreen(camALT));
			if(playField.playback.state == PLAY)
				playField.playback.state = PAUSE;
		}

		// gonna leave it commented for now
		// it softlocks currently, and my skill issue won't help XD
		/*if(playField.healthBar.health <= 0 && !isDead)
		{
			playField.inCutscene = isDead = true;

			playField.playback.state = STOP;

			setCameraFocus('player', [], 0.7, {ease: FlxEase.circOut, startDelay: 0.01});
			setCameraZoom(camGAME.zoom * 2, 0.5, {startDelay: 0.25, ease: FlxEase.expoIn, onComplete: _->{
				//trace('yup.');
				openSubState(new Gameover());
			}});
		}*/

		//TODO: REMOVE, THIS IS DEBUGGIN
		if(FlxG.keys.justPressed.EIGHT)
			endSong();

		//if(FlxG.keys.justPressed.FOUR)
		//	Countdown.performCountdown();

		Global.scriptCall('onUpdate', [elapsed]);
	}

	var camMov:FlxTween;
	var	camZoom:FlxTween;

	public function setCameraFocus(char:String, ?offsets:Array<Int>, ?duration:Float = 2, ?options:Null<TweenOptions>, ?isInstant:Bool = false)
	{
		MoonUtils.cancelActiveTwn(camMov);
		final charPos = getCamPos(char);

		if(!isInstant)
			camMov = FlxTween.tween(camFollower, {x: (charPos[0] ?? 0) + (offsets[0] ?? 0), y: (charPos[1] ?? 0) + (offsets[1] ?? 0)}, 
			duration, options);
		else
			camFollower.setPosition(charPos[0] + (offsets[0] ?? 0), charPos[1] + (offsets[1] ?? 0));
	}

	public function setCameraZoom(zoom:Float, duration:Float, ?options:Null<TweenOptions>, isInstant:Bool = false)
	{
		MoonUtils.cancelActiveTwn(camZoom);

		//trace('Setting zoom to $zoom in $duration', "DEBUG");
		if(!isInstant)
			camZoom = FlxTween.tween(camGAME, {zoom: zoom}, duration, options);
		else camGAME.zoom = zoom;
	}

	public function getCamPos(charName:String):Array<Float>
	{
		final char = getChar(charName);
		if(char != null)
			return [char.getMidpoint().x + char.data.camOffsets[0], char.getMidpoint().y + char.data.camOffsets[1]];

		return [0, 0];
	}

	public function getChar(charName:String):Character
	{
		for (c in stage.chars)
		{
			if('${c.character}-${c.ID}' == charName)
				return c;
			else
			{
				switch(charName)
				{
					case 'opponent': return cast stage.opponents.members[0];
					case 'spectator': return cast stage.spectators.members[0];
					case 'player': return cast stage.players.members[0];
				}
			}
		}

		trace('Could not get character with name $charName', "WARNING");
		return null;
	}

	public var bopRate:Int = Constants.DEFAULT_BOP_RATE - 1;
	public var bopIntensity:Float = Constants.DEFAULT_BOP_INTENSITY - 1;
	public function beatHit(curBeat:Float)
	{
		if (((curBeat % bopRate) == 0) && !playField.inCountdown)
		{
			//camGAME.zoom += 0.010;
			camHUD.zoom += bopIntensity;
		}
		
		// updates less frequently..!
		if(curBeat % 4 == 0)
			DiscordRPC.updatePresence(PLAYMODE, rpcString, 'Accuracy: ${Std.int(playField.inputHandlers.get("p1").stats.accuracy)}%', false);
			
		Global.scriptCall('onBeat', [curBeat]);
	}

	public function stepHit(curStep:Float)
	{
		Global.scriptCall('onStep', [curStep]);
	}

	public function endSong()
	{
		Global.scriptCall('onSongEnd');
		final stat = playField.inputHandlers.get('p1').stats;
		var saved:Bool = false;
		if(VALID_SCORE)
			saved = SongData.saveData(songData.song, songData.difficulty, songData.mix, stat.score, stat.misses, stat.accuracy);

		camHUD.fade(FlxColor.BLACK, conductor.crochet / 1000 * 2, false, ()->exit(false, saved));
		setCameraFocus('spectator', [], conductor.crochet / 1000 * 2, {ease: FlxEase.circOut});
	}

	override function closeSubState()
	{
		super.closeSubState();
	}

	public function exit(toMenu:Bool = true, savedData:Bool = false)
	{
		// jus to make sure
		Paths.skipNextCleanup = false;
		Global.clearScriptList();
		instance = null;

		if(toMenu) openSubState(new StickerSubState(new MainMenu()));
		else FlxG.switchState(()-> new ResultsState(playField.inputHandlers.get('p1').stats, playField.chart.content.meta, playField.difficulty, savedData));
	}

	// this is ugly but whatever
	// Made public so event classes can access it
	public function resolveEase(easeName:String):EaseFunction
	{
		//btw this is just because of how vslice handle tween easings.

		if(easeName == null || easeName == "" || easeName.toLowerCase().contains('linear'))
			return FlxEase.linear; //safechecks are nice!

		var name:String = easeName;
		switch(name.toLowerCase())
		{
			case "instant": return null;
			default: 
				if(name.toLowerCase() != "linear" && !StringTools.endsWith(name, "In") && !StringTools.endsWith(name, "Out") && !StringTools.endsWith(name, "InOut"))
					name += "InOut";

			var func = Reflect.field(FlxEase, name);

			//just some last failsafes
			if(func == null)
			{
				name = StringTools.replace(name, "InOut", "Out");
				func = Reflect.field(FlxEase, name);
			}

			if(func == null)
				func = FlxEase.expoInOut;

			//trace('resolved ease: $name', "DEBUG");

			return func;
		}
	}
}
