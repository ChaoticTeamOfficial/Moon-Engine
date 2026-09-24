package moon.utils;

import moon.game.submenus.*;
import moon.menus.*;

@:publicFields
/**
 * This class will hold utilities for scripts.
 * Basically, lets you access some stuff that aren't available for scripts but are important!
 * If there's anything missing here, feel free to contribute by either messaging me or making a pull request.
 */
class ScriptUtils
{
	// --- FlxPoint stuff. ---

	/**
	 * Creates a new FlxPoint (or reuses one from the pool).
	 */
	public static function point(x:Float = 0, y:Float = 0) return flixel.math.FlxPoint.get(x, y);

	/**
	 * Creates a FlxPoint from polar coordinates.
	 */
	public static function pointPolar(angle:Float, length:Float = 1) return flixel.math.FlxPoint.get(Math.cos(angle) * length, Math.sin(angle) * length);

	// --- Menus Stuff. --- //

	/**
	 * Opens a substate, preferring a mod script if one exists.
	 */
	public static function openMenu(name:String, ?args:Array<Dynamic>, ?parent:FlxState):Void
	{
		final target = parent ?? FlxG.state;

		if (Paths.exists('data/substates/$name.hx'))
		{
			target.openSubState(new MoonScriptedSubState(name, args));
			return;
		}

		switch (name)
		{
			case 'Freeplay':
				target.openSubState(new Freeplay(args != null && args.length > 0 ? args[0] : 'bf'));
			case 'PauseMenu':
				target.openSubState(new PauseMenu(args != null ? args[0] : null));
			case 'Gameover':
				target.openSubState(new Gameover());
			case 'AchievementsMenu':
				target.openSubState(new AchievementsMenu());
			case 'Settings':
				target.openSubState(new Settings(args != null && args.length > 0 ? args[0] : false));
			default:
				trace('[MENUS] No fallback found for "$name" and no script found!', "WARNING");
		}
	}

	/**
	 * Switches to a state, preferring a mod script if one exists.
	 */
	public static function switchTo(name:String, ?args:Array<Dynamic>):Void
	{
		if (Paths.exists('data/states/$name.hx'))
		{
			FlxG.switchState(() -> new MoonScriptedState(name, args));
			return;
		}

		switch (name)
		{
			case 'MainMenu':
				FlxG.switchState(() -> new MainMenu());
			case 'Story':
				FlxG.switchState(() -> new Story());
			case 'LoadingScreen':
				// TODO: find a way to make it so people won't need to recode the entire loading!
				FlxG.switchState(() -> new LoadingScreen());
			case 'ResultsState':
				FlxG.switchState(() -> new moon.game.ResultsState(args[0], args[1], args[2], args[3]));
			default:
				trace('[STATES] No fallback found for "$name" and no script found.', "WARNING");
		}
	}
}
