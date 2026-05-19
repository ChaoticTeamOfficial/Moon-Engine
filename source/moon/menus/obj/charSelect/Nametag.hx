package moon.menus.obj.charSelect;

class Nametag extends MoonSprite
{
	public var character(default, set):String;
	public function new(x:Float, y:Float, initChar:String = 'bf')
	{
		super(x, y);
		this.character = initChar;
		antialiasing = false;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	final mosaic = new MosaicShader();
	var mosaicTwn:FlxTween;
	@:noCompletion public function set_character(character:String):String
	{
		if(this.character == character) return this.character;
		this.character = character;

		loadGraphic((character != 'locked') ? Paths.image('$character/${character}Chill/nametag', 'characters') : Paths.image('menus/charSelect/lockedNametag'));
		this.shader = mosaic;
		TweenUtils.cancelTwn(mosaicTwn);

		mosaic.bSize = 32.0;
		mosaicTwn = FlxTween.tween(mosaic, {bSize: 1.0}, 0.4);

		return this.character;
	}
}