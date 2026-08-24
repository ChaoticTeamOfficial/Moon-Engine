package moon.game;

import sys.FileSystem;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import modchart.Manager;
import moon.dependency.scripting.MoonScript;
import moon.game.obj.Character;
import moon.menus.*;
import moon.game.submenus.*;
import moon.game.obj.*;
import moon.toolkit.level_editor.*;
import moon.backend.gameplay.*;
import moon.dependency.scripting.MoonEvent;
import moon.game.submenus.PauseScreen;
import moon.game.events.EventRegistry;
import moon.game.obj.Character.CharacterType;
import moon.game.obj.SubtitleDisplay;
import moon.dependency.MoonShaderHandler;
import moon.game.events.ShaderFilterRegistry;
import moon.backend.gameplay.mechanics.*;

using StringTools;

class PlayState extends FlxTransitionableState
{
	/**
	 * The current active playstate instance.
	 */
	public static var instance:PlayState;

	//-- Gameplay main variables --//

	/**
	 * The current playfield, containing the game's interface.
	 */
	public var playField:PlayField;

	/**
	 * The playfield's conductor.
	 */
	public var conductor:Conductor;

	/**
	 * The game's background.
	 */
	public var stage:Stage;

	/**
	 * The funkin' modchart instance.
	 */
	public var fmInstance:Manager;

	/**
	 * The subtitles that show up on a show subtitle event :D
	 */
	public var captions:SubtitleDisplay;

	// Cameras

	/**
	 * The camera in which is used for most HUD elements.
	 */
	public var camHUD:MoonCamera = new MoonCamera();

	/**
	 * The camera in which is used for other objects. For example, the Pause menu.
	 */
	public var camALT:MoonCamera = new MoonCamera();

	/**
	 * The camera used for most in-game objects.
	 */
	public var camGAME:MoonCamera = new MoonCamera();

	public var camFollower:FlxObject = new FlxObject();

	/**
	 * Per-camera shader handlers used by the Set Filter event!
	 */
	public var cameraShaderHandlers:Map<String, MoonShaderHandler> = [];

	// -- Some other values --
	// Events (a array containing every MoonEvent, not the raw events from chart.)
	public static var events:Array<MoonEvent> = [];

	public var songScript:MoonScript = new MoonScript();

	/** 
	 * If the score is valid or not. Sets to false if on practice mode, botplay...
	 */
	public static var VALID_SCORE:Bool = true;

	public var canPause:Bool = true;
	public var loadedReplay:Replay = null;

	public static var replaysToSave:Array<Replay> = [];
	public static var songData:SongBase = {
		song: 'dadbattle d-side',
		difficulty: 'hard',
		mix: 'bf'
	};
	public static var playlist:Array<SongBase> = [];
	public static var playlistIndex:Int = 0;

	public static function queuePlaylist(songs:Array<SongBase>)
	{
		playlist = songs != null ? songs.copy() : [];
		playlistIndex = 0;
		if (playlist.length > 0) songData = playlist[0];
	}

	public var paused:Bool = false;
	public var isDead:Bool = false;

	public function new(?replay:Replay = null)
	{
		super();
		Global.allowInputs = true;

		EventRegistry.init();
		MechanicRegister.init();

		if (replay != null)
		{
			loadedReplay = replay;
			songData.song = replay.song;
			songData.difficulty = replay.difficulty;
			songData.mix = replay.mix;
		}
	}

	var rpcString:String = "";

	override public function create()
	{
		super.create();
		activeTweens(true);
		// Paths.clearStoredMemory();
		instance = this;
		events = [];
		isDead = false;

		Global.registerScript("songScript", songScript);
		songScript.load('songs/${songData.song}/${songData.mix}/script.hx');

		this.persistentUpdate = false;
		// this.persistentDraw = false;

		// < -- CAMERAS SETUP -- >//
		camGAME.bgColor = FlxColor.BLACK;
		camGAME.bgColor.alpha = 1;
		camHUD.bgColor.alpha = 0;
		camALT.bgColor.alpha = 0;

		FlxG.cameras.reset(camGAME);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camALT, false);

