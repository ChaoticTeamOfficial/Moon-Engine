package moon.game.obj;

import flixel.tweens.FlxTween;
import flixel.text.FlxText.FlxTextBorderStyle;

enum abstract SubtitleBoxType(String) from String to String
{
	var NONE = "None";
	var ROUNDED = "Rounded";
	var RECTANGLE = "Rectangle";
	var NOTESKIN = "Noteskin";
}

class SubtitleDisplay extends FlxSpriteGroup
{
	public var box:FlxSprite;
	public var text:FlxText;

	private var currentTmr:FlxTimer;
	private var fadeTwn:FlxTween;
	private var isShowing:Bool = false;
	private var currentBoxType:SubtitleBoxType = ROUNDED;
	private var targetBoxAlpha:Float = 0.65;

	public function new()
	{
		super();

		box = new FlxSprite();
		box.scrollFactor.set();
		add(box);

		text = new FlxText(0, 0, 24);
		text.alignment = CENTER;
		text.size = 24;
		text.font = Paths.font('vcr.ttf');
		text.scrollFactor.set();
		add(text);

		visible = false;
	}

	public function show(textStr:String, duration:Float = 8.0, fontSize:Int = 24, boxType:SubtitleBoxType = ROUNDED, font:String = 'vcr.ttf', textColor:Dynamic = 0xFFFFFFFF, outlineColor:Dynamic = 0xFF000000, outlineType:String = 'None'):Void
	{
		if (text == null) return;

		TweenUtils.cancelTmr(currentTmr);
		FlxTween.cancelTweensOf(box);
		FlxTween.cancelTweensOf(text);
		TweenUtils.cancelTwn(fadeTwn);

		text.text = textStr;
		text.font = Paths.font(font);
		text.color = FlxColor.fromString(textColor);
		text.size = fontSize;

		final olType = switch (outlineType.toLowerCase())
		{
			case "shadow":
				FlxTextBorderStyle.SHADOW;
			case "outline":
				FlxTextBorderStyle.OUTLINE;
			default:
				FlxTextBorderStyle.NONE;
		};

		if (olType != FlxTextBorderStyle.NONE) text.setBorderStyle(olType, FlxColor.fromString(outlineColor), 2.0, 1.0);
		else
			text.setBorderStyle(FlxTextBorderStyle.NONE);

		final pad:Float = 32;

		text.fieldWidth = FlxG.width / 2;
		text.updateHitbox();

		_rebuildBox(boxType, text.fieldWidth + pad, (text.textField.textHeight + (pad / 2)) + pad / 2);

		box.screenCenter(X);
		box.y = FlxG.height - box.height - 112;

		text.x = box.x + (box.width - text.fieldWidth) / 2;
		text.y = box.y + (box.height - text.textField.textHeight) / 2;

		visible = true;
		isShowing = true;

		box.alpha = targetBoxAlpha;
		text.alpha = 1;
		box.visible = (currentBoxType != NONE);

		if (box.alpha == 0 || text.alpha == 0)
		{
			box.alpha = 0;
			text.alpha = 0;

			fadeTwn = FlxTween.tween(box, {
				alpha: targetBoxAlpha
			}, 0.25, {
				ease: FlxEase.quadOut
			});
			FlxTween.tween(text, {
				alpha: 1
			}, 0.25, {
				ease: FlxEase.quadOut
			});
		}

		currentTmr = new FlxTimer().start(duration, _ -> hide(false));
	}

	private function _rebuildBox(boxType:SubtitleBoxType, w:Float, h:Float):Void
	{
		currentBoxType = boxType;

		box.makeGraphic(Std.int(w), Std.int(h), FlxColor.TRANSPARENT);

		switch (currentBoxType)
		{
			case NONE:
				box.visible = false;
				targetBoxAlpha = 0;
			case RECTANGLE:
				box.visible = true;
				targetBoxAlpha = 0.75;
				FlxSpriteUtil.drawRect(box, 0, 0, w, h, FlxColor.BLACK);
			case NOTESKIN:
				box.visible = true;
				targetBoxAlpha = 0.35;
				FlxSpriteUtil.drawRect(box, 0, 0, w, h, FlxColor.WHITE);
			case ROUNDED:
				box.visible = true;
				targetBoxAlpha = 0.65;
				FlxSpriteUtil.drawRoundRect(box, 0, 0, w, h, 24, 24, FlxColor.BLACK);
		}
	}

	public function hide(immediate:Bool = false):Void
	{
		TweenUtils.cancelTmr(currentTmr);
		FlxTween.cancelTweensOf(box);
		FlxTween.cancelTweensOf(text);
		if (fadeTwn != null)
		{
			fadeTwn.cancel();
			fadeTwn = null;
		}

		isShowing = false;

		if (immediate)
		{
			visible = false;
			text.alpha = 0;
			box.alpha = 0;
		}
		else
		{
			FlxTween.tween(text, {
				alpha: 0
			}, 0.4, {
				ease: FlxEase.quadIn
			});
			fadeTwn = FlxTween.tween(box, {
				alpha: 0
			}, 0.4, {
				ease: FlxEase.quadIn,
				onComplete: (_) ->
				{
					if (!isShowing) visible = false;
				}
			});
		}
	}

	override public function destroy():Void
	{
		TweenUtils.cancelTmr(currentTmr);
		FlxTween.cancelTweensOf(box);
		FlxTween.cancelTweensOf(text);
		if (fadeTwn != null) fadeTwn.cancel();
		super.destroy();
	}
}
