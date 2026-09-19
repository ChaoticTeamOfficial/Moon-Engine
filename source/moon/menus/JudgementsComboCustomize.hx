package moon.menus;

import moon.game.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.game.obj.judgements.*;
import moon.menus.obj.MenuPage;
import moon.menus.obj.settings.OptionObject;

class JudgementsComboCustomize extends FlxSubState
{
	var strumlines:Array<Strumline> = [];
	var healthBar:HealthBar;
	var stats:FlxText;
	var judgements:JudgementSprite;
	var combo:ComboNumbers;
	var dragGraphic:MoonSprite;
	var menuPage:MenuPage;
	var settingsMode:Bool = true;
	var modeLabel:FlxText;
	var hintLabel:FlxText;
	var lastAnimSetting:String = '';
	var currentDragOBJ:FlxObject;
	var objOffset:FlxPoint = FlxPoint.get();

	public function new()
	{
		super();

		if (PlayState.instance != null) this.camera = PlayState.instance.camALT;

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/background'));
		add(bg);
		bg.alpha = 0.0001;
		FlxTween.tween(bg, {
			alpha: 1
		}, 0.9);

		// TODO: get current playstate skin? maybe be able to switch between them?
		judgements = new JudgementSprite('moon-engine');
		add(judgements);
		add(judgements.extra);

		combo = new ComboNumbers('moon-engine');
		add(combo);

		for (i in 0...2)
		{
			var strumline = new Strumline(0, 0, 'v-slice', true, 'opponent', null);
			add(strumline.strumBG);
			add(strumline);
			strumlines.push(strumline);
		}

		healthBar = new HealthBar('dummy', 'dummy');
		healthBar.screenCenter(X);
		add(healthBar);

		stats = new FlxText();
		stats.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 24, CENTER);
		stats.text = 'Score: ${FlxG.random.int(1000, 9999)} • Misses: 0 • Acc: ${FlxG.random.int(10, 100)}%';
		stats.antialiasing = true;
		add(stats);
		stats.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
		stats.screenCenter();
		stats.visible = false;

		dragGraphic = new MoonSprite().makeGraphic(1, 1, FlxColor.WHITE);
		add(dragGraphic);
		dragGraphic.alpha = 0.00001;

		replayPop(true);

		menuPage = new MenuPage(0, 0, MoonLang.get('ui.customization.title', 'CUSTOMIZATION'));
		add(menuPage);
		menuPage.build(['Judgement Customization', 'Combo Customization'], cat -> MoonSettings.categories.get(cat));

		menuPage.onChange.add(() ->
		{
			Paths.playSFX('menus/settings/settingsSelection.wav', 'sounds', true, FlxG.random.float(0.9, 1.25));
			lastAnimSetting = currentAnimSettingKey();
		});

