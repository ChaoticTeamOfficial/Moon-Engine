package moon.utils;

import flixel.tweens.FlxTween;
import openfl.display.Window;
import openfl.system.Capabilities;
import openfl.geom.Rectangle;

@:publicFields
enum abstract MonitorAxes(String)
{
	var CENTER = 'Center';
	var CORNER = 'Corner';
}

enum abstract WindowAxes(String)
{
	var TOP_LEFT = 'Top Left';
	var TOP_CENTER = 'Top Center';
	var TOP_RIGHT = 'Top Right';
	var MID_LEFT = 'Middle Left';
	var CENTER = 'Center';
	var MID_RIGHT = 'Middle Right';
	var BOTTOM_LEFT = 'Bottom Left';
	var BOTTOM_CENTER = 'Bottom Center';
	var BOTTOM_RIGHT = 'Bottom Right';
}

/**
 * A class for exclusively handling window stuff, like moving, resizing, opacity, and more!
 * Note: Window manipulation is primarily designed for Desktop targets (Windows, Mac, Linux).
 */
class WindowUtils
{
	/**
	 * Quick accessor for the current window.
	 */
	public static inline function getWindow() return FlxG.stage.window;

	/**
	 * Quick accessor for current screen resolution as a Rectangle.
	 */
	public static inline function getScreenBounds():Rectangle return new Rectangle(0, 0, Capabilities.screenResolutionX, Capabilities.screenResolutionY);

	/**
	 * Returns the current window position and size as a Rectangle.
	 */
	public static function getWindowRect():Rectangle
	{
		final win = getWindow();
		return new Rectangle(win.x, win.y, win.width, win.height);
	}

	public static var moveTwn:FlxTween;

	/**
	 * Moves the window to a position, which can have different results depending on axes.
	 * @param x             X Position
	 * @param y             Y Position
	 * @param monitorAxes   Which axes will the movement be based on your monitor.
	 * @param windowAxes    Which point of the window will sit at the calculated monitor position.
	 * @param duration      The duration of the tween.
	 * @param options       The tween's options.
	 */
	public static function moveTo(x:Float, y:Float, monitorAxes:MonitorAxes, windowAxes:WindowAxes, ?duration:Null<Float>, ?options:Null<TweenOptions>)
	{
		TweenUtils.cancelTwn(moveTwn);

		final isInstant = (duration ?? 0) <= 0;
		var targetX:Float = x;
		var targetY:Float = y;
		final screen = getScreenBounds();
		final win = getWindow();

		if (monitorAxes == CENTER)
		{
			targetX += screen.width / 2;
			targetY += screen.height / 2;
		}

		switch (windowAxes)
		{
			case TOP_LEFT: // unchanged!
			case TOP_CENTER:
				targetX -= win.width / 2;
			case TOP_RIGHT:
				targetX -= win.width;
			case MID_LEFT:
				targetY -= win.height / 2;
			case CENTER:
				targetX -= win.width / 2;
				targetY -= win.height / 2;
			case MID_RIGHT:
				targetX -= win.width;
				targetY -= win.height / 2;
			case BOTTOM_LEFT:
				targetY -= win.height;
			case BOTTOM_CENTER:
				targetX -= win.width / 2;
				targetY -= win.height;
			case BOTTOM_RIGHT:
				targetX -= win.width;
				targetY -= win.height;
		}

		final snapX:Int = Std.int(targetX);
		final snapY:Int = Std.int(targetY);

		if (isInstant)
		{
			win.x = snapX;
			win.y = snapY;
		}
		else
			moveTwn = FlxTween.tween(win, {
				x: snapX,
				y: snapY
			}, duration, options);
	}

	/**
	 * Instantly snaps the window to the exact center of the monitor.
	 */
	public static function centerWindow()
	{
		final win = getWindow();
		final screen = getScreenBounds();
		win.x = Std.int((screen.width - win.width) / 2);
		win.y = Std.int((screen.height - win.height) / 2);
	}

	/**
	 * Prevents the window from going off-screen.
	 * Ensures at least 100 px of the window is always visible.
	 */
	public static function clampToScreen()
	{
		// TODO: make sure this works properly?
		final win = getWindow();
		final screen = getScreenBounds();
		win.x = Std.int(Math.max(-win.width + 100, Math.min(screen.width - 100, win.x)));
		win.y = Std.int(Math.max(-win.height + 100, Math.min(screen.height - 100, win.y)));
	}

	public static var fadeTwn:FlxTween;

	/**
	 * Changes the window opacity.
	 * @param opacity   Value between 0.0 and 1.0.
	 * @param duration  Tween duration.
	 * @param options   Tween options.
	 */
	public static function fadeWindow(opacity:Float, ?duration:Null<Float>, ?options:Null<TweenOptions>)
	{
		TweenUtils.cancelTwn(fadeTwn);
		opacity = Math.max(0, Math.min(1, opacity));
		final isInstant = (duration ?? 0) <= 0;
		final win = getWindow();

		if (isInstant) win.opacity = opacity;
		else
			fadeTwn = FlxTween.num(win.opacity, opacity, duration, options, (v) -> win.opacity = v);
	}

	public static var resizeTwn:FlxTween;

