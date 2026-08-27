package moon.menus.obj.main;

typedef IndevChangelog =
{
	var version:String;
	var ?additions:Array<String>;
	var ?changes:Array<String>;
	var ?fixes:Array<String>;
	var ?removals:Array<String>;
}

class IndevChangelogs
{
	public static final list:Array<IndevChangelog> = [{
		version: Constants.INDEV_VERSION,
		additions: [
			"A bunch of new songs got ported from V-Slice, with some flaws, make sure to report them.",
			"Freeplay now has categories.",
			"Health Icons now can be animated.",
			"Characters now can have multiple atlases.",
			"Characters have one new extra field: extendIdleDuration",
			"A Mechanics system, which is tied with the settings.",
			"An entirely new UI system that's still in development, made by Toffee!",
			"An accuracy bar, which shows how well you're playing.",
			"Tint Character event.",
			"Set Filter events.",
			"Camera Flash and Fade events.",
			"Support for legacy vocal files (Inst and Voices only).",
			"Auto Pause Setting.",
			"If you hold a key after singing, the playable character will hold their animation as well. (You're welcome, Sammy.)",
			"Archipelago implementation. (Still heavily W.I.P. If you want to test it out, DM me and I'll send you the apworld.)",
			"Stage props now have an ID field, so you can have multiple objects on the same image.",
			"A revamp of the pause menu. (W.I.P)",
			"Characters now have an optional \"isPlayer\" field, which allows it to flip properly when changing whether they're an opponent or not.",
			"Achievements are fully implemented, week completion ones are also softcoded."
		],
		changes: [
			"Flixel's Version got bumped up to 6.2.0.",
			"Events now can be executed as soon as PlayState loads!",
			"The entire Chart reading got changed.",
			"Vocal files are hyphen consistent. (e.g. Voices-opponent-erect)",
			"Sammy did some lovely character offsets."
		],
		fixes: [
			"Files from mods now save properly.",
			"Sustain combos are more consistent now.",
			"Stage Prop scaling should behave just like they do in v-slice now.",
			"Stage camera offsets now combine with the characters camera offsets instead of overriding them.",
			"Songs are organized properly on both freeplay and story mode.",
			"The Freeplay P counter now takes P Golds as regular P ranks as well."
		],
		removals: []
	}];

	public static function get(version:String):Null<IndevChangelog>
	{
		for (entry in list) if (entry.version == version) return entry;
		return null;
	}
}
