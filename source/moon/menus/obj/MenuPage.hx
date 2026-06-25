package moon.menus.obj;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import moon.dependency.user.MoonSettings.Setting;
import moon.menus.obj.settings.OptionObject;

// TODO: maybe make it independant on its own?

/**
 * Vertical menu page with categories, options, and navigation.
 * Used by the Settings and can be used by any other menu that needs the same layout.
 */
class MenuPage extends FlxSpriteGroup
{
	public var titleText:FlxText;
	public var optionsContainer:FlxSpriteGroup;
	public var navOptions:Array<OptionObject> = [];
	public var optionFollower:MoonSprite;
	public var curSelected:Int = 0;
	public var onChange:FlxSignal = new FlxSignal();

	private var yPos:Float = 0;
	private var afterHeaderY:Float = 0;

	public function new(x:Float = 0, y:Float = 0, title:String = "SETTINGS")
	{
		super(x, y);

		optionFollower = new MoonSprite(20, 1000).makeGraphic(OptionObject.separationWidth + 16, 32, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(optionFollower, 0, 0, optionFollower.width, optionFollower.height, 8, 8, FlxColor.WHITE);
		add(optionFollower);

		optionsContainer = new FlxSpriteGroup();
		add(optionsContainer);

		titleText = new FlxText(32, yPos);
		titleText.text = title;
		titleText.setFormat(Paths.font('phantomuff/difficulty.ttf'), 54, CENTER);
		titleText.antialiasing = true;
		optionsContainer.add(titleText);
		yPos += titleText.height + 16;

		var separator = new MoonSprite(32, yPos).makeGraphic(OptionObject.separationWidth, 2, FlxColor.WHITE);
		optionsContainer.add(separator);
		yPos += separator.height + 16;

		afterHeaderY = yPos;
	}

	/**
	 * Builds all categories and their options.
	 * @param categories List of category names (in order)
	 * @param getSettings Function that returns the settings for a given category
	 */
	public function build(categories:Array<String>, getSettings:String->Array<Setting>):Void
	{
		navOptions = [];
		yPos = afterHeaderY;

		for (cat in categories) createCategory(cat, getSettings(cat));

		if (navOptions.length > 0) changeSelection(0);
	}

	private function createCategory(category:String, settings:Array<Setting>):Void
	{
		final separation = 16;

		var catTxt = new FlxText(32, yPos, -1, MoonLang.category(category));
		catTxt.setFormat(Paths.font("phantomuff/difficulty.ttf"), 32, FlxColor.WHITE, CENTER);
		catTxt.antialiasing = true;
		catTxt.alpha = 0.7;
		optionsContainer.add(catTxt);

		yPos += catTxt.height + separation;

		for (setting in settings)
		{
			var option = new OptionObject(32, yPos, setting, category);
			optionsContainer.add(option);
			option.camera = camera;
			navOptions.push(option);
			yPos += option.height + separation;
		}

		yPos += separation + 32;
	}

	public function changeSelection(change:Int = 0):Void
	{
		if (navOptions.length == 0) return;
		curSelected = FlxMath.wrap(curSelected + change, 0, navOptions.length - 1);

		for (i in 0...navOptions.length) navOptions[i].selected = (i == curSelected);

		onChange.dispatch();
	}

	/**
	 * Called when language changes (or any other time the menu needs a full refresh).
	 */
	public function refresh(categories:Array<String>, getSettings:String->Array<Setting>):Void
	{
		var toRemove:Array<FlxSprite> = [];
		for (i in 2...optionsContainer.members.length) toRemove.push(optionsContainer.members[i]);

		for (member in toRemove)
		{
			optionsContainer.remove(member);
			member.destroy();
		}

		navOptions = [];
		yPos = afterHeaderY;

		build(categories, getSettings);
	}
}
