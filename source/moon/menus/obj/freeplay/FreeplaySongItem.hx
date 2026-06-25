package moon.menus.obj.freeplay;

import flixel.group.FlxSpriteGroup;
import moon.backend.gameplay.*;
import moon.global_obj.PixelIcon;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;

using StringTools;

class FreeplaySongItem extends FlxSpriteGroup
{
	static final TEXT_GAP:Float = 10.0;
	static final TEXT_W:Int = 260;

	public var targetAlpha:Float = 1.0;
	public var targetScale:Float = 1.0;
	public var lerpAlpha:Float = 0.0;
	public var lerpScale:Float = 1.0;
	public var transitioning:Bool = false;
	public var bg:MoonSprite;
	public var icon:PixelIcon;
	public var nameText:ScrollingText;
	public var scoreText:FlxText;
	public var rankDisplay:FreeplayRank;
	public var data:Chart;

	final selectedBizz:Array<BitmapFilter> = [
		new DropShadowFilter(0, 0, 0xfcfcfc, 1, 2, 2, 19, 1, false, false, false),
		new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
	];

	public function new()
	{
		super();

		bg = new MoonSprite().makeGraphic(416, 84, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, bg.width, bg.height, 12, 12, 0xFF1d1d1d);
		bg.antialiasing = true;
		bg.active = false;
		add(bg);

		icon = new PixelIcon(-9999, -9999, 'bf');
		add(icon);

		nameText = new ScrollingText(-9999, -9999, TEXT_W, '', 22);
		nameText.textField.font = Paths.font('phantomuff/full.ttf');
		nameText.antialiasing = true;
		nameText.alpha = 0;
		add(nameText);

		scoreText = new FlxText(-9999, -9999, TEXT_W, '', 13);
		scoreText.font = Paths.font('phantomuff/full.ttf');
		scoreText.antialiasing = true;
		scoreText.color = 0xFFAAAAAA;
		scoreText.visible = false;
		scoreText.active = false;
		scoreText.alpha = 0;
		add(scoreText);

		rankDisplay = new FreeplayRank();
		rankDisplay.visible = false;
		add(rankDisplay);
	}

	public function loadEntry(entry:SongBase):Void
	{
		data = new Chart(entry.song, entry.difficulty, entry.mix);

		if (icon.character != data.content.meta.opponents[0]) icon.character = data.content.meta.opponents[0];

		nameText.setText(data.content.meta.displayName.toUpperCase());
	}

	private var _lastRank:String = null;

	public function setSelected(selected:Bool, scoreVal:Int = -1, accPct:Float = -1)
	{
		scoreText.visible = selected;
		icon.filters = selected ? selectedBizz : null;

		if (selected)
		{
			scoreText.text = (
				(scoreVal >= 0) ? '${MoonUtils.formatNumber(scoreVal)} SCORE' : '-- SCORE')
				+ '\n'
				+ ((accPct >= 0) ? '${Std.int(accPct)}% ACCURACY' : '--% ACCURACY');
		}

		final rank = Timings.getRank(accPct).rank;
		if (rank != _lastRank)
		{
			_lastRank = rank;
			if ((rank != null && rank != 'NOT FOUND' && accPct >= 0))
			{
				rankDisplay.setRank(rank);
				rankDisplay.visible = true;
			}
			else
				rankDisplay.visible = false;
		}
	}

	public function lerpVisuals(elapsed:Float):Void
	{
		if (transitioning) return;
		final t = elapsed * 14;
		lerpAlpha = FlxMath.lerp(lerpAlpha, targetAlpha, t);
		lerpScale = FlxMath.lerp(lerpScale, targetScale, t);
	}

	public function applyPositions(px:Float, py:Float):Void
	{
		icon.scale.set(lerpScale + 1, lerpScale + 1);
		icon.setPosition(px, py);
		icon.alpha = lerpAlpha;
		icon.updateHitbox();

		final textX = px + 96 * lerpScale + TEXT_GAP;

		nameText.scale.set(lerpScale, lerpScale);
		nameText.setPosition(textX, py + (icon.height * lerpScale - 22 * lerpScale) * 0.5 - 7 * lerpScale);
		nameText.alpha = lerpAlpha;

		scoreText.scale.set(lerpScale, lerpScale);
		scoreText.setPosition(textX, nameText.y + 24 * lerpScale);
		scoreText.alpha = lerpAlpha * 0.85;

		bg.scale.set(lerpScale, lerpScale);
		bg.updateHitbox();
		bg.setPosition(icon.x + 11, (nameText.y + nameText.height / 2 - bg.height / 2) + 8);

		rankDisplay.setPosition(nameText.x + nameText.width, nameText.y);
		rankDisplay.scale.set(lerpScale, lerpScale);
		rankDisplay.alpha = lerpAlpha;
	}

	public function doRankReveal()
	{
		transitioning = true;
	}

	/**
	 * Does the 'confirm' animation on the icon and a nice lil effect on the object itself.
	 */
	public function doConfirm()
	{
		icon.playAnim('select', true);
		FlxFlicker.flicker(nameText, 1.79, 0.05, true);

		bg.brightness = 1;
		FlxTween.tween(bg, {
			brightness: 0
		}, 0.8);
	}

	/**
	 * Snap to targets immediately.
	 */
	public function snapToTarget():Void
	{
		lerpAlpha = targetAlpha;
		lerpScale = targetScale;
	}

	/**
	 * Resets the rank.
	 */
	public function resetRank():Void
	{
		_lastRank = null;
		rankDisplay.visible = false;
	}

	/**
	 * Hides all members. 
	 */
	public function hide():Void
	{
		icon.alpha = nameText.alpha = scoreText.alpha = 0;
		scoreText.visible = false;
		rankDisplay.visible = false;
	}
}
