package moon.game.obj;

import flixel.graphics.FlxGraphic;

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

	public function new()
	{
		super();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	/**
	 * Will update the icon's framed based on the given health.
	 * @param health the health value.
	 */
	public dynamic function updateAnim(health:Float) animation.curAnim.curFrame = (health < 20) ? 1 : 0;

	@:noCompletion
	public function set_icon(val:String)
	{
		final char = (Paths.exists('characters/$val/icon.png')) ? val : 'asmile-erect';
		if (this.icon == char) return char;
		this.icon = char;

		centerAnimations = true;

		data = getIconData(char);

		extraScale = data?.scale ?? 0;
		this.antialiasing = data?.antialiasing ?? true;
		this.flipX = baseFlipX != (data?.flipX ?? false);
		this.flipY = baseFlipY != (data?.flipY ?? false);

		loadIconGraphic();

		scrollFactor.set();

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

		final graphic:FlxGraphic = Paths.image('$path/icon' + (useOldIcon ? '-old' : ''), 'characters');
		loadGraphic(graphic, true, Std.int(graphic.width / 2), Std.int(graphic.height));

		animation.add('icon', [0, 1], 0, false);
		playAnim('icon');
		updateHitbox();
	}

	function getIconData(character:String):Character.HealthIconData
	{
		if (!Paths.exists('characters/$character/data.json')) return null;
		final charData:Character.CharacterData = cast Paths.JSON('characters/$character/data');
		return charData?.icon;
	}
}
