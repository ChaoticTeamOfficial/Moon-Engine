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
			"Freeplay now has categories.",
			"Health Icons now can be animated.",
			"Characters now can have multiple atlases.",
			"Characters have one new extra field: extendIdleDuration",
			"A Mechanics system, which is tied with the settings.",
			"An entirely new UI system that's still in development, made by Toffee!"
		],
		changes: ["Flixel's Version got bumped up to 6.2.0."],
		fixes: [
			"Files from mods now save properly.",
			"Sustain combos are more consistent now."
		],
		removals: []
	}];

	public static function get(version:String):Null<IndevChangelog>
	{
		for (entry in list) if (entry.version == version) return entry;
		return null;
	}
}
