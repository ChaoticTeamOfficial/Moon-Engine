package moon.dependency;

import flixel.util.FlxColor;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;

using StringTools;

/**
 * A Sprite class with more compatibility over animated sprites.
 * With functions for centering offsets, adding offsets for animations, etc.
 */
class MoonSprite extends FlxSprite
{
	/**
	 * A map containing all the offsets for each animation in the sprite.
	 */
	public var animOffsets:Map<String, Array<Dynamic>>;

	/**
	 * Used for setting up if the sprite will center
	 * its offsets for the current animation.
	 */
	public var centerAnimations:Bool = false;

	/**
	 * An ID but it uses a string instead of an int.
	 */
	public var strID:String;

	/**
	 * An array of animation group names (e.g., "idle", "singAnims") that should override normal behavior.
	 * Animations matching these groups will play fully without interruption until finished.
	 * Assumes these animations are non-looped; looped animations may not behave as expected.
	 */
	public var overrideAnims:Array<String> = [];

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
	}

	/**
	 * Checks if the given animation name belongs to an override group.
	 * @param name The animation name to check.
	 * @return True if it's an override animation.
	 */
	private function isOverrideAnim(name:String):Bool
	{
		if (name == null) return false;
		var lowerName = name.toLowerCase();
		for (group in overrideAnims)
		{
			switch (group.toLowerCase())
			{
				case "singanims":
					if (lowerName.startsWith("sing")) return true;
				default:
					if (lowerName.startsWith(group.toLowerCase())) return true;
			}
		}
		return false;
	}

	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		// Prevent playing a new animation if the current one is an override and hasn't finished
		if (animation.curAnim != null && isOverrideAnim(animation.curAnim.name) && !animation.curAnim.finished)
		{
			return;
		}

		animation.play(animName, force, reversed, frame);

		final daOffset = animOffsets.get(animName);
		if (animOffsets.exists(animName))
			offset.set(daOffset[0], daOffset[1]);
		else
			offset.set(0, 0);

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

	override public function destroy()
	{
		super.destroy();
	}
}