package moon.menus.obj.freeplay;

import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.backend.gameplay.*;
import moon.global_obj.PixelIcon;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;

using StringTools;

class FreeplaySongItem extends FlxSpriteGroup
{
	static final TEXT_GAP:Float = 10.0;
	static final TEXT_W:Int = 260;
	static final LERP_SPEED:Float = 14;
	static final RANK_FADE_SPEED:Float = 12;
	static final DIFF_SWITCH_DURATION:Float = 0.35;

	public var targetAlpha:Float = 1.0;
	public var targetScale:Float = 1.0;
	public var lerpAlpha:Float = 0.0;
	public var lerpScale:Float = 1.0;
	public var transitioning:Bool = false;
	public var data:Chart;
	public var bg:MoonSprite;
	public var icon:PixelIcon;
	public var nameText:ScrollingText;
	public var scoreText:FlxText;
	public var rankDisplay:FreeplayRank;

	private var _lastRank:String = null;
	private var _rankAlphaMult:Float = 0;
	private var _isDiffSwitching:Bool = false;
	final selectedFilters:Array<BitmapFilter> = [
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

	public function setEnterValues():Void
	{
		lerpAlpha = 0;
		lerpScale = 0;
	}

	public function loadEntry(entry:SongBase):Void
	{
		data = new Chart(entry.song, entry.difficulty, entry.mix);

		if (icon.character != data.content.meta.opponents[0]) icon.character = data.content.meta.opponents[0];

		nameText.setText(data.content.meta.displayName.toUpperCase());
	}

	public function setSelected(selected:Bool, scoreVal:Int = -1, accPct:Float = -1):Void
	{
		updateFilters(selected);
		updateScoreText(selected, scoreVal, accPct);
		updateRank(accPct);
	}

	function updateFilters(selected:Bool):Void icon.filters = selected ? selectedFilters : null;

	function updateScoreText(selected:Bool, scoreVal:Int, accPct:Float):Void
	{
		scoreText.visible = selected;
		if (!selected) return;

		final scoreStr = (scoreVal >= 0) ? '${MoonUtils.formatNumber(scoreVal)} SCORE' : '-- SCORE';
		final accStr = (accPct >= 0) ? '${Std.int(accPct)}% ACCURACY' : '--% ACCURACY';

		scoreText.text = '$scoreStr\n$accStr';
	}

	function updateRank(accPct:Float):Void
	{
		if (accPct < 0)
		{
			hideRank();
			return;
		}

		final rankResult = Timings.getRank(accPct);
		final rank = rankResult.rank;

		if (rank == null || rank == 'NOT FOUND')
		{
			hideRank();
			return;
		}

		if (rank != _lastRank)
		{
			_lastRank = rank;
			rankDisplay.setRank(rank);
			_rankAlphaMult = 0;
		}

		rankDisplay.visible = true;
	}

	function hideRank():Void
	{
		if (_lastRank == null && !rankDisplay.visible) return;
		_lastRank = null;
		_rankAlphaMult = 0;
		rankDisplay.visible = false;
	}

	public function forceResetRank():Void
	{
		_lastRank = null;
		_rankAlphaMult = 0;
		rankDisplay.visible = false;
	}

	public function playDifficultySwitchEffect():Void
	{
		_isDiffSwitching = true;

		bg.brightness = 0.5;
		FlxTween.tween(bg, {
			brightness: 0
		}, DIFF_SWITCH_DURATION, {
			ease: FlxEase.circOut,
			onComplete: _ -> _isDiffSwitching = false
		});

		final originalScale = lerpScale;
		lerpScale *= 1.12;

		FlxTween.tween(this, {
			lerpScale: originalScale
		}, DIFF_SWITCH_DURATION, {
			ease: FlxEase.elasticOut
		});
	}

	public function lerpVisuals(elapsed:Float):Void
	{
		if (transitioning) return;

		final t = elapsed * LERP_SPEED;
		lerpAlpha = FlxMath.lerp(lerpAlpha, targetAlpha, t);
		lerpScale = FlxMath.lerp(lerpScale, targetScale, t);

		_rankAlphaMult = FlxMath.lerp(_rankAlphaMult, 1.0, elapsed * RANK_FADE_SPEED);
		if (_rankAlphaMult > 0.99) _rankAlphaMult = 1.0;
	}

	public function applyPositions(px:Float, py:Float):Void
	{
		applyIconPosition(px, py);
		applyTextPositions(px, py);
		applyBackgroundPosition();
		applyRankPosition();
	}

	function applyIconPosition(px:Float, py:Float):Void
	{
		icon.scale.set(lerpScale + 1, lerpScale + 1);
		icon.setPosition(px, py);
		icon.alpha = lerpAlpha;
		icon.updateHitbox();
	}

	function applyTextPositions(px:Float, py:Float):Void
	{
		final textX = px + 96 * lerpScale + TEXT_GAP;
		final textOffsetY = (icon.height * lerpScale - 22 * lerpScale) * 0.5 - 7 * lerpScale;

		nameText.scale.set(lerpScale, lerpScale);
		nameText.setPosition(textX, py + textOffsetY);
		nameText.alpha = lerpAlpha;

		scoreText.scale.set(lerpScale, lerpScale);
		scoreText.setPosition(textX, nameText.y + 24 * lerpScale);
		scoreText.alpha = lerpAlpha * 0.85;
	}

	function applyBackgroundPosition():Void
	{
		bg.scale.set(lerpScale, lerpScale);
		bg.updateHitbox();
		bg.setPosition(icon.x + 11, (nameText.y + nameText.height / 2 - bg.height / 2) + 8);
	}

	function applyRankPosition():Void
	{
		rankDisplay.setPosition(nameText.x + nameText.width, nameText.y);
		rankDisplay.scale.set(lerpScale, lerpScale);
		rankDisplay.alpha = lerpAlpha * _rankAlphaMult;
	}

	public function doRankReveal():Void
	{
		transitioning = true;
		// TODO!
	}

	/**
	 * Does the 'confirm' animation on the icon and a nice lil effect on the object itself.
	 */
	public function doConfirm():Void
	{
		icon.playAnim('select', true);
		FlxFlicker.flicker(nameText, 1.79, 0.05, true);

		bg.brightness = 1;
		FlxTween.tween(bg, {
			brightness: 0
		}, 0.8);
	}

	public function snapToTarget():Void
	{
		lerpAlpha = targetAlpha;
		lerpScale = targetScale;
		_rankAlphaMult = 1.0;
	}

	public function hide():Void
	{
		icon.alpha = 0;
		nameText.alpha = 0;
		scoreText.alpha = 0;
		scoreText.visible = false;
		rankDisplay.visible = false;
	}
}
