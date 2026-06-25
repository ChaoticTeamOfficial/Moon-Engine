package moon.utils;

import moon.backend.data.JudgementsCombo;

using StringTools;

@:publicFields
/**
 * A class that holds mostly utilities related to sprites.
 */
class SpriteUtils
{
	/**
	 * Centers `spriteA` on `spriteB`.
	 * @param spriteA The sprite that will be centered.
	 * @param spriteB The sprite who will use as a center base.
	 * @param axes Which axes to center.
	 */
	static function centerSprite(spriteA:FlxSprite, spriteB:FlxSprite, ?axes:FlxAxes = XY)
	{
		if (axes == X || axes == XY) spriteA.x = spriteB.x + spriteB.width / 2 - spriteA.width / 2;

		if (axes == Y || axes == XY) spriteA.y = spriteB.y + spriteB.height / 2 - spriteA.height / 2;
	}

	/**
	 * Starts the appear animation and chains to disappear. Don't use it on sprites with offsets, as this messes with them.
	 * @param sprite The sprite to animate.
	 * @param anim The appear animation type (e.g. 'jump-in').
	 * @param outAnim The disappear animation type (e.g. 'fade').
	 * @param setTween A function that updates the caller's tween reference.
	 */
	static function doAppearAnim(sprite:MoonSprite, anim:AppearAnim, outAnim:DisappearAnim, setTween:FlxTween->Void)
	{
		var tween:FlxTween = null;
		final duration = 0.32;
		sprite.skew.set(0, 0);
		switch (anim)
		{
			case JUMP_IN, JUMP_OUT:
				final ogOffset = sprite.offset.y;
				sprite.offset.y = ogOffset;
				sprite.offset.y = (anim == JUMP_IN) ? -8 : 8;
				tween = FlxTween.tween(sprite, {
					"offset.y": ogOffset
				}, duration, {
					ease: FlxEase.expoOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case SCALE, PULSE:
				final resizeTo = anim == PULSE ? 1.25 : 0.75;
				final ogScaleX = sprite.scale.x;
				final ogScaleY = sprite.scale.y;

				sprite.scale.set(ogScaleX * resizeTo, ogScaleY * resizeTo);

				tween = FlxTween.tween(sprite.scale, {
					x: ogScaleX,
					y: ogScaleY
				}, duration, {
					ease: FlxEase.expoOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case SKEW_X, SKEW_Y, SKEW_BOTH:
				final n = (FlxG.random.bool(50)) ? -18 : 18;
				sprite.skew.set((anim == SKEW_X || anim == SKEW_BOTH) ? n : 0, (anim == SKEW_Y || anim == SKEW_BOTH) ? n : 0);
				tween = FlxTween.tween(sprite.skew, {
					x: 0,
					y: 0
				}, duration, {
					ease: FlxEase.circOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case SLIDE, SLIDE_SKEW:
				final ogOffset = sprite.offset.x;
				sprite.offset.x = ogOffset;
				sprite.offset.x = ogOffset + 15;
				if ('$anim'.contains('skew')) sprite.skew.x = 22;
				tween = FlxTween.tween(sprite, {
					"offset.x": ogOffset,
					"skew.x": 0
				}, duration + 0.3, {
					ease: FlxEase.expoOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case LIGHT:
				final ogScaleX = sprite.scale.x;
				final ogScaleY = sprite.scale.y;

				sprite.scale.set(ogScaleX * 0.85, ogScaleY * 0.85);

				tween = FlxTween.tween(sprite.scale, {
					x: ogScaleX,
					y: ogScaleY
				}, duration, {
					ease: FlxEase.expoOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case ANGLE:
				sprite.angle = FlxG.random.int(-15, 15);
				tween = FlxTween.tween(sprite, {
					angle: 0
				}, duration, {
					ease: FlxEase.expoOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case LASER:
				final ogCol = sprite.color;
				tween = FlxTween.color(sprite, duration, FlxColor.WHITE, ogCol, {
					ease: FlxEase.circOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			case SHAKE:
				tween = FlxTween.shake(sprite, 0.03, duration - 0.16, XY, {
					ease: FlxEase.expoOut,
					onComplete: _ -> doDisappearAnim(sprite, outAnim, setTween)
				});

			default:
				trace('[UTILS] Unknown appear anim: $anim', "ERROR");
				doDisappearAnim(sprite, outAnim, setTween);
		}

		setTween(tween);
	}

	/**
	 * Starts the disappear animation.
	 * @param sprite The sprite to animate.
	 * @param anim The disappear animation type.
	 * @param setTween A function that updates the caller's tween reference.
	 */
	static function doDisappearAnim(sprite:MoonSprite, anim:DisappearAnim, setTween:FlxTween->Void)
	{
		final duration = 0.8;
		final delay = 0.2;

		var tween:FlxTween = null;
		switch (anim)
		{
			case FADE:
				tween = FlxTween.tween(sprite, {
					alpha: 0.0001
				}, duration, {
					startDelay: delay
				});

			case SCALE, SCALE_FADE:
				tween = FlxTween.tween(sprite, {
					"scale.x": 0,
					"scale.y": 0,
					alpha: '$anim'.contains('fade') ? 0.0001 : 1
				}, duration, {
					startDelay: delay,
					ease: FlxEase.circIn,
					onComplete: _ -> sprite.alpha = 0.0001
				});

			case BOUNCE, BOUNCE_FADE:
				tween = FlxTween.tween(sprite, {
					"scale.x": sprite.scale.x * 1.6,
					"scale.y": sprite.scale.y * 1.6,
					alpha: ('$anim'.contains('fade')) ? 0.0001 : 1
				}, duration, {
					startDelay: delay,
					ease: FlxEase.circIn,
					onComplete: _ -> sprite.alpha = 0.0001
				});

			case SKEW_X, SKEW_Y, SKEW_BOTH, SKEW_X_FADE, SKEW_Y_FADE, SKEW_BOTH_FADE:
				tween = FlxTween.tween(sprite, {
					"skew.x": ('$anim'.contains('skewX') || '$anim'.contains('skewBoth')) ? 100 : 0,
					"skew.y": ('$anim'.contains('skewY') || '$anim'.contains('skewBoth')) ? 100 : 0,
					alpha: ('$anim'.contains('fade')) ? 0.0001 : 1
				}, duration, {
					ease: FlxEase.expoIn,
					startDelay: delay,
					onComplete: _ -> sprite.alpha = 0.0001
				});

			case SQUISH_X, SQUISH_Y:
				final squishX = (anim == SQUISH_X) ? sprite.scale.x * 1.4 : 0;
				final squishY = (anim == SQUISH_Y) ? sprite.scale.y * 1.4 : 0;
				tween = FlxTween.tween(sprite.scale, {
					x: squishX,
					y: squishY
				}, duration - 0.3, {
					startDelay: delay,
					ease: FlxEase.circIn,
					onComplete: _ -> sprite.alpha = 0.0001
				});

			default:
				trace('[UTILS] Unknown disappear anim: $anim', "ERROR");
				sprite.alpha = 0.0001;
		}

		setTween(tween);
	}
}
