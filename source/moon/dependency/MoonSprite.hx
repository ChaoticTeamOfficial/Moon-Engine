package moon.dependency;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;

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

	public function new(x:Float = 0, y:Float = 0)
	{
		super(x, y);

		animOffsets = new Map<String, Array<Dynamic>>();
	}

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
		
	// ---- SKEW STUFF ---- //

    /**
     * @author Zaphod
     */
    public var skew(default, null):FlxPoint = FlxPoint.get();

    /**
     * Tranformation matrix for this sprite.
     * Used only when matrixExposed is set to true
     */
    public var transformMatrix(default, null):FlxMatrix = new FlxMatrix();

    /**
     * Bool flag showing whether transformMatrix is used for rendering or not.
     * False by default, which means that transformMatrix isn't used for rendering
     */
    public var matrixExposed:Bool = false;

    /**
     * Internal helper matrix object. Used for rendering calculations when matrixExposed is set to false
     */
    var _skewMatrix:FlxMatrix = new FlxMatrix();

    override public function destroy():Void
    {
        skew = FlxDestroyUtil.put(skew);
        _skewMatrix = null;
        transformMatrix = null;

        super.destroy();
    }

    override function drawComplex(camera:FlxCamera):Void
    {
        _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
        _matrix.translate(-origin.x, -origin.y);
        _matrix.scale(scale.x, scale.y);

        if (matrixExposed)
            _matrix.concat(transformMatrix);
        else
        {
            if (bakedRotationAngle <= 0)
            {
                updateTrig();

                if (angle != 0)
                    _matrix.rotateWithTrig(_cosAngle, _sinAngle);
            }

            updateSkewMatrix();
            _matrix.concat(_skewMatrix);
        }

        getScreenPosition(_point, camera).subtractPoint(offset);
        _point.addPoint(origin);

        if (isPixelPerfectRender(camera))
            _point.floor();

        _matrix.translate(_point.x, _point.y);

        camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
    }

    function updateSkewMatrix():Void
    {
        _skewMatrix.identity();

        if (skew.x != 0 || skew.y != 0)
        {
            _skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
            _skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
        }
    }

    override public function isSimpleRender(?camera:FlxCamera):Bool
    {
        if (FlxG.renderBlit)
            return super.isSimpleRender(camera) && (skew.x == 0) && (skew.y == 0) && !matrixExposed;
        else
            return false;
    }
}