package moon.game.obj;

import flixel.graphics.FlxGraphic;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;

using StringTools;

class HealthIcon extends MoonSprite
{
	public var icon(default, set):String;

	/**
	 * The icon data pulled from the character's JSON `icon` field.
	 */
	public var data:Character.HealthIconData;

	/**
	 * Extra scale added on top of whatever scale the healthbar assigns this icon.
	 */
	public var extraScale:Float = 0;

	/**
	 * A flip applied regardless of `data.flipX`, so the healthbar can mirror the
	 * player's icon layout-wise without fighting the character's own flip setting.
	 */
	public var baseFlipX:Bool = false;

	/**
	 * Same idea as `baseFlipX`, but vertical.
	 */
	public var baseFlipY:Bool = false;

	/**
	 * Whether to use the character's "old" icon variant, if `data.old` is set up.
	 */
	public var useOldIcon(default, set):Bool = false;

	/**
	 * Whether this icon is using the animated (Sparrow) format or the 2-frames one.
	 */
	public var isAnimated(default, null):Bool = false;

	/**
	 * Whether this icon should bop on the beat. Should be called `onStepHit` for this.
	 */
	public var shouldBop:Bool = true;

	/**
	 * Apply the bop once every X steps.
	 */
	public var bopEvery:Int = 4;

	static final HEALTH_ICON_SIZE:Int = 150;
	static final BOP_SCALE:Float = 0.2;
	static final WINNING_THRESHOLD:Float = 80;
	static final LOSING_THRESHOLD:Float = 20;

	var bopTween:FlxTween;

	public function new()
	{
		super();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	/**
	 * Updates the icon's animation/frame based on the given health (0-100).
	 */
	public dynamic function updateAnim(health:Float):Void
	{
		if (!isAnimated)
		{
			animation.curAnim.curFrame = (health < LOSING_THRESHOLD) ? 1 : 0;
			return;
		}

		switch (animation.curAnim?.name)
		{
			case 'idle' | null:
				if (health < LOSING_THRESHOLD) animOrFallback('toLosing', 'losing');
				else if (health > WINNING_THRESHOLD) animOrFallback('toWinning', 'winning');
				else
					animOrFallback('idle');

			case 'winning':
				if (health < WINNING_THRESHOLD) animOrFallback('fromWinning', 'idle');

			case 'losing':
				if (health > LOSING_THRESHOLD) animOrFallback('fromLosing', 'idle');

			case 'toLosing':
				if (animation.curAnim.finished) animOrFallback('losing', 'idle');

			case 'toWinning':
				if (animation.curAnim.finished) animOrFallback('winning', 'idle');

			case 'fromLosing' | 'fromWinning':
				if (animation.curAnim.finished) animOrFallback('idle');

			default:
				animOrFallback('idle');
		}
	}

	/**
	 * Bops the icon.
	 */
	public function onStepHit(curStep:Float, baseScale:Float):Void
	{
		if (bopEvery == 0 || !shouldBop || curStep % bopEvery != 0) return;

		// trace('bump!');

		TweenUtils.cancelTwn(bopTween);

		final targetSize = HEALTH_ICON_SIZE * baseScale;
		final bumpedSize = targetSize + (HEALTH_ICON_SIZE * baseScale * BOP_SCALE);

		setGraphicSize(Std.int(bumpedSize), 0);
		updateHitbox();

		bopTween = FlxTween.num(bumpedSize, targetSize, 0.15, {
			ease: FlxEase.quadOut
		}, value ->
		{
			setGraphicSize(Std.int(value), 0);
			updateHitbox();
		});
	}

	function animOrFallback(name:String, ?fallback:String):Void
	{
		if (animation.getByName(name) != null) playAnim(name);
		else if (fallback != null && animation.getByName(fallback) != null) playAnim(fallback);
	}

	@:noCompletion
	public function set_icon(val:String)
	{
		final char = (Paths.exists('characters/$val/icon.png')) ? val : 'asmile-erect';
		if (this.icon == char) return char;
		this.icon = char;

		loadIconGraphic();
		setGraphicSize(150, 150);

		centerAnimations = true;

		data = getIconData(char);

		extraScale = data?.scale ?? 0;
		this.antialiasing = data?.antialiasing ?? true;
		this.flipX = baseFlipX != (data?.flipX ?? false);
		this.flipY = baseFlipY != (data?.flipY ?? false);
		this.offset.x = data?.x ?? 0;
		this.offset.y = data?.y ?? 0;
		scrollFactor.set();
		updateHitbox();

		return char;
	}

	@:noCompletion
	public function set_useOldIcon(val:Bool)
	{
		useOldIcon = val;
		if (icon != null) loadIconGraphic();
		return val;
	}

	function loadIconGraphic():Void
	{
		var path = '$icon';
		if (data?.icon != null && data?.icon != '') path = data?.icon;
		if (useOldIcon && data?.old != null && Paths.exists('characters/${data.old}/icon.png')) path = data.old;

		final animPath = path + (useOldIcon ? '-old' : '');
		isAnimated = !useOldIcon && Paths.exists('characters/$animPath/icon.xml');

		if (isAnimated)
		{
			this.frames = Paths.getSparrowAtlas('$animPath/icon', 'characters');
			addIconAnim('idle', 24, true);
			addIconAnim('winning', 24, true);
			addIconAnim('losing', 24, true);
			addIconAnim('toWinning', 24, false);
			addIconAnim('toLosing', 24, false);
			addIconAnim('fromWinning', 24, false);
			addIconAnim('fromLosing', 24, false);
			animOrFallback('idle');
		}
		else
		{
			final graphic:FlxGraphic = Paths.image('$path/icon' + (useOldIcon ? '-old' : ''), 'characters');
			loadGraphic(graphic, true, Std.int(graphic.width / 2), Std.int(graphic.height));

			animation.add('icon', [0, 1], 0, false);
			playAnim('icon');
		}

		updateHitbox();
	}

	function addIconAnim(name:String, frameRate:Int, looped:Bool):Void
	{
		// only add it if frames matching this prefix actually exist...
		if (frames == null) return;
		var found = false;
		for (f in frames.frames)
		{
			if (f.name != null && f.name.startsWith(name))
			{
				found = true;
				break;
			}
		}
		if (found) animation.addByPrefix(name, name, frameRate, looped);
	}

	function getIconData(character:String):Character.HealthIconData
	{
		if (!Paths.exists('characters/$character/data.json')) return null;
		final charData:Character.CharacterData = cast Paths.JSON('characters/$character/data');
		return charData?.icon;
	}
}
