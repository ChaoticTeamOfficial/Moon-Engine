package moon.toolkit.level_editor;

import lime.system.System;
import moon.toolkit.ui.UIActionButton;
import moon.toolkit.ui.UITheme;
import moon.toolkit.level_editor.pages.*;
import moon.menus.*;

using StringTools;

class LeftPanel extends FlxSpriteGroup
{
	var panelBehind:MoonSprite;
	var bg:MoonSprite;
	var headerBox:FlxSpriteGroup;
	var headerTitle:FlxText;
	var backButton:UIActionButton;
	var buttons:Array<IconButton> = [];
	var buttonMap:Map<String, IconButton> = [];
	var keybinds:Array<
		{modifiers:Array<String>, key:String, action:String}> = [];
	var pageMap:Map<String, PanelPage> = [];
	var pageStack:Array<PanelPage> = [];
	var editor:LevelEditor = null;

	public var panelOpen:Bool = false;
	public var curPanel:String = '';

	static inline final PANEL_W:Int = 360;
	static inline final HEADER_H:Int = 40;

	public function new(editor:LevelEditor, ?list:Array<String>)
	{
		super();

		this.editor = editor;

		panelBehind = new MoonSprite().makeGraphic(PANEL_W, FlxG.height, 0xFF0b0b0b);
		add(panelBehind);
		panelBehind.x = -panelBehind.width;

		bg = new MoonSprite().makeGraphic(80, FlxG.height, 0xFF181818);
		add(bg);
		bg.active = panelBehind.active = false;

		_buildHeader();

		// Build icon buttons
		if (list == null || list.length <= 0)
		{
			list = [
				'menu',
				'separator',
				'joystick',
				'videoSettings',
				'separator',
				'editDocument',
				'openFolder',
				'lightbulb',
				'space-196',
				'settings',
				'openDoor',
				'space-399999',
				'saveL'
			];
		}

		var curY:Float = 24;
		final gap:Float = 10;

		for (i in 0...list.length)
		{
			if (list[i].startsWith('space-')) curY += Std.parseFloat(list[i].split('-')[1]);
			else if (list[i] == 'separator')
			{
				var separator = new MoonSprite().makeGraphic(60, 1, FlxColor.WHITE);
				separator.setPosition(bg.x + bg.width / 2 - separator.width / 2, curY);
				separator.active = false;
				separator.alpha = 0.15;
				add(separator);

				curY += 2 + gap;
			}
			else
			{
				var thing = new IconButton(0, 0, 40, 40, list[i]);
				thing.invertShader = editor?.invertColors ?? new InvertColor();
				add(thing);
				thing.setPosition(bg.x + bg.width / 2 - thing.width / 2, curY);

				thing.callback = () -> selectButton(thing, list[i]);
				buttons.push(thing);
				buttonMap.set(list[i], thing);

				curY += 48 + gap;
			}
		}

		panelOpen = false;

		keybinds = [
			{
				modifiers: ["CONTROL"],
				key: "O",
				action: "openFolder"
			},
			{
				modifiers: ["CONTROL"],
				key: "S",
				action: "saveL"
			}
		];

		registerPage('menu', new MainPage());
	}

	public function registerPage(buttonName:String, page:PanelPage):Void
	{
		page.panel = this;
		pageMap.set(buttonName, page);
	}

	public function push(page:PanelPage):Void
	{
		if (pageStack.length > 0) pageStack[pageStack.length - 1].hide();

		page.panel = this;
		pageStack.push(page);
		_showTopPage();
		_refreshHeader();
	}

	public function pop():Void
	{
		if (pageStack.length == 0) return;

		final top = pageStack.pop();
		top.hide();

		if (pageStack.length > 0)
		{
			_showTopPage();
			_refreshHeader();
		}
		else
			close();
	}

