package moon.game.obj;

import moon.backend.data.Cutscene.CutsceneAction;
import animate.FlxAnimateFrames;
import moon.backend.data.Cutscene.CutsceneActor;
import moon.game.obj.*;
import moon.game.obj.Character.CharacterType;
import flixel.sound.FlxSound;

using StringTools;

/**
 * TODO: properly document!
 */
class CutscenePlayer extends FlxGroup
{
	public var data:Cutscene;
	public var actors:Map<String, FlxSprite> = new Map();
	public var onComplete = new FlxSignal();
	public var onSkip = new FlxSignal();
	public var playing(default, null):Bool = false;
	public var skippable:Bool = true;
	public var canPause:Bool = false;

	var playState:PlayState;
	var actionIndex:Int = 0;
	var activeTimers:Array<FlxTimer> = [];
	var activeTweens:Array<FlxTween> = [];
	var sequentialWaiting:Bool = false;
	var activeSounds:Array<FlxSound> = [];
	var soundById:Map<String, FlxSound> = new Map();

	public function new(cutscene:Cutscene, ?playState:PlayState)
	{
		super();
		this.data = cutscene;
		this.playState = playState ?? PlayState.instance;
		this.skippable = cutscene.skippable ?? true;
		this.canPause = cutscene.canPause ?? false;
	}

	/**
	 * Starts the cutscene.
	 */
	public function start():Void
	{
		if (data == null || data.actions == null)
		{
			trace('[CUTSCENE] No actions to play, skipping...', "INFO");
			finish();
			return;
		}

		playing = true;
		actionIndex = 0;

		if (playState != null) playState.playField.inCutscene = true;

		spawnActors();
		runNext();
	}

	public function skip():Void
	{
		if (!playing || !skippable) return;

		cancelAll();
		stopAllCutsceneSounds();

		while (actionIndex < data.actions.length)
		{
			final action = data.actions[actionIndex++];
			executeAction(action, true);
		}

		onSkip.dispatch();
		finish();
	}

	function finish():Void
	{
		playing = false;
		cancelAll();
		stopAllCutsceneSounds();

		if (playState != null) playState.startCountdown();

		for (id => spr in actors)
		{
			if (spr != null && spr.exists && !(spr is Character && isBoundCharacter(cast spr)))
			{
				spr.kill();
				remove(spr, true);
			}
		}
		actors.clear();

		onComplete.dispatch();
		kill();
	}

	function isBoundCharacter(c:Character):Bool
	{
		if (playState == null || playState.stage == null) return false;
		return playState.stage.chars.indexOf(c) != -1;
	}

	function spawnActors():Void
	{
		if (data.actors == null) return;

		for (def in data.actors)
		{
			if (def.id == null || def.id == "") continue;

			var spr:FlxSprite = null;

			if (def.bindExisting == true || def.character != null) spr = tryBindExisting(def);

			if (spr == null)
			{
				spr = spawnNewActor(def);
				if (spr != null)
				{
					add(spr);
					assignCamera(spr, def.camera);
				}
			}

			if (spr != null)
			{
				applyActorDefaults(spr, def);
				actors.set(def.id, spr);
			}
		}
	}

	function tryBindExisting(def:CutsceneActor):FlxSprite
	{
		if (playState == null) return null;

		final role = (def?.id ?? "").toLowerCase();
		if (role == "player" || role == "opponent" || role == "spectator") return playState.getChar(role);

		if (def.character != null)
		{
			final c = playState.getChar(def.character);
			if (c != null) return c;

			for (ch in playState.stage.chars) if (ch.character == def.character) return ch;
		}

		return playState.getChar(def.id);
	}

	function spawnNewActor(def:CutsceneActor):FlxSprite
	{
		if (def.character != null)
		{
			final char = new Character(def.x ?? 0, def.y ?? 0, def.character, playState?.conductor);
			return char;
		}

		if (def.image != null)
		{
			final spr = new MoonSprite(def.x ?? 0, def.y ?? 0);
			if (def.atlasType != null)
			{
				switch (def.atlasType)
				{
					case SPARROW:
						spr.frames = Paths.getSparrowAtlas(def.image, 'images');
					case PACKED:
						spr.frames = Paths.getPackerAtlas(def.image, 'images');
					case ATLAS:
						spr.frames = FlxAnimateFrames.fromAnimate(Paths.getPath('images/${def.image}'), {
							filterQuality: HIGH
						});
					default:
						// TODO: support for regular spritesheets?
						spr.loadGraphic(Paths.image(def.image));
				}
			}
			else
				spr.loadGraphic(Paths.image(def.image));

			if (def.animations != null) AnimationUtils.loadAnimations(spr, def.animations);

			return spr;
		}

		trace('[CUTSCENE] Actor "${def.id}" has no character or image.', "WARNING");
		return null;
	}

	function applyActorDefaults(spr:FlxSprite, def:CutsceneActor):Void
	{
		if (def.x != null) spr.x = def.x;
		if (def.y != null) spr.y = def.y;
		if (def.scale != null) spr.scale.set(def.scale, def.scale);
		if (def.alpha != null) spr.alpha = def.alpha;
		if (def.visible != null) spr.visible = def.visible;
		if (def.flipX != null) spr.flipX = def.flipX;
		if (def.antialiasing != null) spr.antialiasing = def.antialiasing;
	}

