package moon.menus.obj.freeplay;

import openfl.filters.GlowFilter;
import moon.backend.gameplay.Timings;
import openfl.filters.DropShadowFilter;

class FreeplayRank extends FlxText
{
	public var rank:String;

	public function new(?x:Float = 410, ?y:Float = 42)
	{
		super(x, y);
		setFormat(Paths.font('5by7_b.ttf'), 38, FlxColor.WHITE, CENTER);
	}

	public function setRank(rank:String):Void
	{
		this.rank = rank;
		visible = true;

		for (rankD in Timings.thresholds) if (rankD.rank == rank)
		{
			this.color = rankD.color;
			this.text = rankD.short;
		}
	}
}
