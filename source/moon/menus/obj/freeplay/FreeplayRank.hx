package moon.menus.obj.freeplay;

class FreeplayRank extends MoonSprite
{
	public var rank:String;

	public function new(?x:Float = 410, ?y:Float = 42)
	{
		super(x, y);
		frames = Paths.getSparrowAtlas("menus/freeplay/rankbadges");

		animation.addByPrefix("LOSS", "LOSS rank0", 24, false);
		animation.addByPrefix("GOOD", "GOOD rank0", 24, false);
		animation.addByPrefix("GREAT", "GREAT rank0", 24, false);
		animation.addByPrefix("EXCELLENT", "EXCELLENT rank0", 24, false);
		animation.addByPrefix("PERFECT", "PERFECT rank0", 24, false);
		animation.addByPrefix("PERFECT-GOLD", "PERFECT rank GOLD0", 24, false);

		/*addOffset("loss", -3, 4);
			addOffset("good", 0, 4);
			addOffset("great", 0, 4);
			addOffset("excellent", -2, 4);
			addOffset("perfect", 0, 2);
			addOffset("perfectGold", 0, 2); */
		centerAnimations = true;
		updateHitbox();

		antialiasing = true;
	}

	public function setRank(rank:String):Void
	{
		this.rank = rank;
		playAnim(rank, true);
		visible = true;
	}
}
