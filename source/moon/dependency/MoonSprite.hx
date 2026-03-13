package moon.dependency;

import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.io.Path;
import animate.FlxAnimateFrames.FlxAnimateSettings;
import animate.FlxAnimate;
import animate.FlxAnimateFrames;
import animate.internal.*;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;

using StringTools;

/**
 * A Sprite class with more compatibility over animated sprites.
 * With functions for centering offsets, adding offsets for animations, etc.
 */
class MoonSprite extends FlxAnimate
{
	/**
	 * A map containing all the offsets for each animation in the sprite.
	 */
	public var animOffsets:Map<String, Array<Dynamic>> = [];

	/**
	 * Used for setting up if the sprite will center
	 * its offsets for the current animation.
	 */
	public var centerAnimations:Bool = false;

	/**
	 * An ID but it uses a string instead of an int.
	 */
	public var strID:String = '';

	/**
	 * A brightness field that looks just like Adobe Animate's brightness.
	 */
	public var brightness(default, set):Float = 0;
	
	/**
	 * The suffix used for animations.
	 * Let's say you have an "`idle`" animation, then, you set the suffix to "`alt`".
	 * Then, the sprite will attempt to play "idle-alt".
	 * If there's no animation with the suffix, it'll try to play the animation without the suffix.
	 */
	public var animationSuffix:String = "";

	/**
	 * An array of animation group names (e.g., "idle", "singAnims") that should override normal behavior.
	 * Animations matching these groups will play fully without interruption until finished.
	 * Assumes these animations are non-looped; looped animations may not behave as expected.
	 */
	public var overrideAnims:Array<String> = [];

	public var extraOffset:FlxPoint = FlxPoint.get();

	public var idleAnims:Array<String> = null;
	public var danceIndex:Int = 0;
	public var lastDanceBeat:Int = -1;

	public var twn:FlxTween;

	/**
	 * Checks if the given animation name belongs to an override group.
	 * @param name The animation name to check.
	 * @return True if it's an override animation.
	 */
	private function isOverrideAnim(name:String):Bool
	{
		if (name == null) return false;
		final lowerName = name.toLowerCase();
		for (group in overrideAnims)
		{
			switch (group.toLowerCase())
			{
				case "singanims": return lowerName.startsWith("sing");
				default: return lowerName.startsWith(group.toLowerCase());
			}
		}
		return false;
	}

	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		// Prevent playing a new animation if the current one is an override and hasn't finished
		if (animation.curAnim != null && isOverrideAnim(animation.curAnim.name) && !animation.curAnim.finished)
			return;

		doAnimThingy(animName, force, reversed, frame);
	}

	/**
	 * Forcefully plays an animation, interrupting and stopping any current animation
	 * (including overrides) to ensure the new one starts immediately.
	 * @param animName The name of the animation to play.
	 * @param force Whether to force-restart the animation if it's already playing (defaults to true for forceful behavior).
	 * @param reversed Whether to play the animation in reverse.
	 * @param frame The frame to start the animation from.
	 */
	public function forcePlayAnim(animName:String, force:Bool = true, reversed:Bool = false, frame:Int = 0):Void
		doAnimThingy(animName, force, reversed, frame);

	private function doAnimThingy(animName:String, force:Bool, reversed:Bool, frame:Int)
	{
		var playName:String = animName;
		if (animationSuffix != "" && animation.exists('$animName-$animationSuffix'))
			playName = '$animName-$animationSuffix';

		if(!animation.exists(playName))
		{
			trace('Tried to play animation $playName, but it doesn\'t exist!', "WARNING");
			return;
		}

		animation.play(playName, force, reversed, frame);

		var offsetKey:String = playName;
		if (!animOffsets.exists(offsetKey))
			offsetKey = animName;

		final daOffset = animOffsets.get(offsetKey);
		(animOffsets.exists(offsetKey)) ? offset.set(daOffset[0], daOffset[1]) : offset.set(0, 0);

		if (centerAnimations)
		{
			centerOffsets();
        	centerOrigin();
		}
	}

	@:inheritDoc(FlxSprite.loadGraphic)
	override public function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):MoonSprite
		return cast super.loadGraphic(graphic, animated, frameWidth, frameHeight, unique, key);

	@:inheritDoc(FlxSprite.makeGraphic)
	override public function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):MoonSprite
		return cast super.makeGraphic(width, height, color, unique, key);

	/**
	 * Adds an offset to a animation. (IMPORTANT NOTE: For offsets to apply, use `playAnim()` instead of `animation.play()`.)
	 * @param name The animation's name.
	 * @param x    The X offset.
	 * @param y    The Y offset.
	 */
	public function addOffset(name:String, x:Float = 0, y:Float = 0)
		animOffsets[name] = [x, y];

	/**
	 * Automatically adds animations and offsets using an array of AnimationData. 
	 * @param animations Array of AnimationDatas.
	 * return array of idle anims, for chaining them.
	 */
	public function loadAnimations(animations:Array<Paths.AnimationData>):Array<String>
	{
		var idleAnims:Array<String> = [];
		for (i in 0...animations.length)
		{
			final anim:Paths.AnimationData = animations[i];
			(anim.indices != null)
			? this.animation.addByIndices(anim.name, anim.prefix, anim.indices, '', anim.fps ?? 24, anim.looped ?? false)
			: this.animation.addByPrefix(anim.name, anim.prefix, anim.fps ?? 24, anim.looped ?? false);
			this.addOffset(anim.name, anim?.x ?? 0, anim?.y ?? 0);
			//trace('added ' + animations);

			if(anim.name.startsWith("idle-"))
				idleAnims.push(anim.name);

			if(anim.finishAnim != null)
				animation.onFinish.add((animName) -> {
					if(animation.curAnim != null && animation.curAnim.name == animations[i].name)
						playAnim(animations[i].finishAnim, true); //compiler being ass moment
				});
		}
		return idleAnims;
	}

	public function dance(?force:Bool = false)
    {
        if (idleAnims != null && idleAnims.length > 0)
        {
            playAnim(idleAnims[danceIndex], force);
            danceIndex = (danceIndex + 1) % idleAnims.length;
        }
        else
        {
            if(animation.exists("idle-0"))
            {
                playAnim("idle-0", force);
                danceIndex = 0;
            }
        }
    }

    @:noCompletion public function set_brightness(value:Float):Float
    {
        this.brightness = value;
        
        FlxSpriteUtil.setBrightness(this, value);
        
        return value;
    }

	override public function destroy():Void
	{
		extraOffset = FlxDestroyUtil.put(extraOffset);

		super.destroy();
	}
}