	public function selectButton(selected:IconButton, name:String):Void
	{
		for (btn in buttons) if (btn != selected) btn.isPressed = false;

		switch (name)
		{
			case 'menu', 'layers', 'designServices':
				_openPageForButton(name);

			case 'openFolder':
				new FlxTimer().start(0.1, _ -> selected.isPressed = false);

				if (editor != null)
				{
					editor.sfx('popupSMALL', true);
					System.openFile(System.applicationDirectory + Paths.getPath('songs/${editor.song}/${editor.mix}'));
				}
				else
				{
					Paths.playSFX('toolkit/general/popupSMALL.wav', false);
					System.openFile('${System.applicationDirectory}assets/stages/stage');
				}

			case 'settings':
				if (editor != null)
				{
					editor.playback.state = PAUSE;
					editor.sustainLoopOpp.pause();
					editor.sustainLoopP1.pause();

					var stt = new Settings();
					stt.camera = editor.camFRONT;
					FlxG.state.openSubState(stt);
				}

			case 'saveL':
				if (editor != null) editor.saveLevel();
		}
	}

	public function close():Void
	{
		for (page in pageStack) page.hide();
		pageStack = [];

		for (btn in buttons) btn.isPressed = false;

		panelOpen = false;
		curPanel = '';

		headerBox.visible = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (editor != null) editor.allowEditing = !panelOpen;

		if (panelOpen && curPanel != '' && pageStack.length == 0)
		{
			final btn = buttonMap.get(curPanel);
			if (btn != null && !btn.isPressed) close();
		}

		panelBehind.x = FlxMath.lerp(panelBehind.x, panelOpen ? bg.x + bg.width : -panelBehind.width, 0.2);

		_positionHeader();

		for (kb in keybinds)
		{
			var modsPressed:Bool = true;
			for (mod in kb.modifiers)
			{
				if (!Reflect.getProperty(FlxG.keys.pressed, mod))
				{
					modsPressed = false;
					break;
				}
			}

			if (modsPressed && Reflect.getProperty(FlxG.keys.justPressed, kb.key))
			{
				final btn = buttonMap.get(kb.action);
				if (btn != null) selectButton(btn, kb.action);
			}
		}

		if (FlxG.mouse.justPressed && !FlxG.mouse.overlaps(this, this.camera)) close();
	}

	function _buildHeader():Void
	{
		headerBox = new FlxSpriteGroup();
		headerBox.visible = false;
		add(headerBox);

		final headerBg = new MoonSprite().makeGraphic(PANEL_W, HEADER_H, 0xFF111111);
		headerBg.active = false;
		headerBox.add(headerBg);

		backButton = new UIActionButton(4, (HEADER_H - 28) / 2, 28, "<", () -> pop(), null, 28);
		headerBox.add(backButton);

		headerTitle = new FlxText(40, 0, PANEL_W - 48, "", 13);
		headerTitle.font = UITheme.FONT;
		headerTitle.color = 0xFFCCCCCC;
		headerTitle.antialiasing = true;
		headerTitle.active = false;
		headerTitle.y = (HEADER_H - headerTitle.height) / 2;
		headerBox.add(headerTitle);
	}

	function _positionHeader():Void
	{
		final px = panelBehind.x;
		headerBox.x = px;
		headerBox.y = 0;

		for (page in pageStack)
		{
			if (page.root != null && page.root.visible)
			{
				page.root.left = px;
				page.root.top = HEADER_H;
				page.root.width = PANEL_W;
				page.root.height = FlxG.height - HEADER_H;
				page.content.width = PANEL_W;
			}
		}
	}

	function _refreshHeader():Void
	{
		if (pageStack.length == 0)
		{
			headerBox.visible = false;
			return;
		}

		headerBox.visible = true;
		headerTitle.text = pageStack[pageStack.length - 1].title;
		backButton.visible = (pageStack.length > 1);
	}

	function _showTopPage():Void
	{
		if (pageStack.length == 0) return;
		final top = pageStack[pageStack.length - 1];
		final px = panelBehind.x;
		top.show(px, HEADER_H, PANEL_W, FlxG.height - HEADER_H);
	}

	function _openPageForButton(name:String):Void
	{
		if (panelOpen && curPanel == name)
		{
			close();
			return;
		}

		for (page in pageStack) page.hide();
		pageStack = [];

		curPanel = name;
		panelOpen = true;

		final page = pageMap.get(name);
		if (page != null)
		{
			page.panel = this;
			pageStack.push(page);
			_showTopPage();
		}

		_refreshHeader();
	}
}
