package moon.dependency;

import flixel.FlxSprite;
import flixel.animation.FlxAnimation;
import flixel.group.*;
import flixel.math.FlxPoint;
import flixel.system.FlxAssets;
import flixel.util.FlxArrayUtil;
import flixel.util.FlxColor;
import flixel.util.FlxDestroyUtil;
#if flash
import flash.display.BlendMode;
#else
import openfl.display.BlendMode;
#end

/**
 * A modified version of FlxTrail with some cool additions.
 * I made this for FlxDeltarune, but I'll have it here too XD
 * @author Gama11 (Original FlxTrail)
 */
class MoonTrail extends flixel.group.FlxSpriteContainer.FlxTypedSpriteContainer<MoonSprite>
{
	/**
	 * Stores the MoonSprite the trail is attached to.
	 */
	public var target(default, null):MoonSprite;

	/**
	 * How often to update the trail
	 */
	public var delay:Int;

	/**
	 * Whether the trail generation is paused
	 */
	public var paused:Bool = false;

	/**
	 * The velocity applied to each trail sprite.
	 */
	public var trailVelocity:Array<Float> = [0, 0];

	/**
	 * Whether to check for x changes or not. When false, trail sprites are
	 * emitted at this container's own x position instead of the target's.
	 */
	public var xEnabled:Bool = true;

	/**
	 * Whether to check for y changes or not. When false, trail sprites are
	 * emitted at this container's own y position instead of the target's.
	 */
	public var yEnabled:Bool = true;

	/**
	 * Whether to check for angle changes or not.
	 */
	public var rotationsEnabled:Bool = true;

	/**
	 * Whether to check for scale changes or not.
	 */
	public var scalesEnabled:Bool = true;

	/**
	 * Whether to check for frame changes of the parent FlxSprite or not.
	 */
	public var framesEnabled:Bool = true;

	/**
	 * Whether trail sprites should inherit the target's color/tint.
	 */
	public var colorsEnabled:Bool = true;

	/**
	 * Whether trail sprites should inherit the target's blend mode.
	 * Ignored if `overrideBlend` is set.
	 */
	public var blendsEnabled:Bool = true;

	/**
	 * If set, forces every trail sprite to use this blend mode instead of
	 * whatever the target is currently using.
	 */
	public var overrideBlend:Null<BlendMode> = null;

	/**
	 * If set, forces every trail sprite to use this color instead of
	 * whatever the target is currently using.
	 */
	public var overrideColor:Null<FlxColor> = null;

	/**
	 * The maximum number of trail sprites.
	 */
	public var trailLength:Int = 10;

	/**
	 * The trail's additive offsets.
	 */
	public var offsets:Array<Float> = [0, 0];

	var _counter:Int = 0;
	var _graphic:flixel.system.FlxAssets.FlxGraphicAsset;
	var _initialAlpha:Float = 0.4;
	var _alphaDecrement:Float = 0.05;
	var _spriteOrigin:FlxPoint;

	/**
	 * Creates a Trail effect for a MoonSprite.
	 *
	 * @param target The MoonSprite the trail will be attached to.
	 * @param graphic The image to use for the Trail Sprites. If none, will use the FlxSprite's graphic.
	 * @param length The maximum amount of sprites the trail can have.
	 * @param delay How often to update the trail. 0 will update it every frame.
	 * @param alpha The initial alpha value for newly created sprites for the trail.
	 * @param diff How much to decrement the alpha of existing sprites when a new one is added
	 */
	public function new(target:MoonSprite, ?graphic:flixel.system.FlxAssets.FlxGraphicAsset, length = 10, delay = 3, alpha = 0.4, diff = 0.05):Void
	{
		super();

		_spriteOrigin = FlxPoint.get().copyFrom(target.origin);

		this.target = target;
		this.delay = delay;
		this._graphic = graphic;
		this._initialAlpha = alpha;
		this._alphaDecrement = diff;
		this.trailLength = length;

		solid = false;
	}

	override public function destroy():Void
	{
		FlxDestroyUtil.put(_spriteOrigin);
		_spriteOrigin = null;

		target = null;
		_graphic = null;
		trailVelocity = null;

		super.destroy();
	}

	override public function update(elapsed:Float):Void
	{
		// bail early if the target has been destroyed out from under us
		if (target == null)
		{
			super.update(elapsed);
			return;
		}

		_counter++;

		if (_counter >= delay && countLiving() < trailLength)
		{
			_counter = 0;

			for (i in 0...members.length)
			{
				final sprite = members[i];
				if (sprite != null && sprite.exists)
				{
					sprite.alpha -= _alphaDecrement;
					if (sprite.alpha <= 0) sprite.kill();
				}
			}

			// emit new sprite if still under length
			if (countLiving() < trailLength && !paused) emitTrailSprite();
		}

		// enforces max length, killing oldest if exceeded
		while (countLiving() > trailLength)
			killOldest();

		super.update(elapsed);
	}

	private function emitTrailSprite():Void
	{
		// TODO: animations not playing properly on animate sprites
		var trailSprite:MoonSprite = recycle(MoonSprite);
		trailSprite.active = true;
		trailSprite.solid = solid;
		trailSprite.alpha = _initialAlpha;

		trailSprite.x = xEnabled ? target.x : this.x;
		trailSprite.y = yEnabled ? target.y : this.y;

		if (rotationsEnabled) trailSprite.angle = target.angle;

		if (rotationsEnabled || scalesEnabled) trailSprite.origin.copyFrom(_spriteOrigin);

		if (scalesEnabled) trailSprite.scale.copyFrom(target.scale);

		if (_graphic == null)
		{
			trailSprite.loadGraphicFromSprite(target);
			if (target.frames != null) trailSprite.frames = target.frames;

			trailSprite.animation.copyFrom(target.animation);

			if (target.isAnimate)
			{
				target.useRenderTexture = true;
				trailSprite.useRenderTexture = true;
			}

			trailSprite.brightness = target.brightness;

			if (framesEnabled && target.animation.curAnim != null)
			{
				final curAnim = target.animation.curAnim;
				trailSprite.flipX = target.flipX;
				trailSprite.flipY = target.flipY;
				trailSprite.forcePlayAnim(curAnim.name, true, false, curAnim.curFrame);
				// trailSprite.animation.curAnim.frameRate = 0;
			}
		}
		else
			trailSprite.loadGraphic(_graphic);

		trailSprite.offset.copyFrom(target.offset);
		trailSprite.offset.x += offsets[0];
		trailSprite.offset.y += offsets[1];

		if (overrideColor != null) trailSprite.color = overrideColor;
		else if (colorsEnabled) trailSprite.color = target.color;
		else
			trailSprite.color = FlxColor.WHITE;

		if (overrideBlend != null) trailSprite.blend = overrideBlend;
		else if (blendsEnabled) trailSprite.blend = target.blend;
		else
			trailSprite.blend = null;

		trailSprite.velocity.set(trailVelocity[0], trailVelocity[1]);

		trailSprite.exists = true;
	}

	private function killOldest():Void
	{
		for (i in 0...members.length)
		{
			final sprite = members[i];
			if (sprite != null && sprite.exists)
			{
				sprite.kill();
				return;
			}
		}
	}

	/**
	 * Kills every trail sprite currently alive.
	 */
	public function resetTrail():Void
	{
		kill();
	}
}
