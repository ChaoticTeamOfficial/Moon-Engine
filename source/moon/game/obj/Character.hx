package moon.game.obj;

import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxFramesCollection;
import moon.dependency.scripting.*;

using StringTools;

typedef HealthIconData =
{
	var ?icon:String;
	var ?old:String;
	var ?scale:Float;
	var ?color:Array<Int>;
	var ?antialiasing:Bool;
	var ?flipX:Bool;
	var ?flipY:Bool;
	var ?x:Float;
	var ?y:Float;
}

typedef CharacterData =
{
	var ?antialiasing:Bool;
	var ?isPlayer:Bool;
	var ?scale:Float;
	var ?type:AtlasType;
	var ?frameWidth:Int;
	var ?frameHeight:Int;
	var ?extendIdleDuration:Bool;
	var ?flipX:Bool;
	var ?camOffsets:Array<Float>;
	var ?extraOffsets:Array<Float>;
	var ?icon:HealthIconData;
	var ?danceFrequency:Int;
	var ?holdDuration:Int;
	var ?gameoverColorScheme:String;
	var ?spritesheet:String;
	var animations:Array<Paths.AnimationData>;
	var ?overrideAnims:Array<String>;
}

class Character extends MoonSprite
{
	public var data:CharacterData;
	public var conductor:Conductor;
	public var character(default, set):String;
	public var animationHold:Float = 0;
	public var script:MoonScript;
	public var holdDuration:Int = 8;
	public var gameoverColorScheme:FlxColor;
	public var camOffsets:Array<Float> = [];
	public var type(default, set):CharacterType;
	public var extendIdleDuration:Bool = false;
	public var holding:Bool = false;
	public var isPlayer:Bool = false;

	/**
	 * Creates a character on the screen.
	 * @param x X Position.
	 * @param y Y Position.
	 * @param character The character name.
	 * @param conductor The conductor instance.
	 */
	public function new(?x:Float = 0, ?y:Float = 0, ?character:String = 'dad', conductor:Conductor)
	{
		super(x, y);
		this.conductor = conductor;

		script = new MoonScript();

		this.character = character;

		if (conductor != null)
		{
			conductor.onStep.add(step ->
			{
				if (
					animation.curAnim != null
					&& (animation.curAnim.name.startsWith('sing') || animation.curAnim.name.startsWith('miss'))
				) animationHold += conductor.stepCrochet / 1000;
			});

			conductor.onBeat.add(checkDance);
		}
	}

	public function flipLeftRight():Void
	{
		for (name in animation.getNameList())
		{
			if (!name.contains('singLEFT')) continue;

			final rightName = name.replace('singLEFT', 'singRIGHT');
			if (!animation.exists(rightName)) continue;

			final oldRight = animation.getByName(rightName).frames;
			animation.getByName(rightName).frames = animation.getByName(name).frames;
			animation.getByName(name).frames = oldRight;
		}
	}

	public function checkDance(curBeat:Float)
	{
		if (animation.curAnim == null) return;

		final beatInt = Std.int(curBeat);
		final name = animation.curAnim.name;

		if ((name.startsWith("idle") || name.startsWith("dance") || idleHold) && (beatInt % danceFrequency == 0) && (beatInt != lastDanceBeat))
		{
			lastDanceBeat = beatInt;
			this.dance(true);
		}
	}

	override public function update(elapsed:Float)
	{
		if (conductor != null)
		{
			if (extendIdleDuration && animation.curAnim != null && animation.curAnim.name == 'idle-0')
			{
				animation.curAnim.frameRate = animation.curAnim.frames.length * (conductor.bpm / danceFrequency) / 60.0;
			}

			if (animationHold >= conductor.stepCrochet / 1000 * holdDuration && !holding)
			{
				dance(true);
				animationHold = 0;
				animation.curAnim.curFrame = animation.curAnim.frames[animation.curAnim.frames.length - 1];
			}
		}
		super.update(elapsed);
	}

	override public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		super.playAnim(animName, force, reversed, frame);

		if (animation.curAnim != null)
		{
			final name = animation.curAnim.name;
			if (name.startsWith('idle') || name.startsWith('sing')) animationHold = 0;
			if (name.startsWith('sing') || name.startsWith('miss')) idleHold = false;
		}
	}

	public function updateScale()
	{
		if (data == null) return;
		this.scale.set(data?.scale ?? 1, data?.scale ?? 1);
	}

	@:noCompletion
	public function set_character(char:String):String
	{
		if (this.character == char) return char;

		if (Global.scripts.exists(this.character)) Global.unregisterScript(this.character);

		if (!Paths.exists('characters/$char/data.json'))
		{
			trace('[CHARACTER] Specified character "$char" data does not exist. Loading default...', "WARNING");
			char = 'asmile-erect';
		}

		this.character = char;
		data = cast Paths.JSON('characters/$character/data');
		if (data.type == null) data.type = SPARROW;

		// yayy subfolder support :D
		// I like having things clean inside the same folder, sooo.. I thought... Why not!?
		var atlasName = character;
		if (character.indexOf('/') != -1)
		{
			final parts = character.split('/');
			atlasName = parts[parts.length - 1];
		}

		final sheetKey = data.spritesheet ?? '$character/$atlasName';

		switch (data.type)
		{
			case SPARROW:
				this.frames = Paths.getSparrowAtlas(sheetKey, 'characters');
			case PACKED:
				this.frames = Paths.getPackerAtlas(sheetKey, 'characters');
			case NONE:
				this.loadGraphic(Paths.image(sheetKey, 'characters'), true, data?.frameWidth ?? 0, data?.frameHeight ?? 0);
			case ATLAS:
				// TODO: quality configs?
				this.frames = FlxAnimateFrames.fromAnimate(Paths.getPath('characters/$sheetKey'), {
					filterQuality: HIGH
				});
		}

		AnimationUtils.mergeExtraSheets(this, data.animations, character, 'characters', data.type);

		camOffsets = data?.camOffsets ?? [0, 0];
		overrideAnims = data?.overrideAnims ?? [];
		idleAnims = loadAnimations(data.animations, data.type);
		danceFrequency = data?.danceFrequency ?? 2;
		holdDuration = data?.holdDuration ?? 8;
		gameoverColorScheme = FlxColor.fromString(data?.gameoverColorScheme ?? '0xFF4924ff');
		extendIdleDuration = data?.extendIdleDuration ?? false;
		isPlayer = data?.isPlayer ?? false;

		this.antialiasing = data?.antialiasing ?? true;

		this.updateHitbox();
		this.playAnim("idle-0");
		this.flipX = data?.flipX ?? false;
		origin.set(width / 2, height);
		updateScale();

		script.load('characters/${this.character}/script.hx');
		if (script.code != null)
		{
			script.set('char', this);
			if (script.exists('onCharCreate')) script.call('onCharCreate');

			Global.registerScript('script-${this.character}-${script?.get("scriptID") ?? 0}', script);
		}

		return char;
	}

	override function destroy()
	{
		super.destroy();

		if (script.code != null) Global.unregisterScript('script-${this.character}-${script?.get("scriptID") ?? 0}');

		conductor = null;
	}

	@:noCompletion
	public function set_type(type:CharacterType):CharacterType
	{
		this.type = type;

		if ((isPlayer && type == OPPONENT) || (!isPlayer && type == PLAYER))
		{
			flipX = !flipX;
			flipLeftRight();
		}

		return type;
	}
}

enum abstract CharacterType(String)
{
	var OPPONENT = 'opponent';
	var PLAYER = 'player';
	var SPECTATOR = 'spectator';
}