	function assignCamera(spr:FlxSprite, camName:String):Void
	{
		if (playState == null) return;
		final cam = playState.getCamera(camName ?? "camGAME");
		if (cam != null) spr.camera = cam;
	}

	function getActor(id:String):Null<FlxSprite>
	{
		if (id == null) return null;
		if (actors.exists(id)) return actors.get(id);
		if (playState != null)
		{
			final c = playState.getChar(id);
			if (c != null)
			{
				actors.set(id, c);
				return c;
			}
		}
		return null;
	}

	function runNext():Void
	{
		if (!playing) return;

		if (actionIndex >= data.actions.length)
		{
			finish();
			return;
		}

		final action = data.actions[actionIndex];
		actionIndex++;

		final waitTime = action.duration ?? 0.0;

		executeAction(action, false);

		if (action?.parallel ?? false) runNext();
		else
		{
			if (waitTime <= 0) runNext();
			else
			{
				sequentialWaiting = true;
				final t = new FlxTimer();
				activeTimers.push(t);
				t.start(waitTime, _ ->
				{
					sequentialWaiting = false;
					runNext();
				});
			}
		}
	}

	function executeAction(action:CutsceneAction, skipMode:Bool = false):Void
	{
		final type = (action.type ?? "").toLowerCase();
		final target = action.target;
		final values:Dynamic = action.values ?? {};
		final force = action.force ?? true;
		final ease = skipMode ? null : TweenUtils.resolveEase(action.ease);

		switch (type)
		{
			case "wait":
				// wawa

			case "playanim", "play_anim", "anim", "play animation":
				final spr = getActor(target);
				if (spr == null) return;

				final anim:String = values.anim ?? values.name ?? "idle";
				if (Std.isOfType(spr, Character))
				{
					final char:Character = cast spr;
					if (values.forceOverride == true) char.forcePlayAnim(anim, force, values.reversed ?? false, values.frame ?? 0);
					else
						char.playAnim(anim, force, values.reversed ?? false, values.frame ?? 0);
				}
				else if (spr.animation != null) spr.animation.play(anim, force, values.reversed ?? false, values.frame ?? 0);

			case "set", "setprop":
				final spr = getActor(target);
				if (spr != null) applyProps(spr, values);

			case "tween":
				final spr = getActor(target);
				if (spr == null) return;

				final props:Dynamic = Reflect.copy(values);
				Reflect.deleteField(props, "duration");

				if (skipMode) applyProps(spr, props);
				else
				{
					activeTweens.push(FlxTween.tween(spr, props, values.duration ?? action.duration ?? 0.5, {
						ease: ease,
						onComplete: t -> activeTweens.remove(t)
					}));
				}

			case "camera", "camerafocus", "focus":
				if (playState == null) return;
				final dur:Float = values?.duration ?? action?.duration ?? 0.5;
				playState.setCameraFocus(target ?? values?.char ?? "player", cast values?.offset ?? [0, 0], skipMode ? 0 : dur, {
					ease: ease
				}, skipMode);

			case "camerazoom", "zoom":
				if (playState == null) return;
				final dur:Float = values?.duration ?? action?.duration ?? 0.5;
				final instant = skipMode || dur <= 0 || action?.ease == "INSTANT";
				playState.setCameraZoom(values?.zoom ?? values?.value ?? 1.0, skipMode ? 0 : dur, {
					ease: ease
				}, instant);
				if (!instant && playState.camZoom != null) activeTweens.push(playState.camZoom);

			case "fade":
				if (playState == null) return;
				final cam = playState.getCamera(target ?? "camHUD");
				if (cam == null) return;
				cam.fade(
					FlxColor.fromString(values.color ?? "#000000"),
					skipMode ? 0 : (values.duration ?? action.duration ?? 0.5),
					(values.direction ?? "out").toLowerCase() == "in",
					null,
					force
				);

			case "flash":
				if (playState == null) return;
				final cam = playState.getCamera(target ?? "camGAME");

				if (cam == null) return;
				if (skipMode) return;

				cam.flash(FlxColor.fromString(values.color ?? "#FFFFFF"), values.duration ?? action.duration ?? 0.5, null, force);

			case "visible":
				final spr = getActor(target);
				if (spr != null) spr.visible = values.value ?? true;

			case "alpha":
				final spr = getActor(target);
				if (spr != null)
				{
					final a:Float = values.value ?? values.alpha ?? 1;
					final dur:Float = skipMode ? 0 : (values.duration ?? action.duration ?? 0);
					if (dur <= 0) spr.alpha = a;
					else
					{
						activeTweens.push(FlxTween.tween(spr, {
							alpha: a
						}, dur, {
							ease: ease,
							onComplete: t -> activeTweens.remove(t)
						}));
					}
				}

			case "playsound", "play_sound", "sound":
				if (skipMode) return;
				playCutsceneSound(values);

			case "stopsound", "stop_sound":
				stopCutsceneSound(values?.id ?? target, values?.fade ?? 0);

			case "fadesound", "fade_sound":
				if (skipMode)
				{
					final id:String = values?.id ?? target;
					final toVol:Float = values?.volume ?? values?.to ?? 0;
					if (toVol <= 0) stopCutsceneSound(id, 0);
					else
						setSoundVolume(id, toVol);
					return;
				}
				fadeCutsceneSound(values);

			case "stopallsounds", "stop_all_sounds":
				stopAllCutsceneSounds(values?.fade ?? 0);

			case "call", "callmethod":
				if (!skipMode) Global.scriptCall(values.method ?? values.name, values.args ?? []);

			default:
				trace('[CUTSCENE] Unknown action type: ${action.type}', "WARNING");
		}
	}

