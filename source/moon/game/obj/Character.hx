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
}

typedef CharacterData =
{
	var ?antialiasing:Bool;
	var ?scale:Float;
	var ?type:AtlasType;
	var ?frameWidth:Int;
	var ?frameHeight:Int;
	var ?flipX:Bool;
	var ?camOffsets:Array<Float>;
	var ?extraOffsets:Array<Float>;
	var ?icon:HealthIconData;
	var ?danceFrequency:Int;
	var ?holdDuration:Int;
	var ?gameoverColorScheme:String;
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
	public var type:CharacterType;

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
		final oldRight = animation.getByName('singRIGHT').frames;
		animation.getByName('singRIGHT').frames = animation.getByName('singLEFT').frames;
		animation.getByName('singLEFT').frames = oldRight;
		if (animation.getByName('singRIGHTmiss') != null)
		{
			final oldMiss = animation.getByName('singRIGHTmiss').frames;
			animation.getByName('singRIGHTmiss').frames = animation.getByName('singLEFTmiss').frames;
			animation.getByName('singLEFTmiss').frames = oldMiss;
		}
	}

	public function checkDance(curBeat:Float)
	{
		if (animation.curAnim == null) return;

		final beatInt = Std.int(curBeat);
		if
			((animation.curAnim.name.startsWith("idle") || animation.curAnim.name.startsWith("dance"))
				&& (beatInt % danceFrequency == 0)
				&& (beatInt != lastDanceBeat)
			)
		{
			lastDanceBeat = beatInt;
			this.dance(true);
		}
	}

	override public function update(elapsed:Float)
	{
		if (conductor != null && animationHold >= conductor.stepCrochet / 1000 * holdDuration)
		{
			dance(true);
			animationHold = 0;
			animation.curAnim.curFrame = animation.curAnim.frames[animation.curAnim.frames.length - 1];
		}
		super.update(elapsed);
	}

	override public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0)
	{
		super.playAnim(animName, force, reversed, frame);

		if (animation.curAnim != null) if (animation.curAnim.name.startsWith('idle') || animation.curAnim.name.startsWith('sing')) animationHold = 0;
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

		switch (data.type)
		{
			case SPARROW:
				this.frames = Paths.getSparrowAtlas('$character/$atlasName', 'characters');
			case PACKED:
				this.frames = Paths.getPackerAtlas('$character/$atlasName', 'characters');
			case NONE:
				this.loadGraphic(Paths.image('$character/$atlasName', 'characters'), true, data?.frameWidth ?? 0, data?.frameHeight ?? 0);
			case ATLAS:
				// TODO: quality configs?
				this.frames = FlxAnimateFrames.fromAnimate(Paths.getPath('characters/$character/$atlasName') /*, {filterQuality: HIGH}*/);
		}

		AnimationUtils.mergeExtraSheets(this, data.animations, character, 'characters', data.type);

		camOffsets = data?.camOffsets ?? [0, 0];
		overrideAnims = data?.overrideAnims ?? [];
		idleAnims = loadAnimations(data.animations, data.type);
		danceFrequency = data?.danceFrequency ?? 2;
		holdDuration = data?.holdDuration ?? 8;
		gameoverColorScheme = FlxColor.fromString(data?.gameoverColorScheme ?? '0xFF4924ff');

		this.antialiasing = data?.antialiasing ?? true;
		this.scale.set(data?.scale ?? 1, data?.scale ?? 1);
		this.updateHitbox();
		this.playAnim("idle-0");
		this.flipX = data?.flipX ?? false;
		origin.set(width / 2, height);

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
}

enum abstract CharacterType(String)
{
	var OPPONENT = 'opponent';
	var PLAYER = 'player';
	var SPECTATOR = 'spectator';
}
