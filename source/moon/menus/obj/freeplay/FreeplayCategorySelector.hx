package moon.menus.obj.freeplay;

import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.util.FlxSpriteUtil;
import moon.backend.data.SongLibrary;
import flixel.group.FlxGroup;

class FreeplayCategorySelector extends FlxTypedGroup<Dynamic>
{
	public var leftArrow:MoonSprite;
	public var rightArrow:MoonSprite;
	public var text:FlxText;
	public var bg:MoonSprite;
	public var centerX:Float = 0;
	public var centerY:Float = 0;

	var categories:Array<String> = [];
	var curIndex:Int = 0;

	static final TEXT_SIZE:Int = 26;
	static final ARROW_SCALE:Float = 0.5;
	static final ARROW_GAP:Float = 18;
	static final BG_PAD_X:Float = 48;
	static final BG_PAD_Y:Float = 10;

	public function new()
	{
		super();

		loadCategories();

		bg = new MoonSprite();
		bg.makeGraphic(1, 1, 0x00000000);
		bg.antialiasing = true;
		bg.active = false;
		add(bg);

		leftArrow = new MoonSprite(0, 0);
		leftArrow.loadGraphic(Paths.image('menus/freeplay/arrow'));
		leftArrow.flipX = true;
		leftArrow.antialiasing = true;
		leftArrow.scale.set(ARROW_SCALE, ARROW_SCALE);
		leftArrow.updateHitbox();
		add(leftArrow);

		rightArrow = new MoonSprite(0, 0);
		rightArrow.loadGraphic(Paths.image('menus/freeplay/arrow'));
		rightArrow.antialiasing = true;
		rightArrow.scale.set(ARROW_SCALE, ARROW_SCALE);
		rightArrow.updateHitbox();
		add(rightArrow);

		text = new FlxText(0, 0, 0, "", TEXT_SIZE);
		text.setFormat(Paths.font('phantomuff/full.ttf'), TEXT_SIZE, FlxColor.WHITE, CENTER);
		text.antialiasing = true;
		text.alpha = 0.0001;
		add(text);

		updateUI(true);
	}

	function loadCategories()
	{
		categories = SongLibrary.get().categoryOrder.copy();
		if (categories.length == 0) categories = ['all'];
	}

	public function setIndex(index:Int, instant:Bool = true)
	{
		curIndex = FlxMath.wrap(index, 0, categories.length - 1);
		if (instant) updateUI(true);
	}

	public function getCurrent():String return categories[curIndex];

	public function getIndex():Int return curIndex;

	public function change(delta:Int)
	{
		if (categories.length <= 1) return;
		curIndex = FlxMath.wrap(curIndex + delta, 0, categories.length - 1);
		updateUI(false, delta);
	}

	public function setPos(x:Float, y:Float)
	{
		centerX = x;
		centerY = y;
	}

	public function updateUI(instant:Bool = false, delta:Int = 0)
	{
		final newName = SongLibrary.getCategoryDisplayName(categories[curIndex]).toUpperCase();

		if (instant)
		{
			text.text = newName;
			text.fieldWidth = 0;
			text.updateHitbox();
			text.alpha = 1;
			text.y = centerY - text.height / 2;
			text.x = centerX - text.width / 2;
			positionArrows(true);
		}
		else
		{
			FlxTween.cancelTweensOf(text);

			FlxTween.tween(text, {
				alpha: 0,
				y: centerY - text.height / 2 - 14
			}, 0.14, {
				ease: FlxEase.cubeIn,
				onComplete: _ ->
				{
					text.text = newName;
					text.fieldWidth = 0;
					text.updateHitbox();
					text.y = centerY - text.height / 2 + 14;
					text.x = centerX - text.width / 2;

					FlxTween.tween(text, {
						alpha: 1,
						y: centerY - text.height / 2
					}, 0.18, {
						ease: FlxEase.cubeOut
					});
				}
			});

			if (delta != 0) nudgeArrow(delta > 0 ? 1 : -1, 0.12);
		}
	}

	function nudgeArrow(dir:Int, duration:Float)
	{
		final arrow = dir > 0 ? rightArrow : leftArrow;
		if (arrow == null) return;

		FlxTween.cancelTweensOf(arrow.scale);
		final baseScale = ARROW_SCALE;
		arrow.scale.set(baseScale * 1.25, baseScale * 1.25);
		FlxTween.tween(arrow.scale, {
			x: baseScale,
			y: baseScale
		}, duration, {
			ease: FlxEase.backOut
		});
	}

	function positionArrows(instant:Bool)
	{
		final targetY = centerY - leftArrow.height / 2;

		if (instant)
		{
			leftArrow.x = text.x - leftArrow.width - ARROW_GAP;
			leftArrow.y = targetY;
			rightArrow.x = text.x + text.width + ARROW_GAP;
			rightArrow.y = targetY;
			updateBg();
		}
	}

	function updateBg()
	{
		final totalW = leftArrow.width + ARROW_GAP + text.width + ARROW_GAP + rightArrow.width + BG_PAD_X * 2;
		final totalH = Math.max(text.height, leftArrow.height) + BG_PAD_Y * 2;

		if (bg.width != Std.int(totalW) || bg.height != Std.int(totalH))
		{
			bg.makeGraphic(Std.int(totalW), Std.int(totalH), FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawRoundRect(bg, 0, 0, totalW, totalH, 16, 16, 0xCC1a1a1a);
			bg.updateHitbox();
		}

		bg.x = centerX - totalW / 2;
		bg.y = centerY - totalH / 2;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		final lerpSpeed = 12.0 * elapsed;
		text.x = FlxMath.lerp(text.x, centerX - text.width / 2, lerpSpeed);
		if (Math.abs(text.y - (centerY - text.height / 2)) < 8) text.y = FlxMath.lerp(text.y, centerY - text.height / 2, lerpSpeed);

		leftArrow.x = FlxMath.lerp(leftArrow.x, text.x - leftArrow.width - ARROW_GAP, lerpSpeed);
		leftArrow.y = FlxMath.lerp(leftArrow.y, centerY - leftArrow.height / 2, lerpSpeed);

		rightArrow.x = FlxMath.lerp(rightArrow.x, text.x + text.width + ARROW_GAP, lerpSpeed);
		rightArrow.y = FlxMath.lerp(rightArrow.y, centerY - rightArrow.height / 2, lerpSpeed);

		updateBg();
	}
}
