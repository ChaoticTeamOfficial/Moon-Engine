package moon.menus.obj.freeplay;

import openfl.filters.GlowFilter;
import moon.backend.gameplay.Timings;
import openfl.filters.DropShadowFilter;

class FreeplayRank extends FilteredSprite
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

		addOffset("loss", -3, 4);
		addOffset("good", 0, 4);
		addOffset("great", 0, 4);
		addOffset("excellent", -2, 4);
		addOffset("perfect", 0, 2);
		addOffset("perfectGold", 0, 2);
		// centerAnimations = true;

		antialiasing = true;

		// animation.onFrameChange.add((_, _, _) -> updateFilter());
	}

	public function setRank(rank:String):Void
	{
		this.rank = rank;
		playAnim(rank, true);
		visible = true;

		updateFilter();
	}

	var rCol = FlxColor.WHITE;

	override public function update(o)
	{
		super.update(o);
	}

	function updateFilter()
	{
		for (rankD in Timings.thresholds) if (rankD.rank == this.rank && rCol != rankD.color) rCol = rankD.color;

		// filters = [];

		//						color, alpha, blurX, blurY, strength, quality
		// filters = [new GlowFilter(rCol, 1, 8, 8, 4, 3)];

		// 							dist, angle, col, alpha, blurX & Y, strength, quality
		// filters = [new DropShadowFilter(0, 0, rCol, 1, 12, 12, 7, 2, false, false, false)];
	}
}
