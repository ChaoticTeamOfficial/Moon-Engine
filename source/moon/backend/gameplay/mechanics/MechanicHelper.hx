package moon.backend.gameplay.mechanics;

import moon.dependency.user.MoonInput.MoonKeys;

@:publicFields
/**
 * Helper utilities meant to be used FROM mechanic scripts.
 */
class MechanicHelper
{
	/**
	 * Checks whether `bind` was just pressed within `window` ms of `targetTime`.
	 * @param bind       The keybind to check.
	 * @param conductor  The conductor to read the current time from.
	 * @param targetTime The time (in ms) the press is supposed to happen at.
	 * @param window     Allowed leeway in ms, on either side of `targetTime`.
	 */
	static function isPressInWindow(bind:MoonKeys, conductor:Conductor, targetTime:Float, window:Float = 150):Bool return
		MoonInput.justPressed(bind)
		&& Math.abs(conductor.time - targetTime) <= window;

	/**
	 * Checks whether `bind` was just pressed close enough to ANY beat, within `window` ms.
	 * @param bind      The keybind to check.
	 * @param conductor The conductor to read beat/time info from.
	 * @param window    Allowed leeway in ms, on either side of the nearest beat.
	 * @param useOffset Whether the player's Note Offset should be applied.
	 */
	static function isPressOnBeat(bind:MoonKeys, conductor:Conductor, window:Float = 150, useOffset:Bool = true):Bool return
		MoonInput.justPressed(bind)
		&& Math.abs(getBeatDelta(conductor, useOffset)) <= window;

	/**
	 * Returns how far off (in ms) the CURRENT time is from the nearest beat.
	 * Negative means early, positive means late.
	 * @param conductor The conductor to read beat/time info from.
	 * @param useOffset Whether the player's Note Offset should be applied.
	 */
	static function getBeatDelta(conductor:Conductor, useOffset:Bool = true):Float
	{
		final time:Float = conductor.time - (useOffset ? (MoonSettings.callSetting('Note Offset') ?? 0) : 0);
		final nearestBeat:Float = Math.round(time / conductor.crochet) * conductor.crochet;
		return time - nearestBeat;
	}

	/**
	 * Same as `getBeatDelta`, but returns null unless `bind` was just pressed.
	 */
	static function getBeatPressDelta(bind:MoonKeys, conductor:Conductor, useOffset:Bool = true):Null<Float> return MoonInput.justPressed(
		bind
	) ? getBeatDelta(conductor, useOffset) : null;

	/**
	 * Checks whether `bind` is being HELD through a given time range (e.g. "hold to block from t1 to t2").
	 */
	static function isHeldInRange(bind:MoonKeys, conductor:Conductor, startTime:Float, endTime:Float):Bool return
		MoonInput.pressed(bind)
		&& conductor.time >= startTime
		&& conductor.time <= endTime;

	/**
	 * Quick access to whether the `Mechanics` setting is currently on.
	 */
	static inline function mechanicsEnabled():Bool return MoonSettings.callSetting('Mechanics') ?? true;
}
