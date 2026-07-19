package moon.backend.gameplay.modifiers;

/**
 * String constants for every modifier id
 */
enum abstract ModifierIds(String) from String to String
{
	// accuracy
	var STRICT_TIMING = "strict_timing";
	var SICK_ONLY = "sick_only";
	// speed
	var PLAYBACK_RATE = "playback_rate";
	var SCROLL_SPEED_MULT = "scroll_speed_mult";
	var WAVE_SPEED = "wave_speed";
	// note behavior
	var MIRROR = "mirror";
	var SHUFFLE = "shuffle";
	// visibility
	var FOG = "fog";
	var DRUNK = "drunk";
	var TIPSY = "tipsy";
	// health
	var ONE_LIFE = "one_life";
	var POISON = "poison";
	var NO_HEALING = "no_healing";
	var GLASS_CANNON = "glass_cannon";
}

/**
 * Builds every Modifier instance and registers it with ModifierManager.
 */
class Modifiers
{
	public static function registerAll():Void
	{
		var strictTiming = new Modifier(ModifierIds.STRICT_TIMING, "Strict Timing", "Shrinks timing windows.", ACCURACY);
		ModifierManager.register(strictTiming);

		var sickOnly = new Modifier(ModifierIds.SICK_ONLY, "Sick Only", "Anything below the highest judgment is a miss.", ACCURACY);
		ModifierManager.register(sickOnly);

		var playbackRate = new Modifier(ModifierIds.PLAYBACK_RATE, "Playback Rate", "Play the song faster or slower.", SPEED, RANGE);
		playbackRate.minValue = 0.5;
		playbackRate.maxValue = 2.0;
		playbackRate.defaultValue = 1.0;
		playbackRate.value = 1.0;
		ModifierManager.register(playbackRate);

		var scrollSpeedMult = new Modifier(
			ModifierIds.SCROLL_SPEED_MULT,
			"Scroll Speed Multiplier",
			"Change how much the chart's scroll speed is multiplied.",
			SPEED,
			RANGE,
			[ModifierIds.WAVE_SPEED]
		);
		scrollSpeedMult.minValue = 0.2;
		scrollSpeedMult.maxValue = 5.0;
		scrollSpeedMult.defaultValue = 1.0;
		scrollSpeedMult.value = 1.0;
		ModifierManager.register(scrollSpeedMult);
		scrollSpeedMult.onActivate = () -> Global.scrollSpeedMult = scrollSpeedMult.value;
		scrollSpeedMult.onValueChanged = (newValue) -> Global.scrollSpeedMult = newValue;

		var waveSpeed = new Modifier(
			ModifierIds.WAVE_SPEED,
			"Wave Speed",
			"Scroll speed constantly oscillates.",
			SPEED,
			TOGGLE,
			[ModifierIds.SCROLL_SPEED_MULT]
		);
		ModifierManager.register(waveSpeed);

		// NOTE BEHAVIOR

		var mirror = new Modifier(ModifierIds.MIRROR, "Mirror", "Flips the notes directions.", NOTE_BEHAVIOR, TOGGLE, [ModifierIds.SHUFFLE]);
		ModifierManager.register(mirror);

		var shuffle = new Modifier(ModifierIds.SHUFFLE, "Shuffle", "Randomizes lane mapping once per song.", NOTE_BEHAVIOR, TOGGLE, [ModifierIds.MIRROR]);
		ModifierManager.register(shuffle);

		// VISIBILITY

		var fog = new Modifier(ModifierIds.FOG, "Fog", "Notes fade based on distance.", VISIBILITY);
		ModifierManager.register(fog);

		// TODO
		/*var tipsy = new Modifier(ModifierIds.TIPSY, "Tipsy", "Lanes wobble just a little.", VISIBILITY, TOGGLE, [ModifierIds.DRUNK]);
			ModifierManager.register(tipsy);

			var drunk = new Modifier(ModifierIds.DRUNK, "Drunk", "Lanes wiggle around intensely.", VISIBILITY, TOGGLE, [ModifierIds.TIPSY]);
			ModifierManager.register(drunk);
		 */

		// HEALTH

		var oneLife = new Modifier(ModifierIds.ONE_LIFE, "One Life", "A single miss instantly fails the song.", HEALTH, TOGGLE, [ModifierIds.GLASS_CANNON]);
		ModifierManager.register(oneLife);

		var poison = new Modifier(ModifierIds.POISON, "Poison", "Health constantly drains over time.", HEALTH);
		ModifierManager.register(poison);

		var noHealing = new Modifier(ModifierIds.NO_HEALING, "No Healing", "Hits no longer restore HP.", HEALTH);
		ModifierManager.register(noHealing);

		var glassCannon = new Modifier(
			ModifierIds.GLASS_CANNON,
			"Glass Cannon",
			"Huge healing on hit, huge damage on miss.",
			HEALTH,
			TOGGLE,
			[ModifierIds.ONE_LIFE]
		);
		ModifierManager.register(glassCannon);
	}
}
