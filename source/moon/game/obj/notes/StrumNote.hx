package moon.game.obj.notes;

class StrumNote extends MoonSprite
{
	public var data:Int;
	public var isCPU:Bool;
	public var skin:String;

	public function new(skin:String, data:Int, isCPU:Bool)
	{
		this.data = data;
		this.isCPU = isCPU;
		super();

		this.skin = skin;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed); // need this for animations to work :P
	}
}
