package;

import moon.toolkit.ui.*;

using StringTools;

class TestState extends FlxState
{
	var pageManager:UIPageManager;
	var sidebarButtons:Array<FlxSprite> = [];
	var sidebarLabels:Array<FlxText> = [];
	var pageIds:Array<String> = ["rendering", "notes", "create", "scroll"];
	var statusText:FlxText;

	static inline final SIDEBAR_WIDTH:Float = 64;

	override public function create():Void
	{
		super.create();
		FlxG.cameras.bgColor = 0xFF2E2543;
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		var sidebarBg = RoundedRectCache.create(Std.int(SIDEBAR_WIDTH), Std.int(FlxG.height), FlxColor.WHITE);
		sidebarBg.color = UITheme.SIDEBAR_BG;
		add(sidebarBg);

		var icons = ["Render", "Notes", "Chart", "Scroll"];
		for (i in 0...icons.length)
		{
			var btn = RoundedRectCache.create(48, 48, FlxColor.WHITE);
			btn.setPosition(8, 16 + i * 56);

			btn.color = UITheme.CONTROL_BG;
			add(btn);
			sidebarButtons.push(btn);

			var lbl = new FlxText(btn.x, btn.y + 16, 48, icons[i].substr(0, 1), 18);
			lbl.font = UITheme.FONT;
			lbl.color = UITheme.TEXT_COLOR;
			lbl.alignment = CENTER;
			add(lbl);
			sidebarLabels.push(lbl);
		}

		var version = new FlxText(SIDEBAR_WIDTH + 8, 4, 200, "0.5.0");
		version.font = UITheme.FONT;
		version.color = UITheme.TEXT_DIM;
		version.size = 12;
		add(version);

		statusText = new FlxText(SIDEBAR_WIDTH + 8, FlxG.height - 24, FlxG.width - SIDEBAR_WIDTH - 16, "");
		statusText.font = UITheme.FONT;
		statusText.color = UITheme.TEXT_DIM;
		statusText.size = 12;
		add(statusText);

		pageManager = new UIPageManager();
		add(pageManager);

		buildRenderingSettingsPage();
		buildNoteSettingsPage();
		buildCreateChartPage();
		buildScrollTestPage();

		add(UIOverlay.init());

		pageManager.switchTo("rendering", FadeOnly);
		highlightSidebar(0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (FlxG.mouse.justPressed)
		{
			var mp = FlxG.mouse.getWorldPosition();
			for (i in 0...sidebarButtons.length)
			{
				var b = sidebarButtons[i];
				if (mp.x >= b.x && mp.x <= b.x + b.width && mp.y >= b.y && mp.y <= b.y + b.height)
				{
					pageManager.switchTo(pageIds[i]);
					highlightSidebar(i);
					break;
				}
			}
		}
	}

	function highlightSidebar(index:Int):Void
	{
		for (i in 0...sidebarButtons.length)
		{
			sidebarButtons[i].color = i == index ? UITheme.ACCENT : UITheme.CONTROL_BG;
			sidebarLabels[i].color = i == index ? FlxColor.WHITE : UITheme.TEXT_COLOR;
		}
	}

	function header(text:String):FlxText
	{
		var t = new FlxText(0, 0, 400, text, 20);
		t.font = UITheme.FONT;
		t.color = UITheme.TEXT_COLOR;
		t.antialiasing = UITheme.FONT_ANTIALIASING;
		return t;
	}

	function report(msg:String):Void
	{
		trace(msg);
		if (statusText != null) statusText.text = msg;
	}

	function buildRenderingSettingsPage():Void
	{
		var page = new UIPage(SIDEBAR_WIDTH + 30, 40, "Rendering Settings");

		page.add(header("Rendering Settings"));

		var dRenderBg = new UIDropdown(0, 40, 380, "Render Background:", ["Off", "On"]);
		var dRenderChars = new UIDropdown(0, 0, 380, "Render Characters:", ["Off", "On"], null, 1);
		var dRenderEvents = new UIDropdown(0, 0, 380, "Render Events:", ["Off", "Only Camera (Box)", "On"], null, 1);
		var dRenderUI = new UIDropdown(0, 0, 380, "Render UI and Playtest:", ["Off", "On"]);

		dRenderBg.onChange = (v) -> report('Render Background -> $v');
		dRenderChars.onChange = (v) -> report('Render Characters -> $v');
		dRenderEvents.onChange = (v) -> report('Render Events -> $v');
		dRenderUI.onChange = (v) -> report('Render UI and Playtest -> $v');

		page.addComponent(dRenderBg);
		page.addComponent(dRenderChars);
		page.addComponent(dRenderEvents);
		page.addComponent(dRenderUI);

		var vsync = new UICheckbox(0, 0, 380, "V-Sync Enabled:", true);
		vsync.onChange = (v) -> report('V-Sync Enabled -> $v');
		page.addComponent(vsync);

		var msaa = new UIStepper(0, 0, 380, "MSAA Samples:", 0, 8, 4, 2);
		msaa.onChange = (v) -> report('MSAA Samples -> $v');
		page.addComponent(msaa);

		page.layoutVertical(40);

		pageManager.registerPage("rendering", page);
	}

	function buildNoteSettingsPage():Void
	{
		var page = new UIPage(SIDEBAR_WIDTH + 30, 40, "Normal Note Settings");

		page.add(header("Normal Note Settings"));

		var scrollSpeed = new UIDropdown(0, 40, 320, "Scroll Speed:", ["None", "Slow", "Normal", "Fast"]);
		var bonusPoints = new UIDropdown(0, 0, 320, "Bonus Points:", ["None", "Small", "Large"]);
		var damageBoost = new UIDropdown(0, 0, 320, "Damage Boost:", ["None", "x1.5", "x2"]);

		scrollSpeed.onChange = (v) -> report('Scroll Speed -> $v');
		bonusPoints.onChange = (v) -> report('Bonus Points -> $v');
		damageBoost.onChange = (v) -> report('Damage Boost -> $v');

		page.addComponent(scrollSpeed);
		page.addComponent(bonusPoints);
		page.addComponent(damageBoost);

		var botPlay = new UICheckbox(0, 0, 320, "Bot Play:", false);
		botPlay.onChange = (v) -> report('Bot Play -> $v');
		page.addComponent(botPlay);

		var comboMult = new UIStepper(0, 0, 320, "Max Combo Multiplier:", 1, 10, 4, 1);
		comboMult.onChange = (v) -> report('Max Combo Multiplier -> $v');
		page.addComponent(comboMult);

		page.layoutVertical(40);

		pageManager.registerPage("notes", page);
	}

	function buildCreateChartPage():Void
	{
		var page = new UIPage(SIDEBAR_WIDTH + 30, 20, "Create a New Chart");

		page.add(header("Create a New Chart"));

		var sub1 = header("Display Settings");
		sub1.size = 16;
		sub1.y = 40;
		page.add(sub1);

		var songName = new UITextBox(0, 70, 380, "Song's Name:");
		var songIcon = new UITextBox(0, 0, 380, "Song's Icon (Freeplay):");
		var songWeek = new UITextBox(0, 0, 380, "Song's Week (Story):");

		songName.onChange = (v) -> report('Song Name -> $v');
		songIcon.onChange = (v) -> report('Song Icon -> $v');
		songWeek.onChange = (v) -> report('Song Week -> $v');
		songName.onEnter = (v) -> report('Song Name confirmed -> $v');

		page.addComponent(songName);
		page.addComponent(songIcon);
		page.addComponent(songWeek);

		var featured = new UICheckbox(0, 0, 380, "Featured Chart:", false);
		featured.onChange = (v) -> report('Featured Chart -> $v');
		page.addComponent(featured);

		var difficultyNumber = new UIStepper(0, 0, 380, "Difficulty Number:", 1, 10, 3, 1);
		difficultyNumber.onChange = (v) -> report('Difficulty Number -> $v');
		page.addComponent(difficultyNumber);

		var highlightColor = new UIColorPicker(0, 0, 380, "Chart Highlight Color:", UITheme.ACCENT);
		highlightColor.onChange = (c) -> report('Chart Highlight Color -> 0x' + StringTools.hex(c, 6));
		page.addComponent(highlightColor);

		page.layoutVertical(70);

		var sub2 = header("Difficulty Settings:");
		sub2.size = 16;
		sub2.y = difficultyNumber.y + difficultyNumber.rowHeight + 30;
		page.add(sub2);

		var diffButtons = new UIButtonList(0, sub2.y + 30, ["Easy", "Normal", "Hard", "Erect"], Horizontal, 1, true);
		diffButtons.onSelect = (i, label) -> report('Difficulty -> $label');
		diffButtons.onExtra = () -> report('Add custom difficulty requested');
		page.add(diffButtons);

		var sub3 = header("Starcount Settings:");
		sub3.size = 16;
		sub3.y = diffButtons.y + 50;
		page.add(sub3);

		var starButtons = new UIButtonList(0, sub3.y + 30, ["Automatic", "Custom", "Disabled"], Horizontal, 0);
		starButtons.onSelect = (i, label) -> report('Starcount Mode -> $label');
		page.add(starButtons);

		var starSlider = new UISlider(0, starButtons.y + 50, 432, "RODA O CU", 0.5, 2.0, 1.0, 0.1);
		starSlider.onChange = (v) -> report('RODA A BOLA -> ${Math.round(v * 100) / 100}');
		page.add(starSlider);

		pageManager.registerPage("create", page);
	}

	function buildScrollTestPage():Void
	{
		var page = new UIScrollPage(SIDEBAR_WIDTH + 30, 40, 420, 320, "Scroll Test");

		page.addComponent(new UICheckbox(0, 0, 420, "Row 1 - Checkbox:", true));

		var dd = new UIDropdown(0, 0, 420, "Row 2 - Dropdown:", ["Alpha", "Beta", "Gamma", "Delta"]);
		dd.onChange = (v) -> report('Row 2 Dropdown -> $v');
		page.addComponent(dd);

		var stepper = new UIStepper(0, 0, 420, "Row 3 - Stepper:", 0, 20, 5, 1);
		stepper.onChange = (v) -> report('Row 3 Stepper -> $v');
		page.addComponent(stepper);

		var slider = new UISlider(0, 0, 420, "Row 4 - Slider:", 0, 10, 3, 0.5);
		slider.onChange = (v) -> report('Row 4 Slider -> ${Math.round(v * 100) / 100}');
		page.addComponent(slider);

		var color = new UIColorPicker(0, 0, 420, "Row 5 - Color Picker:", UITheme.ACCENT);
		color.onChange = (c) -> report('Row 5 Color -> 0x' + StringTools.hex(c, 6));
		page.addComponent(color);

		for (i in 6...16)
		{
			var cb = new UICheckbox(0, 0, 420, 'Row $i - Checkbox:', i % 2 == 0);
			final row = i;
			cb.onChange = (v) -> report('Row $row -> $v');
			page.addComponent(cb);
		}

		var textBox = new UITextBox(0, 0, 420, "Row 16 - Text Box:");
		textBox.onChange = (v) -> report('Row 16 Text -> $v');
		page.addComponent(textBox);

		page.layoutVertical();

		pageManager.registerPage("scroll", page);
	}

	public function goTo(id:String):Void
	{
		final idx = pageIds.indexOf(id);
		if (idx >= 0) highlightSidebar(idx);
		pageManager.switchTo(id);
	}
}
