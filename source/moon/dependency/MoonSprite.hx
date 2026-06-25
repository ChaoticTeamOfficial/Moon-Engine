package moon.dependency;

import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.io.Path;
import animate.*;
import animate.internal.*;
import flixel.util.FlxDestroyUtil;
import flixel.util.FlxSpriteUtil;
import flixel.tweens.FlxTween;
import moon.backend.Paths;
import moon.backend.Paths.AtlasType;

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
	 * Stores the raw `Paths.AnimationData` used to register each animation on
	 * this sprite, keyed by animation name. Populated automatically by
	 * `AnimationUtils` (`addAtlasAnimation` / `addTextureAtlasAnimation` /
	 * `loadAnimations`) whenever an animation gets added through it, so you
	 * can look up an animation's original prefix, indices, frame rate, etc.
	 * later without keeping a separate array around.
	 */
	public var animDataMap:Map<String, Paths.AnimationData> = new Map();

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

	/**
	 * Map of idle animations grouped by their suffix.
	 * Key `""` holds the base idle anims (e.g. `["idle-0", "idle-1"]`).
	 * Key `"alt"` holds the suffixed variants (e.g. `["idle-0-alt", "idle-1-alt"]`).
	 * And so goes on for every suffix.
	 * `dance()` will use the group matching `animationSuffix`, falling back to `""`.
	 */
	public var idleAnimsMap:Map<String, Array<String>> = new Map();

	/**
	 * Convenience getter/setter for the base idle animations (`idleAnimsMap.get("")`).
	 * Setting this directly replaces the base group.
	 */
	public var idleAnims(get, set):Array<String>;

	public var danceIndex:Int = 0;
	public var lastDanceBeat:Int = -1;
	public var danceFrequency:Int = 2;
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
				case "singanims":
					return lowerName.startsWith("sing");
				default:
					return lowerName.startsWith(group.toLowerCase());
			}
		}
		return false;
	}

	@:inheritDoc(flixel.animation.FlxAnimationController.play)
	public function playAnim(animName:String, force:Bool = false, reversed:Bool = false, frame:Int = 0):Void
	{
		// Prevent playing a new animation if the current one is an override and hasn't finished
		if (animation.curAnim != null && isOverrideAnim(animation.curAnim.name) && !animation.curAnim.finished) return;

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
	public function forcePlayAnim(animName:String, force:Bool = true, reversed:Bool = false, frame:Int = 0):Void doAnimThingy(
		animName,
		force,
		reversed,
		frame
	);

	private function doAnimThingy(animName:String, force:Bool, reversed:Bool, frame:Int)
	{
		var playName:String = animName;
		if (animationSuffix != "" && animation.exists('$animName-$animationSuffix')) playName = '$animName-$animationSuffix';

		if (!animation.exists(playName))
		{
			// trace('Tried to play animation $playName, but it doesn\'t exist!', "WARNING");
			return;
		}

		animation.play(playName, force, reversed, frame);

		var offsetKey:String = playName;
		if (!animOffsets.exists(offsetKey)) offsetKey = animName;

		final daOffset = animOffsets.get(offsetKey);
		(animOffsets.exists(offsetKey)) ? offset.set(daOffset[0], daOffset[1]) : offset.set(0, 0);

		if (centerAnimations)
		{
			centerOffsets();
			centerOrigin();
		}

		offset.x += extraOffset.x;
		offset.y += extraOffset.y;
	}

	@:inheritDoc(FlxSprite.loadGraphic)
	override public function loadGraphic(graphic:FlxGraphicAsset, animated:Bool = false, frameWidth:Int = 0, frameHeight:Int = 0, unique:Bool = false, ?key:String):MoonSprite
		return cast super.loadGraphic(
		graphic,
		animated,
		frameWidth,
		frameHeight,
		unique,
		key
	);

	@:inheritDoc(FlxSprite.makeGraphic)
	override public function makeGraphic(width:Int, height:Int, color:FlxColor = FlxColor.WHITE, unique:Bool = false, ?key:String):MoonSprite
		return cast super.makeGraphic(
		width,
		height,
		color,
		unique,
		key
	);

	/**
	 * Adds an offset to a animation. (IMPORTANT NOTE: For offsets to apply, use `playAnim()` instead of `animation.play()`.)
	 * @param name The animation's name.
	 * @param x    The X offset.
	 * @param y    The Y offset.
	 */
	public function addOffset(name:String, x:Float = 0, y:Float = 0) animOffsets[name] = [x, y];

	/**
	 * Automatically adds animations and offsets using an array of AnimationData.
	 * Delegates the actual frame-registration/offset/idle-grouping work to `AnimationUtils.loadAnimations`.
	 * @param animations Array of AnimationDatas.
	 * @param type       Which atlas/spritesheet format these animations come from.
	 * return array of idle anims, for chaining them.
	 */
	public function loadAnimations(animations:Array<Paths.AnimationData>, type:AtlasType = SPARROW):Array<String> return AnimationUtils.loadAnimations(
		this,
		animations,
		type
	);

	/**
	 * Convenience lookup into `animDataMap`.
	 */
	public function getAnimData(name:String):Paths.AnimationData return animDataMap.exists(name) ? animDataMap.get(name) : null;

	public function dance(?force:Bool = false)
	{
		final group = idleAnimsMap.exists(animationSuffix) ? idleAnimsMap.get(animationSuffix) : (idleAnimsMap.exists("") ? idleAnimsMap.get("") : []);

		if (group != null && group.length > 0)
		{
			playAnim(group[danceIndex], force);
			danceIndex = (danceIndex + 1) % group.length;
		}
		else if (animation.exists("idle-0"))
		{
			playAnim("idle-0", force);
			danceIndex = 0;
		}
	}

	/**
	 * Sets the visibility of one or more named layers, by default on this
	 * sprite's currently-playing root symbol timeline. Note that it only works if this sprite is loaded with an
	 * Animate Atlas!
	 * @param names    Layer names to toggle (case-sensitive, matches the names from Adobe Animate!)
	 * @param visible  Whether the named layers should be visible.
	 * @param timeline Optional explicit timeline to search instead of the root symbol's.
	 */
	public function setLayersVisible(names:Array<String>, visible:Bool, ?timeline:Timeline):Void
	{
		final tl = timeline ?? getRootTimeline();
		if (tl == null)
		{
			trace('[MoonSprite] Could not resolve a timeline to set layer visibility on!', "WARNING");
			return;
		}

		var matched = 0;
		tl.forEachLayer(layer ->
		{
			trace('[MoonSprite] layer: "${layer.name}" (visible=${layer.visible})', "DEBUG");
			if (names.contains(layer.name))
			{
				layer.visible = visible;
				matched++;
			}
		});
		trace('[MoonSprite] setLayersVisible: matched $matched / ${names.length}', "DEBUG");
	}

	/**
	 * Returns a named layer from a timeline (the root symbol's by default), or
	 * `null` if it doesn't exist. Only works if the sprite is loaded with an Animate Atlas.
	 */
	public function getLayer(name:String, ?timeline:Timeline):Layer
	{
		final tl = timeline ?? getRootTimeline();
		if (tl == null) return null;

		var found:Layer = null;
		tl.forEachLayer(layer ->
		{
			if (layer.name == name) found = layer;
		});
		return found;
	}

	private function getRootTimeline():Timeline
	{
		final controller:FlxAnimateController = cast this.animation;
		@:privateAccess if (!controller.hasAnimateAtlas) return null;
		@:privateAccess if (controller.isAnimate)
		{
			final curAnim = cast controller.curAnim;
			if (curAnim != null && curAnim.timeline != null) return curAnim.timeline;
		}

		return controller.getDefaultTimeline();
	}

	@:noCompletion
	public function set_brightness(value:Float):Float
	{
		this.brightness = value;

		FlxSpriteUtil.setBrightness(this, value);

		return value;
	}

	private function get_idleAnims():Array<String> return idleAnimsMap.exists("") ? idleAnimsMap.get("") : [];

	private function set_idleAnims(value:Array<String>):Array<String>
	{
		idleAnimsMap.set("", value != null ? value : []);
		return value;
	}

	override public function destroy():Void
	{
		extraOffset = FlxDestroyUtil.put(extraOffset);

		super.destroy();
	}
}
