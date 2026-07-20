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
		additions: [],
		changes: [],
		fixes: [],
		removals: []
	}];

	public static function get(version:String):Null<IndevChangelog>
	{
		for (entry in list) if (entry.version == version) return entry;
		return null;
	}
}
