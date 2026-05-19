package moon.menus.obj.charSelect;

import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;
import flixel.util.FlxSignal.FlxTypedSignal;

class CharGrid extends FlxSpriteGroup
{
	public var columns:Int;
	public var spacing:Int;

	public static var curSelected:Int = 4;
	public static var curChar:String;
	public var list:Array<String> = [];

	public final onChange:FlxTypedSignal<Int->Void> = new FlxTypedSignal<Int->Void>();

	var selectedBizz:Array<BitmapFilter> = [
	    new DropShadowFilter(0, 0, 0xfcfcfc, 1, 2, 2, 19, 1, false, false, false),
	    new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
	];

	public function new(columns:Int, spacing:Int)
	{
		super();
		this.columns = columns;
		this.spacing = spacing;
	}

	public function setupGrid(items:Array<String>):Void
	{
		this.list = items;

		if(this.members.length > 0)
			clear();

		final lockColors = [
			0xFF31F2A5, 0xFF20ECCD, 0xFF24D9E8,
			0xFF20ECCD, 0xFF20C8D4, 0xFF209BDD,
			0xFF209BDD, 0xFF2362C9, 0xFF243FB9
		];

		for (i in 0...items.length)
		{
			final pos = FlxPoint.get((i % columns) * spacing , (Math.floor(i / columns)) * spacing);

			if(items[i] != "locked")
			{
				final icon = new PixelIcon(0,0, items[i]);
				add(icon);
				icon.setPosition(pos.x - icon.width / 2, pos.y - icon.height / 2);
			}
			else
			{
				final icon = new FilteredSprite(0,0).loadGraphic(Paths.image('menus/charSelect/lock'));
				add(icon);
				icon.antialiasing = false;
				//icon.color = lockColors[i];
				icon.setPosition(pos.x - icon.width / 2, pos.y - icon.height / 2);
			}
		}
	}

	public function scroll(direction:Int)
	{
		final lastSelected = curSelected;
		final length = members.length;

		if (length == 0) return;

		final numRows = Std.int((length - 1) / columns) + 1;

		var row = Std.int(curSelected / columns);
		var col = curSelected % columns;

		if (direction != 0)
		{
			final delta = direction > 0 ? 1 : -1;

			if (Math.abs(direction) == 1)
				col = (col + delta + columns) % columns;
			else if (Math.abs(direction) == columns)
				row = (row + delta + numRows) % numRows;

			curSelected = row * columns + col;

			if (curSelected >= length)
				curSelected = lastSelected;
		}

		for(i in 0...members.length)
		{
			final ico = cast(members[i], FilteredSprite);
			TweenUtils.cancelTwn(ico.twn);

			final sel = (curSelected == i);
			ico.filters = sel ? selectedBizz : null;

			ico.scale.set(2, 2);
			ico.strID = '';
			if(sel) ico.twn = FlxTween.tween(ico, {"scale.x": 3, "scale.y": 3}, 0.1, {ease: FlxEase.backOut, onComplete: _->ico.strID = "bump"});
		}

		curChar = list[curSelected];

		onChange.dispatch(direction);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		for(i in 0...members.length)
		{
			final ico = cast(members[i], FilteredSprite);

			if(i == curSelected && ico.strID == 'bump')
				ico.scale.x = ico.scale.y = FlxMath.lerp(ico.scale.x, 3, elapsed * 16);
		}
	}

	public function beat(beat:Float)
	{
		final ico = cast(members[curSelected], FilteredSprite);

		if(ico.strID == 'bump' && beat % 2 == 0)
			ico.scale.x = ico.scale.y = 3.3;
	}
}