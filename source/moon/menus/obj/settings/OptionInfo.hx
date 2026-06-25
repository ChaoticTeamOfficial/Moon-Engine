package moon.menus.obj.settings;

import moon.dependency.user.MoonSettings.Setting;

class OptionInfo extends FlxSpriteGroup
{
	var bg:MoonSprite;
	var topText:FlxText;
	var descriptionText:FlxText;

	public function new()
	{
		super();

		bg = new MoonSprite().makeGraphic(Std.int(FlxG.width / 3) + 64, Std.int(FlxG.height / 2 + 128), FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, bg.width, bg.height, 16, 16, FlxColor.BLACK);
		bg.alpha = 0.65;
		add(bg);

		topText = new FlxText(24, 24, bg.width - 24);
		topText.setFormat(Paths.font('phantomuff/difficulty.ttf'), 28, LEFT, FlxColor.WHITE);
		topText.antialiasing = true;
		add(topText);

		descriptionText = new FlxText(24, 24, bg.width - 26);
		descriptionText.setFormat(Paths.font('phantomuff/full.ttf'), 18, LEFT);
		descriptionText.antialiasing = true;
		add(descriptionText);

		topText.text = 'LOREM IPSUM DOLOR SIT AMET';
	}

	var texts:Array<FlxText> = [];

	public function updateInfo(setting:Setting)
	{
		topText.text = MoonLang.settingName(setting.name).toUpperCase();

		descriptionText.text = MoonLang.settingDesc(setting.name, setting.description);
		descriptionText.y = topText.y + topText.height + 24;
		MoonUtils.scrambleText(topText);

		// this is kinda ass lol
		/*if(texts.length > 0)
				for(option in texts)
				{
					remove(option);
					option.destroy();
					texts
				}

			if(setting.type == SELECTOR)
			{
				final options:Array<Dynamic> = cast setting.options;
				for(i in 0...options.length)
				{
					var option = new FlxText(24, descriptionText.y + descriptionText.height + (20 * i), bg.width - 26, '${options[i]}');
					option.setFormat(Paths.font('phantomuff/full.ttf'), 18, LEFT);
					option.antialiasing = true;
					add(option);
					texts.push(option);
				}
			}
		 */
	}

	public function updateSetting(setting:Setting)
	{
		if (setting.type != SELECTOR) return;
	}
}
