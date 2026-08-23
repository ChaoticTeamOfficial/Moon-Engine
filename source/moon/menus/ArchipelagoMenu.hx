package moon.menus;

import openfl.events.KeyboardEvent;
import openfl.ui.Keyboard;
import moon.backend.archipelago.ArchipelagoManager;
import moon.backend.archipelago.ArchipelagoSave;
import moon.global_obj.UIButton;

using StringTools;

/**
 * Dedicated menu for connecting to an Archipelago multiworld.
 * mostly a placeholder menu?
 */
class ArchipelagoMenu extends FlxTransitionableState
{
	static final FIELD_HOST:Int = 0;
	static final FIELD_PORT:Int = 1;
	static final FIELD_SLOT:Int = 2;
	static final FIELD_PASSWORD:Int = 3;
	static final FIELD_CONNECT:Int = 4;
	static final FIELD_PLAY:Int = 5;
	static final FIELD_BACK:Int = 6;

	var fieldLabels:Array<String> = [
		"HOST",
		"PORT",
		"SLOT",
		"PASSWORD",
		"CONNECT",
		"PLAY",
		"BACK"
	];
	var fieldValues:Array<String> = ["", "38281", "", ""];
	var valueTexts:Array<FlxText> = [];
	var labelTexts:Array<FlxText> = [];
	var actionButtons:Array<UIButton> = [];
	var curSelected:Int = 0;
	var statusText:FlxText;
	var editing:Bool = false;

	override public function create()
	{
		super.create();

		Global.allowInputs = true;

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/menuDesat'));
		bg.color = 0xFF6b4cff;
		bg.x += 132;
		add(bg);

		var blackBar = new MoonSprite().makeGraphic(620, FlxG.height, FlxColor.BLACK);
		blackBar.skew.x = 10;
		blackBar.x -= 100;
		add(blackBar);

		var title = new FlxText();
		title.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 42, CENTER);
		title.text = '- ARCHIPELAGO -';
		title.color = 0xFFffd863;
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
		title.letterSpacing = -2;
		title.y = 48;
		title.x = 40;
		add(title);

		loadDefaults();

		final startY = 130;
		final rowH = 44;

		for (i in 0...4)
		{
			final label = new FlxText(40, startY + rowH * i, 160, fieldLabels[i]);
			label.setFormat(Paths.font('phantomuff/full.ttf'), 22, FlxColor.WHITE, LEFT);
			label.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			add(label);
			labelTexts.push(label);

			final value = new FlxText(210, startY + rowH * i, 340, fieldValues[i] == "" ? "..." : fieldValues[i]);
			value.setFormat(Paths.font('phantomuff/full.ttf'), 22, 0xFFaaaaaa, LEFT);
			value.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
			add(value);
			valueTexts.push(value);
		}

		final connectBtn = new UIButton(40, startY + rowH * 4 + 12, "CONNECT");
		add(connectBtn);
		actionButtons.push(connectBtn);

		final playBtn = new UIButton(40, startY + rowH * 5 + 20, "PLAY");
		add(playBtn);
		actionButtons.push(playBtn);

		final backBtn = new UIButton(40, startY + rowH * 6 + 28, "BACK");
		add(backBtn);
		actionButtons.push(backBtn);

		statusText = new FlxText(40, FlxG.height - 80, 560, getStatusString());
		statusText.setFormat(Paths.font('phantomuff/full.ttf'), 18, FlxColor.WHITE, LEFT);
		statusText.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(statusText);

		changeSelection(0);
		wireSignals();

		FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
	}

	override public function destroy()
	{
		FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, onKeyDown);
		super.destroy();
	}

	function loadDefaults()
	{
		if (ArchipelagoManager.host != "")
		{
			fieldValues[FIELD_HOST] = ArchipelagoManager.host;
			fieldValues[FIELD_PORT] = Std.string(ArchipelagoManager.port);
			fieldValues[FIELD_SLOT] = ArchipelagoManager.slot;
			fieldValues[FIELD_PASSWORD] = ArchipelagoManager.password;
		}
	}

	function wireSignals()
	{
		ArchipelagoManager.onConnected.add(() ->
		{
			try
			{
				statusText.text = 'Connected to ${ArchipelagoManager.slot}';
				statusText.color = 0xff73ff73;
			}
			catch (e)
			{
			}
			actionButtons[0].dText.text = "DISCONNECT";
			refreshFieldDisplay();
		});

		ArchipelagoManager.onDisconnected.add(() ->
		{
			statusText.text = "Disconnected.";
			statusText.color = 0xFFffaa66;
			actionButtons[0].dText.text = "CONNECT";
		});
	}

	function getStatusString():String
	{
		if (ArchipelagoManager.isConnected) return 'Connected to ${ArchipelagoManager.slot}';
		return "Not connected.";
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (editing)
		{
			if (MoonInput.justPressed(ACCEPT))
			{
				editing = false;
				refreshFieldDisplay();
				Paths.playSFX('ui/scrollMenu.ogg');
			}
			return;
		}

		if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
		if (MoonInput.justPressed(UI_UP)) changeSelection(-1);

		if (MoonInput.justPressed(ACCEPT))
		{
			if (curSelected <= FIELD_PASSWORD)
			{
				editing = true;
				refreshFieldDisplay();
				Paths.playSFX('ui/scrollMenu.ogg');
			}
			else if (curSelected == FIELD_CONNECT) toggleConnect();
			else if (curSelected == FIELD_PLAY)
			{
				if (ArchipelagoManager.isConnected) FlxG.switchState(() -> new ArchipelagoPlayMenu());
				else
				{
					statusText.text = "Connect first.";
					statusText.color = 0xFFff6666;
				}
			}
			else if (curSelected == FIELD_BACK) FlxG.switchState(() -> new MainMenu());
		}

		if (MoonInput.justPressed(BACK)) FlxG.switchState(() -> new MainMenu());

		if (ArchipelagoManager.isConnected && statusText.color != 0xFF66ff66)
		{
			statusText.text = 'Connected to ${ArchipelagoManager.slot}';
			statusText.color = 0xFF66ff66;
			actionButtons[0].dText.text = "DISCONNECT";
		}
	}

	function toggleConnect()
	{
		if (ArchipelagoManager.isConnected)
		{
			ArchipelagoManager.disconnect();
			return;
		}

		final host = fieldValues[FIELD_HOST].trim();
		final portStr = fieldValues[FIELD_PORT].trim();
		final slot = fieldValues[FIELD_SLOT].trim();
		final password = fieldValues[FIELD_PASSWORD];

		if (host == "" || slot == "")
		{
			statusText.text = "Host and Slot are required.";
			statusText.color = 0xFFff6666;
			return;
		}

		final port = Std.parseInt(portStr);
		if (port == null || port <= 0)
		{
			statusText.text = "Invalid port.";
			statusText.color = 0xFFff6666;
			return;
		}

		statusText.text = 'Connecting to $host:$port...';
		statusText.color = 0xFFffd863;
		ArchipelagoManager.connect(host, port, slot, password);
	}

	function changeSelection(change:Int)
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, FIELD_BACK);
		Paths.playSFX('ui/scrollMenu.ogg');
		refreshFieldDisplay();
	}

	function refreshFieldDisplay()
	{
		for (i in 0...4)
		{
			final selected = (i == curSelected);
			labelTexts[i].color = selected ? 0xFFffd863 : FlxColor.WHITE;

			var display = fieldValues[i];
			if (i == FIELD_PASSWORD && display != "") display = [for (_ in 0...display.length) "*"].join("");
			if (display == "") display = "...";

			if (selected && editing)
			{
				valueTexts[i].text = display + "_";
				valueTexts[i].color = 0xFFffffff;
			}
			else
			{
				valueTexts[i].text = display;
				valueTexts[i].color = selected ? 0xFFffd863 : 0xFFaaaaaa;
			}
		}

		actionButtons[0].selected = curSelected == FIELD_CONNECT;
		actionButtons[1].selected = curSelected == FIELD_PLAY;
		actionButtons[2].selected = curSelected == FIELD_BACK;
	}

	function onKeyDown(e:KeyboardEvent)
	{
		if (!editing || curSelected > FIELD_PASSWORD) return;

		final idx = curSelected;

		if (e.keyCode == Keyboard.BACKSPACE)
		{
			if (fieldValues[idx].length > 0) fieldValues[idx] = fieldValues[idx].substr(0, fieldValues[idx].length - 1);
			refreshFieldDisplay();
			return;
		}

		if (e.charCode >= 32 && e.charCode <= 126)
		{
			if (idx == FIELD_PORT && (e.charCode < "0".code || e.charCode > "9".code)) return;

			if (fieldValues[idx].length < 64) fieldValues[idx] += String.fromCharCode(e.charCode);
			refreshFieldDisplay();
		}
	}
}