		// < -- PLAYFIELD SETUP -- >//
		playField = new PlayField(songData.song, songData.difficulty, songData.mix, loadedReplay);
		playField.camera = camHUD;
		playField.conductor.onBeat.add(beatHit);
		playField.conductor.onStep.add(stepHit);
		add(playField);

		captions = new SubtitleDisplay();
		captions.camera = camHUD;
		add(captions);

		for (handler in playField.inputHandlers) handler.game = this;

		this.conductor = playField.conductor;

		if (playField.inputHandlers.get('p1').isReplay) VALID_SCORE = false;

		// < -- BACKGROUND SETUP -- >//
		stage = new Stage(Shortcuts.getChart().meta.stage, conductor);
		add(stage);

		final chartMeta = Shortcuts.getChart().meta;
		for (opp in chartMeta.opponents) stage.addCharTo(opp, stage.opponents, playField.inputHandlers.get('opponent'));
		for (plyr in chartMeta.players) stage.addCharTo(plyr, stage.players, playField.inputHandlers.get('p1'));
		for (spct in chartMeta.spectators) stage.addCharTo(spct, stage.spectators);

		stage.updatePositioning();

		// initialize the modchart manager
		// fmInstance = new Manager();
		// add(fmInstance);

		Countdown.init(conductor, playField);

		if (chartMeta.hasCountdown)
		{
			// playField.healthBar.visible = false;
			Countdown.perform();

			Countdown.onStart.addOnce(() ->
			{
				playField.healthBar.performTransition();
				playField.healthBar.visible = true;
			});
		}

		// call on post create for scripts
		Global.scriptSet('game', instance);
		Global.scriptCall('onPostStageCreate');

		playField.onGhostTap.add((keyDir) -> Global.scriptCall('onGhostTap', [keyDir]));
		playField.onNoteHit.add((playerID, note, timing, isSustain) ->
		{
			final combo = playField.inputHandlers.get('p1').stats.combo;

			if
				((playerID == 'p1')
					&& (combo == 50 || combo == 200)
				) for (spectator in stage.spectators.members) if (Std.isOfType(
					spectator,
					Character
				)) cast(spectator, Character).playAnim((combo == 50) ? 'combo50' : 'combo200', true);

			Global.scriptCall('onNoteHit', [playerID, note, timing, isSustain]);
		});

		playField.onNoteMiss.add((playerID, note) ->
		{
			if (playerID == 'p1') for (spectator in stage.spectators.members) if (Std.isOfType(
				spectator,
				Character
			)) cast(spectator, Character).playAnim('comboBreak', true);

			Global.scriptCall('onNoteMiss', [playerID, note]);
		});

		playField.onSongCountdown.add((number) -> Global.scriptCall('onSongCountdown', [number]));

		playField.onSongStart.add(() -> Global.scriptCall('onSongStart'));
		playField.playback.onFinish.add(() -> endSong());

		// trace(SongData.retrieveData(song, difficulty, mix));

		rpcString = 'Playing ${playField.chart.content.meta.displayName} on ${songData.difficulty.toUpperCase()}';
		DiscordRPC.updatePresence(PLAYMODE, rpcString, "", true);

		// FlxG.signals.focusLost.add(()->pauseGame());
		// alright.
		// camHUD.fade(FlxColor.BLACK, conductor.crochet / 1000 * 2, true);
		camGAME.follow(camFollower, LOCKON, 1);
		camGAME.focusOn(camFollower.getPosition());

		MoonSettings.restartPending = false;

		setEvents();
		Global.scriptCall('onPostCreate');