		modeLabel = new FlxText(0, 0, FlxG.width);
		modeLabel.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 20, FlxColor.WHITE, CENTER);
		modeLabel.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
		modeLabel.antialiasing = true;
		add(modeLabel);

		hintLabel = new FlxText(0, 0, FlxG.width);
		hintLabel.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 16, 0xFFCCCCCC, CENTER);
		hintLabel.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		hintLabel.antialiasing = true;
		add(hintLabel);

		updateModeLabels();
		updateStrums();
	}

	function updateStrums()
	{
		final downscroll = MoonSettings.callSetting('Downscroll');
		for (strum in strumlines)
		{
			strum.y = (!downscroll) ? 80 : FlxG.height - strum.height - 80;

			final mid = (FlxG.width * 0.5);
			final xAddition = (FlxG.width * 0.25);
			final strumXs = [-xAddition, xAddition];

			final playerStrum = strumlines[1];
			final oppStrum = strumlines[0];

			playerStrum.x = (MoonSettings.callSetting('Middlescroll')) ? mid : mid + strumXs[1];
			oppStrum.x = mid + strumXs[0];
			oppStrum.visible = oppStrum.strumBG.visible = !MoonSettings.callSetting('Middlescroll');

			strum.strumBG.setPosition(strum.x - (strum.strumBG.width / 2), 0);
			strum.strumBG.alpha = MoonSettings.callSetting('Lane Background Visibility');
		}

		healthBar.y = (downscroll) ? 64 : FlxG.height - healthBar.height + 32;
		stats.y = healthBar.y + stats.height + 8;

		modeLabel.y = FlxG.height - 56;
		hintLabel.y = FlxG.height - 32;
	}

	function updateModeLabels()
	{
		if (settingsMode)
		{
			modeLabel.text = 'MODE: SETTINGS  [TAB to switch to Position]';
			hintLabel.text = 'UP-DOWN / Wheel: select | LEFT-RIGHT: change value | SPACE: replay anim | R: reset positions';
			menuPage.alpha = 1;
		}
		else
		{
			modeLabel.text = 'MODE: POSITION [TAB to switch to Settings]';
			hintLabel.text = 'Drag judgement or combo with mouse | SPACE: replay anim | R: reset positions';
			menuPage.alpha = 0.35;
		}
	}

	function replayPop(notAnimated:Bool = false)
	{
		final judges = ['sick', 'good', 'bad', 'shit'];
		final j = judges[FlxG.random.int(0, judges.length - 1)];
		judgements.pop(j, FlxG.random.bool(20), notAnimated);

		final neg = FlxG.random.bool(50) ? '-' : 'x';
		combo.pop('${neg}${FlxG.random.int(100, 9999)}', judgements.color, notAnimated);
	}

	function currentAnimSettingKey():String
	{
		if (menuPage == null || menuPage.navOptions.length == 0) return '';
		final s = menuPage.navOptions[menuPage.curSelected].setting;
		return s != null ? '${s.name}:${s.value}' : '';
	}

	function isAnimRelatedSetting(name:String):Bool
	{
		// lollll
		return
			name == 'Judgement Spawn Animation'
			|| name == 'Judgement Despawn Animation'
			|| name == 'Combo Spawn Animation'
			|| name == 'Combo Despawn Animation'
			|| name == 'Combo Spacing'
			|| name == 'Combo Rolls';
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.TAB)
		{
			settingsMode = !settingsMode;
			currentDragOBJ = null;
			dragGraphic.alpha = 0.00001;
			updateModeLabels();
			Paths.playSFX('menus/settings/settingsSelection.wav', 'sounds', true, FlxG.random.float(0.95, 1.1));
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			replayPop(false);
			Paths.playSFX('menus/settings/settingsSelection.wav', 'sounds', true, FlxG.random.float(1.05, 1.2));
		}

		if (FlxG.keys.justPressed.R)
		{
			MoonSettings.setSetting('JudgePos', [500, 270]);
			MoonSettings.setSetting('ComboPos', [500, 340]);
			replayPop(true);
			Paths.playSFX('menus/settings/settingsOFF.wav', 'sounds', true);
		}

		if (settingsMode)
		{
			if (MoonInput.justPressed(UI_UP)) menuPage.changeSelection(-1);
			else if (MoonInput.justPressed(UI_DOWN)) menuPage.changeSelection(1);

			if (FlxG.mouse.wheel != 0) menuPage.changeSelection(-FlxG.mouse.wheel);

			if (menuPage.navOptions.length > 0)
			{
				final cur = menuPage.navOptions[menuPage.curSelected];
				menuPage.optionsContainer.y = FlxMath.lerp(
					menuPage.optionsContainer.y,
					FlxG.height / 2 - (cur.y + cur.height / 2 - menuPage.optionsContainer.y),
					elapsed * 13
				);
				menuPage.optionFollower.y = cur.y - 5;

				final key = currentAnimSettingKey();
				if (key != lastAnimSetting && isAnimRelatedSetting(cur.setting.name))
				{
					lastAnimSetting = key;
					replayPop(false);
				}
			}
		}
		else
		{
			updateTo(FlxG.mouse.overlaps(judgements, this.camera) ? judgements : (FlxG.mouse.overlaps(combo, this.camera) ? combo : null));

			if (currentDragOBJ != null) currentDragOBJ.setPosition(FlxG.mouse.x - objOffset.x, FlxG.mouse.y - objOffset.y);

			if (FlxG.mouse.justReleased && currentDragOBJ != null)
			{
				final dr = (currentDragOBJ == judgements) ? 'Judge' : 'Combo';
				MoonSettings.setSetting('${dr}Pos', [currentDragOBJ.x, currentDragOBJ.y]);
				currentDragOBJ = null;
			}
		}

		if (MoonInput.justPressed(BACK))
		{
			FlxG.mouse.visible = false;
			FlxG.state.openSubState(new Settings(true));
		}
	}

	function updateTo(sprite:FlxObject)
	{
		if (sprite == null)
		{
			dragGraphic.alpha = 0.00001;
			return;
		}

		dragGraphic.alpha = 0.45;
		if (dragGraphic.width != sprite.width || dragGraphic.height != sprite.height)
		{
			dragGraphic.setGraphicSize(Std.int(sprite.width), Std.int(sprite.height));
			dragGraphic.updateHitbox();
		}

		dragGraphic.setPosition(sprite.x + sprite.width / 2 - dragGraphic.width / 2, sprite.y + sprite.height / 2 - dragGraphic.height / 2);

		if (FlxG.mouse.justPressed)
		{
			currentDragOBJ = sprite;
			objOffset.set(FlxG.mouse.x - sprite.x, FlxG.mouse.y - sprite.y);
		}
	}

	override public function destroy()
	{
		FlxG.mouse.visible = false;
		if (objOffset != null) objOffset.put();
		super.destroy();
	}
}
