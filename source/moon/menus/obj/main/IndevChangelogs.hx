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
			'A few mods are now included as optional content! Feel free to enable/disable in the mods menu.',
			'Characters and stage props now support multiple spritesheets for animations.',
			'Added a Playlist Menu! Thanks Remagets.',
			'Added a Placeholder Modifiers menu! Press TAB on Freeplay to open it. (Do note that some of them aren\'t implemented yet.)',
			'(W.I.P) Window Dance Events.',
			'Added a class for handling shaders.',
			'Added a difficulty selector for Freeplay',
			'Added a color picker for certain events on the Chart Editor.',
			'Added subtitle events.',
			'(W.I.P) Added a new volume overlay!',
			'(W.I.P) Story Mode menu.'
		],
		changes: [
			'Song data such as scores, misses and accuracy are handled separately.',
			'SongLibrary now reloads between states.',
			'Icons have their own structure on the character\'s JSON file.',
			'The chart converter is entirely different now.',
			'Moved some Paths functionalities to a new class, AssetManager.'
		],
		fixes: [
			'The healthbar now is properly centered.',
			'The healthbar icons now have their origin points on the edges so the scaling effect is similar to V-Slice.',
			'Various performance enhancements.'
		],
		removals: []
	}];

	public static function get(version:String):Null<IndevChangelog>
	{
		for (entry in list) if (entry.version == version) return entry;
		return null;
	}
}