	/**
	 * Resizes the window.
	 * @param width     Target width.
	 * @param height    Target height.
	 * @param duration  Tween duration (0 or null = instant).
	 * @param options   Tween options.
	 * @param anchor    Which corner / edge of the window stays in place.
	 */
	public static function resizeTo(width:Float, height:Float, ?duration:Null<Float>, ?options:Null<TweenOptions>, ?anchor:WindowAxes)
	{
		// TODO: separate resizing in two functions, in which one would be "scale" based rather than width/height
		TweenUtils.cancelTwn(resizeTwn);

		final isInstant = (duration ?? 0) <= 0;
		final win = getWindow();

		width = Math.max(win.minWidth, Math.min(win.maxWidth > 0 ? win.maxWidth : width, width));
		height = Math.max(win.minHeight, Math.min(win.maxHeight > 0 ? win.maxHeight : height, height));

		final dw = width - win.width;
		final dh = height - win.height;

		var dx:Float = 0;
		var dy:Float = 0;

		switch (anchor ?? TOP_LEFT)
		{
			case TOP_LEFT: // unchanged!
			case TOP_CENTER:
				dx = -dw / 2;
			case TOP_RIGHT:
				dx = -dw;
			case MID_LEFT:
				dy = -dh / 2;
			case CENTER:
				dx = -dw / 2;
				dy = -dh / 2;
			case MID_RIGHT:
				dx = -dw;
				dy = -dh / 2;
			case BOTTOM_LEFT:
				dy = -dh;
			case BOTTOM_CENTER:
				dx = -dw / 2;
				dy = -dh;
			case BOTTOM_RIGHT:
				dx = -dw;
				dy = -dh;
		}

		final targetX = win.x + dx;
		final targetY = win.y + dy;

		if (isInstant)
		{
			win.width = Std.int(width);
			win.height = Std.int(height);
			win.x = Std.int(targetX);
			win.y = Std.int(targetY);
		}
		else
			resizeTwn = FlxTween.tween(win, {
				width: width,
				height: height,
				x: targetX,
				y: targetY
			}, duration, options);
	}

	public static var shakeTwn:FlxTween;

	/**
	 * Shakes the window with a dampened sine-wave oscillation.
	 *
	 * @param intensity  Max pixel offset at the start of the shake.
	 * @param duration   How long the shake lasts in seconds.
	 * @param frequency  Number of full oscillations over the duration.
	 * @param options    Tween options (e.g. onComplete callback).
	 */
	public static function shake(intensity:Float = 12, duration:Float = 0.5, frequency:Float = 14, ?options:Null<TweenOptions>)
	{
		TweenUtils.cancelTwn(shakeTwn);

		final win = getWindow();
		final origX = win.x;
		final origY = win.y;

		shakeTwn = FlxTween.num(0, 1, duration, options, (progress:Float) ->
		{
			final decay = 1.0 - progress;
			final angle = progress * Math.PI * 2.0 * frequency;
			win.x = Std.int(origX + Math.sin(angle) * intensity * decay);
			win.y = Std.int(origY + Math.sin(angle * 1.37) * intensity * decay * 0.6);
		});
	}

	/**
	 * Sets the window fullscreen state.
	 * @param value  True to enter fullscreen, false to exit.
	 */
	public static function setFullscreen(value:Bool)
	{
		#if (desktop && !html5)
		getWindow().fullscreen = value;
		#end
	}

	/**
	 * Toggles between fullscreen and windowed mode.
	 */
	public static function toggleFullscreen()
	{
		#if (desktop && !html5)
		final win = getWindow();
		win.fullscreen = !win.fullscreen;
		#end
	}

	/**
	 * Minimizes the window to the taskbar / dock.
	 */
	public static function minimize()
	{
		#if (desktop && !html5)
		getWindow().minimized = true;
		#end
	}

	/**
	 * Attempts to maximize the window to fill the screen.
	 */
	public static function maximize()
	{
		#if (desktop && !html5)
		getWindow().maximized = true;
		#end
	}

	/**
	 * Restores the window from a minimized or maximized state back to its
	 * normal windowed size and position.
	 */
	public static function restoreWindow()
	{
		#if (desktop && !html5)
		final win = getWindow();
		win.minimized = false;
		win.maximized = false;
		win.fullscreen = false;
		#end
	}

	/**
	 * Brings the window to the foreground and gives it input focus.
	 */
	public static function focusWindow()
	{
		#if (desktop && !html5)
		getWindow().focus();
		#end
	}

	/**
	 * Changes the window title.
	 * @param title The new title text.
	 */
	public static function setTitle(title:String) getWindow().title = title;

	/**
	 * Toggles or sets window borders.
	 * @param value True for borderless, false for normal window.
	 */
	public static function setBorderless(value:Bool) getWindow().borderless = value;

	/**
	 * Allows or prevents the user from resizing the window by dragging its edges.
	 * @param value True to allow resizing.
	 */
	public static function setResizable(value:Bool) getWindow().resizable = value;

	/**
	 * Sets the minimum allowed size for the window.
	 * Immediately clamps the window if it is currently smaller.
	 * @param width  Minimum width.
	 * @param height Minimum height.
	 */
	public static function setMinSize(width:Int, height:Int)
	{
		final win = getWindow();
		win.minWidth = width;
		win.minHeight = height;
		if (win.width < width) win.width = width;
		if (win.height < height) win.height = height;
	}

	/**
	 * Sets the maximum allowed size for the window.
	 * @param width   Maximum width  (0 or -1 = unlimited).
	 * @param height  Maximum height (0 or -1 = unlimited).
	 */
	public static function setMaxSize(width:Int, height:Int)
	{
		getWindow().maxWidth = width;
		getWindow().maxHeight = height;
	}
}