	function playCutsceneSound(values:Dynamic):Void
	{
		final path:String = values.sound ?? values.path ?? values.file;
		if (path == null || path == "")
		{
			trace('[CUTSCENE] playsound missing sound path.', "WARNING");
			return;
		}

		final looped:Bool = values.looped ?? values.loop ?? false;
		final id:String = values.id;

		final asset = Paths.sound(path, values?.folder ?? values?.from ?? "sounds");
		final snd = FlxG.sound.play(asset, values?.volume ?? 1.0, looped);

		if (snd == null) return;

		if (values.pitch != null) snd.pitch = values.pitch;

		activeSounds.push(snd);
		if (id != null && id != "")
		{
			if (soundById.exists(id))
			{
				final old = soundById.get(id);
				if (old != null)
				{
					old.stop();
					activeSounds.remove(old);
				}
			}
			soundById.set(id, snd);
		}

		if (!looped)
		{
			snd.onComplete = () ->
			{
				activeSounds.remove(snd);
				if (id != null) soundById.remove(id);
			};
		}
	}

	function stopCutsceneSound(?id:String, fadeOut:Float = 0):Void
	{
		if (id != null && id != "" && soundById.exists(id))
		{
			final snd = soundById.get(id);
			killSound(snd, fadeOut);
			soundById.remove(id);
			activeSounds.remove(snd);
			return;
		}

		stopAllCutsceneSounds(fadeOut);
	}

	function fadeCutsceneSound(values:Dynamic):Void
	{
		final toVol:Float = values?.volume ?? values?.to ?? 0;
		final dur:Float = values?.duration ?? 0.5;
		final fromVol:Null<Float> = values?.from;

		final list:Array<FlxSound> = [];
		if (values?.id != null && soundById.exists(values?.id)) list.push(soundById.get(values?.id));
		else
			for (s in activeSounds) list.push(s);

		for (snd in list)
		{
			if (snd == null) continue;
			if (fromVol != null) snd.volume = fromVol;

			if (dur <= 0)
			{
				snd.volume = toVol;
				if (toVol <= 0) killSound(snd, 0);
			}
			else if (toVol <= 0) snd.fadeOut(dur, _ -> killSound(snd, 0));
			else
				snd.fadeIn(dur, snd.volume, toVol);
		}
	}

	function setSoundVolume(?id:String, vol:Float):Void
	{
		if (id != null && soundById.exists(id))
		{
			final s = soundById.get(id);
			if (s != null) s.volume = vol;
			return;
		}
		for (s in activeSounds) if (s != null) s.volume = vol;
	}

	function stopAllCutsceneSounds(fadeOut:Float = 0):Void
	{
		for (snd in activeSounds.copy()) killSound(snd, fadeOut);
		activeSounds = [];
		soundById.clear();
	}

	function killSound(snd:FlxSound, fadeOut:Float = 0):Void
	{
		if (snd == null) return;
		if (fadeOut > 0 && snd.playing)
		{
			snd.fadeOut(fadeOut, _ ->
			{
				snd.stop();
				snd.kill();
			});
		}
		else
		{
			snd.stop();
			snd.kill();
		}
	}

	function applyProps(spr:FlxSprite, values:Dynamic):Void
	{
		if (values == null) return;
		if (values.x != null) spr.x = values.x;
		if (values.y != null) spr.y = values.y;
		if (values.alpha != null) spr.alpha = values.alpha;
		if (values.visible != null) spr.visible = values.visible;
		if (values.angle != null) spr.angle = values.angle;
		if (values.flipX != null) spr.flipX = values.flipX;
		if (values.scale != null)
		{
			if (Std.isOfType(values.scale, Float)) spr.scale.set(values.scale, values.scale);
			else
			{
				spr.scale.x = values.scale.x ?? spr.scale.x;
				spr.scale.y = values.scale.y ?? spr.scale.y;
			}
		}
	}

	function cancelAll():Void
	{
		for (t in activeTimers) if (t != null) t.cancel();
		activeTimers = [];
		for (tw in activeTweens) if (tw != null && tw.active) tw.cancel();
		activeTweens = [];
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (playing && skippable && FlxG.keys.justPressed.ENTER) skip();
	}

	override public function destroy():Void
	{
		cancelAll();
		stopAllCutsceneSounds();
		actors.clear();
		super.destroy();
	}
}