		// make sure we clean everything unused up
		// AssetManager.clearUnused();
		// wait shit it cleans the gameover stuff lol
	}

	public function activeTweens(isActive:Bool)
	{
		FlxTimer.globalManager.forEach((t) -> if (!t.finished) t.active = isActive);
		FlxTween.globalManager.forEach((t) -> if (!t.finished) t.active = isActive);
	}

	public function setEvents()
	{
		preloadCameraShaders();

		camFollower.setPosition(stage?.cameraSettings?.startX ?? 0, stage?.cameraSettings?.startY ?? 0);
		camGAME.zoom = lastZoom = stage?.cameraSettings?.zoom ?? 1;
		isDead = false;
		allowGameBop = true;

		bopRate = Constants.DEFAULT_BOP_RATE;
		bopIntensity = Constants.DEFAULT_BOP_INTENSITY - 1;

		// < -- EVENTS SETUP -- >//
		var onLoadEvents = playField.chart.events.filter((e) -> e.runOnLoad == true);
		onLoadEvents.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

		for (event in onLoadEvents)
		{
			var ev = new MoonEvent(event.tag, event.values);
			ev.PRESET_VARIABLES = ['game' => this, 'stage' => stage, 'playField' => playField];
			ev.time = event.time;

			Global.scriptCall('onEvent', [ev.tag]);

			if (ev.valid) ev.exec();
			else
				EventRegistry.executeEvent(this, ev);
		}

		for (event in playField.chart.events)
		{
			if (event.runOnLoad == true) continue;

			var ev = new MoonEvent(event.tag, event.values);
			ev.PRESET_VARIABLES = ['game' => this, 'stage' => stage, 'playField' => playField];
			ev.time = event.time;
			events.push(ev);
		}

		events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
	}

	override public function update(elapsed:Float):Void
	{
		Global.scriptCall('onUpdate', [elapsed]);
		MechanicRegister.updateAll(elapsed);
		if (cameraShaderHandlers != null) for (handler in cameraShaderHandlers) handler.update(elapsed);
		super.update(elapsed);

		// camGAME.rotation += 0.5;

		// EVENTS CHECK
		if (events.length > 0)
		{
			for (event in events)
			{
				if (event.time <= conductor.time)
				{
					Global.scriptCall('onEvent', [event.tag]);

					if (event.valid) event.exec();
					else
						EventRegistry.executeEvent(this, event);

					events.remove(event);
				}
			}
		}

		if (allowGameBop) camGAME.zoom = FlxMath.lerp(camGAME.zoom, lastZoom, elapsed * 6);

		camHUD.zoom = FlxMath.lerp(camHUD.zoom, 1, elapsed * 6);

		// if (FlxG.keys.justPressed.NINE) FlxG.switchState(() -> new ChartConvert());
		if (FlxG.keys.justPressed.SEVEN)
		{
			Global.clearScriptList();
			EditorTransition.transitionToEditor(this);
			canPause = false;
		}

		if (MoonInput.justPressed(PAUSE)) pauseGame();

		if (playField.healthBar.health <= 0 && !isDead)
		{
			isDead = true;

			playField.playback.state = PAUSE;

			setCameraFocus('player', [0, 50], 1.4, {
				ease: FlxEase.circOut,
				startDelay: 0.01
			});
			setCameraZoom(1, 1, {
				ease: FlxEase.expoOut
			});
			openSubState(new Gameover());

			final reasons = ['got blueballed', 'has skill issue', 'gave up', 'freakin sucks'];
			moon.backend.archipelago.ArchipelagoManager.sendDeathLink(reasons[FlxG.random.int(0, reasons.length - 1)]);
		}

		// TODO: REMOVE, THIS IS DEBUGGIN
		if (FlxG.keys.justPressed.EIGHT) endSong();
		// if (FlxG.keys.justPressed.T) triggerVideoTrap();

		if (FlxG.keys.justPressed.F5)
		{
			Global.clearScriptList();
			AssetManager.clearUnused();
			Countdown.onStart.removeAll();
			FlxG.resetState();
		}

		// if(FlxG.keys.justPressed.FOUR)
		//	Countdown.perform();

		Global.scriptCall('onPostUpdate', [elapsed]);
	}

	public function showCaptions(textStr:String, duration:Float = 8.0, fontSize:Int = 24, boxType:SubtitleBoxType = ROUNDED, font:String = 'vcr.ttf', textColor:Dynamic = 0xFFFFFFFF, outlineColor:Dynamic = 0xFF000000, outlineType:String = 'None'):Void
		if (captions != null) captions.show(
		textStr,
		duration,
		fontSize,
		boxType,
		font,
		textColor,
		outlineColor,
		outlineType
	);

	public var camMov:FlxTween;
	public var camRot:FlxTween;
	public var camZoom:FlxTween;

	public function setCameraFocus(char:String, ?offsets:Array<Int>, ?duration:Float = 2, ?options:Null<TweenOptions>, ?isInstant:Bool = false)
	{
		TweenUtils.cancelTwn(camMov);
		final charPos = getCamPos(char);

		if (!isInstant) camMov = FlxTween.tween(camFollower, {
			x: (charPos[0] ?? 0) + (offsets[0] ?? 0),
			y: (charPos[1] ?? 0) + (offsets[1] ?? 0)
		}, duration, options);
		else
			camFollower.setPosition(charPos[0] + (offsets[0] ?? 0), charPos[1] + (offsets[1] ?? 0));

		Global.scriptCall('onCameraFocus', [getChar(char)?.type ?? CharacterType.OPPONENT]);
	}

	public function rotateCamera(rotation:Float, ?duration:Float = 2, ?options:Null<TweenOptions>, ?isInstant:Bool = false)
	{
		TweenUtils.cancelTwn(camRot);
		if (!isInstant) camRot = FlxTween.tween(camGAME, {
			rotation: rotation
		}, duration, options);
		else
			camGAME.rotation = rotation;
	}

	var lastZoom:Float;

	public function setCameraZoom(zoom:Float, duration:Float, ?options:Null<TweenOptions>, isInstant:Bool = false)
	{
		TweenUtils.cancelTwn(camZoom);
		allowGameBop = false;

		// trace('Setting zoom to $zoom in $duration', "DEBUG");
		if (!isInstant)
		{
			camZoom = FlxTween.tween(camGAME, {
				zoom: zoom
			}, duration, options);
			camZoom.onComplete = _ ->
			{
				lastZoom = camGAME.zoom;
				allowGameBop = true;
			};
		}
		else
		{
			allowGameBop = true;
			camGAME.zoom = lastZoom = zoom;
		}
	}

	public function getCamPos(charName:String):Array<Float>
	{
		final char = getChar(charName);
		if (char != null) return [
			char.getMidpoint().x + char.camOffsets[0],
			char.getMidpoint().y + char.camOffsets[1]
		];

		return [0, 0];
	}

	public function getChar(charName:String):Character
	{
		for (c in stage.chars)
		{
			if ('${c.character}-${c.ID}' == charName) return c;
			else
			{
				switch (charName)
				{
					case 'opponent':
						for (opponent in stage.opponents.members) if (Std.isOfType(opponent, Character)) return cast opponent;
					case 'spectator':
						for (spectator in stage.spectators.members) if (Std.isOfType(spectator, Character)) return cast spectator;
					case 'player':
						for (player in stage.players.members) if (Std.isOfType(player, Character)) return cast player;
				}
			}
		}

		trace('[PLAYSTATE] Could not get character with name $charName', "WARNING");
		return null;
	}

	public var bopRate:Int = Constants.DEFAULT_BOP_RATE;
	public var bopIntensity:Float = Constants.DEFAULT_BOP_INTENSITY - 1;
	public var allowGameBop:Bool = false;

	public function beatHit(curBeat:Float)
	{
		if (((curBeat % bopRate) == 0) && !playField.inCountdown)
		{
			if (allowGameBop) camGAME.zoom += bopIntensity;

			camHUD.zoom += bopIntensity;
			Global.scriptCall('onCameraBop', []);
		}

		// updates less frequently..!
		if (curBeat % 4 == 0) DiscordRPC.updatePresence(PLAYMODE, rpcString, 'Accuracy: ${Std.int(playField.inputHandlers.get("p1").stats.accuracy)}%', false);

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
		final data = SongData.saveData(songData, stat.score, stat.misses, stat.accuracy);
		if (VALID_SCORE) saved = data.contains('score') || data.contains('new');

		// saves replay stuff
		final p1Handler = playField.inputHandlers.get('p1');
		if (p1Handler.recording && p1Handler.recordedInputs.length > 0)
		{
			final rep = new Replay(songData.song, songData.difficulty, songData.mix);
			rep.inputs = p1Handler.recordedInputs.copy();
			rep.stats = Shortcuts.getStats();
			rep.date = Date.now().getTime();
			rep.filename = '${rep.song}_${rep.difficulty}_${rep.mix}_${rep.date}.mrp';
			rep.displayName = rep.toString();
			replaysToSave.push(rep);
		}

		// Playlist handling
		if (playlist.length > 0 && playlistIndex < playlist.length - 1)
		{
			camHUD.fade(FlxColor.BLACK, conductor.crochet / 1000 * 2, false, () ->
			{
				AssetManager.skipNextCleanup = false;
				Global.clearScriptList();
				instance = null;
				PlayField.instance = null;

				playlistIndex++;
				songData = playlist[playlistIndex];

				FlxG.switchState(() -> new LoadingScreen());
			});
		}
		else
		{
			setCameraFocus('spectator', [], conductor.crochet / 1000 * 2, {
				ease: FlxEase.circOut
			});
			camHUD.fade(FlxColor.BLACK, conductor.crochet / 1000 * 2, false, () -> exit(false, saved));
		}
	}

	override function closeSubState()
	{
		super.closeSubState();
	}

	override function onFocusLost()
	{
		super.onFocusLost();

		if (playField != null && MoonSettings.callSetting('Auto Pause')) pauseGame();
	}

	public function pauseGame()
	{
		if (paused || isDead || !canPause) return;

		paused = true;
		activeTweens(false);
		openSubState(new PauseScreen(camALT));
		if (playField.playback.state == PLAY) playField.playback.state = PAUSE;

		Global.scriptCall('onSongPause');
	}

	public function preloadCameraShaders():Void
	{
		ShaderFilterRegistry.init();

		final needed:Map<String, Array<String>> = [];

		for (e in playField.chart.events)
		{
			if (e.tag != 'Set Filter') continue;

			final target:String = e.values?.target ?? 'camGAME';
			final def = ShaderFilterRegistry.getByLabel(e.values?.filter) ?? ShaderFilterRegistry.get(e.values?.filter);
			if (def == null) continue;

			if (!needed.exists(target)) needed.set(target, []);
			final list = needed.get(target);
			if (list.indexOf(def.id) == -1) list.push(def.id);
		}

		for (target => ids in needed)
		{
			final handler = getCameraShaderHandler(target);
			if (handler == null) continue;

			for (id in ids)
			{
				if (handler.getShader(id) != null) continue;
				final def = ShaderFilterRegistry.get(id);
				if (def == null) continue;
				handler.add(id, def.create(), false);
			}
		}
	}

	public function getCamera(target:String):Null<MoonCamera>
	{
		return switch (target)
		{
			case 'camHUD':
				camHUD;
			case 'camALT':
				camALT;
			case 'camGAME':
				camGAME;
			default:
				null;
		};
	}

	/**
	 * Returns (and creates if needed) the MoonShaderHandler for a camera target name.
	 */
	public function getCameraShaderHandler(target:String):Null<MoonShaderHandler>
	{
		if (cameraShaderHandlers.exists(target)) return cameraShaderHandlers.get(target);

		final cam = getCamera(target);

		if (cam == null)
		{
			trace('[PlayState] Unknown camera target: $target', "WARNING");
			return null;
		}

		final handler = new MoonShaderHandler(cam);
		cameraShaderHandlers.set(target, handler);
		return handler;
	}

	public function resumeGame()
	{
		paused = false;
		activeTweens(true);
		if (!playField.inCountdown)
		{
			playField.playback.state = PLAY;
			playField.playback.resync();
		}

		Global.scriptCall('onSongResume');
	}

	public function exit(toMenu:Bool = true, savedData:Bool = false)
	{
		// jus to make sure
		AssetManager.skipNextCleanup = false;
		Global.clearScriptList();
		instance = null;
		PlayField.instance = null;
		Countdown.onStart.removeAll();

		// clears all shader instances.
		if (MoonShaderHandler.instances.length > 0) for (instance in MoonShaderHandler.instances) instance.destroy();
		cameraShaderHandlers.clear();

		if (toMenu) openSubState(new StickerSubState(new MainMenu()));
		else
			FlxG.switchState(() -> new ResultsState(playField.inputHandlers.get('p1').stats, playField.chart.content.meta, playField.difficulty, savedData));
	}

	static public function saveReplays()
	{
		#if sys
		if (!FileSystem.exists('assets/data/replays')) FileSystem.createDirectory('assets/data/replays');
		for (replay in replaysToSave)
		{
			final path = Paths.getPath('data/replays/${replay.filename}');

			final data = {
				song: replay.song,
				difficulty: replay.difficulty,
				mix: replay.mix,
				displayName: replay.displayName,
				replayCode: replay.date,
				stats: {
					misses: replay.stats.misses,
					accuracy: replay.stats.accuracy,
					score: replay.stats.score,
					maxCombo: replay.stats.highestCombo
				},
				inputs: replay.inputs
			};

			sys.io.File.saveContent(path, haxe.Json.stringify(data, null, "  \t"));
			trace('[REPLAY] Replay saved on $path');
		}
		#else
		trace("[REPLAY] Replay saving not supported on this platform", "ERROR");
		#end
	}

	public static function loadReplay(path:String):Replay
	{
		#if sys
		if (Paths.exists(path))
		{
			final content = Paths.getFileContent(path);
			if (content == "") return null;

			final json:Dynamic = haxe.Json.parse(content);
			final rep = new Replay(json.song, json.difficulty, json.mix);
			rep.inputs = json.inputs;
			return rep;
		}
		#end
		return null;
	}

	// ---------------- ARCHIPELAGO STUFF
	/// -traps

	public function triggerVideoTrap()
	{
		if (subState != null) subState.close();
		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		// TODO: make this a helper on paths?
		final exts = [".mp4", ".mkv", ".mov"];
		final videos:Array<String> = [];

		#if desktop
		function collect(rel:String)
		{
			for (mod in Mods.activeMods)
			{
				final modDir = '${mod.root}/$rel';
				if (!FileSystem.exists(modDir) || !FileSystem.isDirectory(modDir)) continue;
				for (entry in FileSystem.readDirectory(modDir))
				{
					final full = '$modDir/$entry';
					if (FileSystem.isDirectory(full)) collect('$rel/$entry');
					else
						for (ext in exts) if (entry.endsWith(ext))
						{
							videos.push('$rel/$entry');
							break;
						}
				}
			}

			final vanilla = Paths.getVanillaPath(rel);
			if (FileSystem.exists(vanilla) && FileSystem.isDirectory(vanilla)) for (entry in FileSystem.readDirectory(vanilla))
			{
				final full = '$vanilla/$entry';
				if (FileSystem.isDirectory(full)) collect('$rel/$entry');
				else
					for (ext in exts) if (entry.endsWith(ext))
					{
						videos.push('$rel/$entry');
						break;
					}
			}
		}

		collect('videos');
		#end

		if (videos.length == 0) return;

		final curVid = videos[FlxG.random.int(0, videos.length - 1)];
		trace('[ARCHIPELAGO] AD has been chosen: $curVid', "DEBUG");

		canPause = false;
		Global.allowInputs = false;
		paused = true;
		activeTweens(false);
		if (playField.playback.state == PLAY) playField.playback.state = PAUSE;

		openSubState(new VideoSubState({
			path: Paths.getPath(curVid),
			canPause: false,
			camera: camALT,
			onComplete: () ->
			{
				canPause = true;
				Global.allowInputs = true;
				paused = false;
				activeTweens(true);
				playField.playback.state = PLAY;
			},
			infoText: ":)"
		}));
	}
}
