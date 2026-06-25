package moon.dependency.user;

/**
 * A typedef that contains all data used in achievements.
 */
typedef AchievementData =
{
	/**
	 * The achievement's ID. Used mostly for unlocking it.
	 */
	var id:String;

	/**
	 * The achievement's display name. 
	 * The name that'll show when unlocking it or when looking at it on the achievements menu.
	 */
	var name:String;

	/**
	 * The achievement's description.
	 * It'll be displayed when selecting it on the achievements menu if visible.
	 */
	var description:String;

	/**
	 * The category in which this achievement will be stored at.
	 */
	var category:String;

	/**
	 * Whether this achievement should be hidden when locked or not.
	 */
	var ?secret:Bool;

	/**
	 * Whether this achievement should hide the name on the achievements menu when locked or not.
	 */
	var ?hideName:Bool;

	/**
	 * Whether this achievement should hide the description on the achievements menu when locked or not.
	 */
	var ?hideDesc:Bool;
}

@:publicFields
/**
 * The class that stores everything related to achievements.
 */
class MoonAchievements
{
	/**
	 * A map that holds all the achievements.
	 * You can get one by using an achievement ID.
	 */
	static var all(default, null):Map<String, AchievementData> = [];

	/**
	 * A map that holds all the unlocked achievements.
	 */
	static var unlocked(default, null):Map<String, Bool> = [];

	/**
	 * An array that holds all the categories.
	 */
	static var categories(default, null):Array<String> = [];

	@:dox(hide)
	static var save:FlxSave;

	@:dox(hide)
	static function init():Void
	{
		// aighttt lets initialize this
		save = new FlxSave();
		save.bind(Constants.ACHIEVEMENTS_SAVE_BIND);

		if (save.data?.unlocked != null) unlocked = cast save.data.unlocked;
		else
			unlocked = [];

		loadAchievements();

		// trace(all);
	}

	private static function loadAchievements():Void
	{
		all.clear();
		categories = [];

		// just acts as a failsafe incase a dumbass deletes it all
		// just kidding nobody's a dumbass <3<3<3
		if (!Paths.exists('achievements')) return;

		// let's register the categories and the achievements.
		for (file in Paths.readDir('achievements', ['.json'], true))
		{
			final data:AchievementData = Paths.JSON('achievements/$file');

			// mannn wheres my ??=
			data.secret = data?.secret ?? false;
			data.hideName = data?.hideName ?? false;
			data.hideDesc = data?.hideDesc ?? false;

			all.set(data.id, data);

			if (!categories.contains(data.category)) categories.push(data.category);
		}

		categories.sort((a, b) -> a < b ? -1 : 1);
		trace('[ACHIEVEMENTS] All achievements loaded successfully.');
	}

	/**
	 * Unlocks an achievement if locked.
	 * @param id The achievement's ID.
	 */
	static function unlock(id:String):Void
	{
		// no need to unlock if already unlocked, duhh!!
		if (!all.exists(id) || isUnlocked(id)) return;

		unlocked.set(id, true);

		save.data.unlocked = unlocked;
		save.flush();

		// TODO: make a popup ingame? :eyes:
		trace('[ACHIEVEMENTS] Unlocked an achievement: ${all.get(id).name}');
	}

	/**
	 * Returns whether an achievement is unlocked or not.
	 * @param id The achievement's ID.
	 */
	static function isUnlocked(id:String):Bool return unlocked.exists(id) && unlocked.get(id);

	/**
	 * Returns an array that contains all achievements in a category.
	 * @param category The category it'll search for.
	 */
	static function getByCategory(category:String):Array<AchievementData>
	{
		final list:Array<AchievementData> = [];
		for (ach in all) if (ach.category == category) list.push(ach);

		return list;
	}
}
