package moon.menus;

import flixel.util.FlxGradient;
import moon.game.submenus.PauseScreen;
import moon.game.PlayState;
import moon.menus.obj.MenuPage;
import moon.menus.obj.settings.OptionInfo;
import moon.dependency.user.MoonSettings.Setting;

class Settings extends FlxSubState
{
	public static var current:Settings;

	var menuPage:MenuPage;
	var info:OptionInfo;

	public function new(skipTransition:Bool = false)
	{
		super();

		current = this;

		if (PlayState.instance != null) this.camera = PlayState.instance.camALT;
		var back = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		back.blend = HARDLIGHT;
		back.alpha = 0.0001;
		add(back);
		FlxTween.tween(back, {
			alpha: 0.6
		}, skipTransition ? 0.0000001 : 0.8);

		var backGradient = FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, [0x00000000, 0xFF111111], 1, 180);
		backGradient.alpha = 0;
		add(backGradient);
		FlxTween.tween(backGradient, {
			alpha: 1
		}, skipTransition ? 0.0000001 : 1);

		menuPage = new MenuPage(0, 0, MoonLang.get('ui.settings.title', 'SETTINGS'));
		add(menuPage);
		menuPage.build(MoonSettings.categoryOrder, cat -> MoonSettings.categories.get(cat));

		info = new OptionInfo();
		info.screenCenter(Y);
		info.x = FlxG.width / 2 + 64;
		info.y -= 32;
		FlxTween.tween(info, {
			y: info.y + 32
		}, 2, {
			type: PINGPONG,
			ease: FlxEase.quadInOut
		});
		add(info);

		if (!skipTransition)
		{
			info.scale.set(3, 0);
			FlxTween.tween(info.scale, {
				x: 1,
				y: 1
			}, 0.2, {
				ease: FlxEase.backOut
			});
		}

		FlxTween.tween(menuPage.optionFollower, {
			alpha: 0.5
		}, 5, {
			type: PINGPONG,
			ease: FlxEase.quadIn
		});

		menuPage.onChange.add(() ->
		{
			info.updateInfo(menuPage.navOptions[menuPage.curSelected].setting);
			Paths.playSFX('menus/settings/settingsSelection.wav', 'sounds', true, FlxG.random.float(0.9, 1.25));
		});

		if (!skipTransition) Paths.playSFX('menus/settings/settingsEnter.wav', 'sounds', true);

		changeSelection(0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (MoonInput.justPressed(UI_UP)) menuPage.changeSelection(-1);
		else if (MoonInput.justPressed(UI_DOWN)) menuPage.changeSelection(1);
		else if (FlxG.keys.justPressed.TAB) changeCategory();

		if (FlxG.mouse.wheel != 0) menuPage.changeSelection(-FlxG.mouse.wheel);

		// centers the selected option
		final cur = menuPage.navOptions[menuPage.curSelected];
		final targetY = FlxG.height / 2 - (cur.y + cur.height / 2 - menuPage.optionsContainer.y);
		menuPage.optionsContainer.y = FlxMath.lerp(menuPage.optionsContainer.y, targetY, elapsed * 13);
		menuPage.optionFollower.y = cur.y - 5;

		if (MoonInput.justPressed(BACK))
		{
			Paths.playSFX('menus/settings/settingsLeave.wav', 'sounds', true);
			close();
			if (PlayState.instance != null) PlayState.instance.openSubState(new PauseScreen(PlayState.instance.camALT));
		}
	}

	private function changeCategory():Void
	{
		final curCat = menuPage.navOptions[menuPage.curSelected].category;
		final idx = MoonSettings.categoryOrder.indexOf(curCat);
		final nextIdx = (idx + 1) % MoonSettings.categoryOrder.length;

		for (i => opt in menuPage.navOptions)
		{
			if (opt.category == MoonSettings.categoryOrder[nextIdx])
			{
				menuPage.curSelected = i;
				menuPage.changeSelection(0);
				Paths.playSFX('menus/settings/settingsSectionChange.wav', 'sounds', true);
				return;
			}
		}
	}

	public function refreshOptions():Void
	{
		menuPage.titleText.text = MoonLang.get('ui.settings.title', 'SETTINGS');
		menuPage.refresh(MoonSettings.categoryOrder, cat -> MoonSettings.categories.get(cat));
		changeSelection(0);
	}

	private function changeSelection(change:Int = 0):Void
	{
		menuPage.changeSelection(change);
		info.updateInfo(menuPage.navOptions[menuPage.curSelected].setting);
	}

	override public function close()
	{
		super.close();
		current = null;
	}
}
