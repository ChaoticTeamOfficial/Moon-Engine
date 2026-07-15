package moon.game.obj.dialogue;

import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxPoint;
import flixel.tweens.*;

using StringTools;

/**
 * Class for handling dialogue portraits.
 */
class Portrait extends MoonSprite
{
	/**
	 * The current character for this portrait.
	 */
	public var char:String = '';

	/**
	 * The data on this portrait.
	 */
	public var data:DialogueCharacter;

	/**
	 * The sound effect played on the typer.
	 */
	public var beep:MoonSound = new MoonSound();

	public var thisTwn:FlxTween;

	public function new(char:String = 'bf')
	{
		super();
		this.char = char;
		final dataInfo = DialogueCharacter.getChar(char);
		final chardata = (Paths.exists('characters/$char/data.json')) ? Paths.JSON('characters/$char/data') : null;

		final rs = dataInfo?.soundData;
		data = {
			displayName: dataInfo?.displayName ?? '',
			soundData: {
				sounds: rs?.sounds ?? ['dialogue.wav'],
				playType: rs?.playType ?? 'order',
				pitchIntensity: rs?.pitchIntensity ?? 0.03
			},
			color: dataInfo?.color ?? chardata?.icon.color ?? [255, 255, 255],
			antialiasing: dataInfo?.antialiasing ?? true,
			position: dataInfo?.position ?? [],
			animations: dataInfo?.animations ?? []
		}

		for (audio in data.soundData.sounds)
		{
			final basePath = '$char/dialogue/$audio';
			// I should figure this out sometime.....
			// FlxG.sound.cache(Paths.exists('characters/$basePath') ? Paths.sound(basePath, 'characters') : Paths.sound('ui/dialogue/narrator.wav', 'sounds'));
		}

		// trace(data.animations);
		if (!Paths.exists('characters/$char/dialogue/portraits.png'))
		{
			trace('[PORTRAIT] Portraits for "$char" does not exist!', "ERROR");
			strID = 'noAnim';
			return;
		}

		this.frames = Paths.getSparrowAtlas('$char/dialogue/portraits', 'characters');
		for (i in 0...data.animations.length)
		{
			final anim = data.animations[i];
			(anim.indices != null) ? this.animation.addByIndices(
				anim.name,
				anim.prefix,
				anim.indices,
				'',
				anim.fps ?? 24,
				anim.looped ?? false
			) : this.animation.addByPrefix(anim.name, anim.prefix, anim.fps ?? 24, anim.looped ?? false);
			this.addOffset(anim.name, anim.x ?? 0, anim.y ?? 0);
		}

		antialiasing = data.antialiasing;
		updateHitbox();
		setPosition(data.position[0], data.position[1]);
	}

	private var soundIndex:Int = 0;
	private var doubleCounter:Int = 0;
	private var evenPhase:Bool = false;

	/**
	 * Plays the next dialogue beep.
	 */
	public function playBeep():Void
	{
		if (data.soundData == null || data.soundData.sounds == null || data.soundData.sounds.length == 0) return;

		final sounds:Array<String> = data.soundData.sounds;
		// trace(sounds);
		final playType:String = data.soundData.playType ?? "order";
		final pitchIntensity:Float = data.soundData.pitchIntensity ?? 0.0;

		var chosenSound:String = sounds[0];
		// trace('before: $chosenSound');
		switch (playType)
		{
			case "order":
				chosenSound = sounds[soundIndex];
				soundIndex = (soundIndex + 1) % sounds.length;

			case "order-double":
				chosenSound = sounds[soundIndex];
				doubleCounter++;
				if (doubleCounter >= 2)
				{
					doubleCounter = 0;
					soundIndex = (soundIndex + 1) % sounds.length;
				}

			case "random":
				chosenSound = sounds[FlxG.random.int(0, sounds.length - 1)];
			case "even-odds":
				var indices:Array<Int> = [];
				var phaseList = evenPhase ? evenIndices(sounds) : oddIndices(sounds);
				for (i in phaseList) indices.push(i);

				if (indices.length == 0)
				{
					evenPhase = !evenPhase;
					phaseList = evenPhase ? evenIndices(sounds) : oddIndices(sounds);
					for (i in phaseList) indices.push(i);
				}

				chosenSound = sounds[indices[0]];
				if (indices.length == 1) evenPhase = !evenPhase;
				else
					indices.shift();

			default:
				chosenSound = sounds[0];
		}
		// trace('after: $chosenSound');
		final basePath = '$char/dialogue/${chosenSound}';
		// trace('characters/$basePath');
		// trace(Paths.exists('characters/$basePath'));
		beep.loadEmbedded(Paths.exists('characters/$basePath') ? Paths.sound(basePath, 'characters') : Paths.sound('ui/dialogue/narrator.wav', 'sounds'));

		if (pitchIntensity > 0)
		{
			final pitchVariation = 1.0 + FlxG.random.float(-pitchIntensity, pitchIntensity);
			beep.pitch = pitchVariation;
		}
		else
			beep.pitch = 1.0;

		beep.play();
	}

	public function resetBeeps():Void
	{
		soundIndex = 0;
		doubleCounter = 0;
		evenPhase = false;
	}

	private function oddIndices(arr:Array<Dynamic>):Array<Int>
	{
		var res:Array<Int> = [];
		for (i in 0...arr.length) if (i % 2 == 1) res.push(i);
		return res;
	}

	private function evenIndices(arr:Array<Dynamic>):Array<Int>
	{
		var res:Array<Int> = [];
		for (i in 0...arr.length) if (i % 2 == 0) res.push(i);
		return res;
	}

	public function doAnim(anim:PortraitAnim, ?values:Dynamic)
	{
		TweenUtils.cancelTwn(thisTwn);
		final p:FlxPoint = FlxPoint.get(data.position[0], data.position[1]);

		switch (anim)
		{
			case JUMP:
				thisTwn = FlxTween.tween(this, {
					y: p.y - 16
				}, 0.1, {
					ease: FlxEase.quadOut,
					onComplete: _ -> thisTwn = FlxTween.tween(this, {
						y: p.y
					}, 0.1, {
						ease: FlxEase.quadIn
					})
				});
			case DOWN:
				thisTwn = FlxTween.tween(this, {
					y: this.y + 16
				}, 0.5, {
					ease: FlxEase.quadOut
				});
			case UP:
				thisTwn = FlxTween.tween(this, {
					y: this.y - 16
				}, 0.5, {
					ease: FlxEase.quadOut
				});
			case SHAKE:
				thisTwn = FlxTween.shake(this, 0.04, 0.2, XY);
			default: // nothing lol
		}
	}

	public function getColor():FlxColor return FlxColor.fromRGB(data.color[0], data.color[1], data.color[2]);
}

enum abstract PortraitAnim(String)
{
	var JUMP = 'jump';
	var DOWN = 'down';
	var UP = 'up';
	var SHAKE = 'shake';
	var NONE = 'none';
}
