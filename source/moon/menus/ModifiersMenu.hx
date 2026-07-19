package moon.menus;

import flixel.group.FlxSpriteGroup;
import flixel.text.FlxText;
import moon.backend.gameplay.modifiers.ModifierManager;
import moon.backend.gameplay.modifiers.Modifier;

// ! ATTENTION!
// ! THIS MENU IS A PLACEHOLDER MENU.
// ! THE ACTUAL MENU WILL BE IMPLEMENTED AFTER A CONCEPT IS DONE.
class ModifiersMenu extends FlxSpriteGroup
{
	public var isOpen(default, null):Bool = false;

	var overlay:FlxSprite;
	var header:FlxText;
	var footer:FlxText;
	var entries:Array<FlxText> = [];
	var modIds:Array<String> = [];
	var curSelected:Int = 0;
	var descDivider:FlxSprite;
	var descTitle:FlxText;
	var descBody:FlxText;

	static inline var VALUE_STEP:Float = 0.05;
	static inline var ENTRY_HEIGHT:Float = 32;
	static inline var LIST_X:Float = 220;
	static inline var LIST_Y:Float = 100;
	static inline var COLUMN_SPLIT:Float = 0.52;
	static inline var COLUMN_GAP:Float = 40;

	public function new()
	{
		super();

		overlay = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		overlay.alpha = 0.87;
		add(overlay);

		header = new FlxText(LIST_X, LIST_Y - 50, FlxG.width - LIST_X * 2, "MODIFIERS");
		header.setFormat(Paths.font('BRIANNE_S_HAND.TTF'), 32, FlxColor.WHITE);
		add(header);

		footer = new FlxText(LIST_X, FlxG.height - 60, FlxG.width - LIST_X * 2, "UP/DOWN: select   LEFT/RIGHT: adjust value   ACCEPT: toggle   TAB: close");
		footer.setFormat(Paths.font('BRIANNE_S_HAND.TTF'), 16, FlxColor.GRAY);
		add(footer);

		var splitX = FlxG.width * COLUMN_SPLIT;

		descDivider = new FlxSprite(splitX, LIST_Y - 10).makeGraphic(2, Std.int(FlxG.height - LIST_Y - 50), FlxColor.GRAY);
		descDivider.alpha = 0.5;
		add(descDivider);

		descTitle = new FlxText(splitX + COLUMN_GAP, LIST_Y, FlxG.width - splitX - COLUMN_GAP - LIST_X, "");
		descTitle.setFormat(Paths.font('BRIANNE_S_HAND.TTF'), 26, FlxColor.YELLOW);
		add(descTitle);

		descBody = new FlxText(splitX + COLUMN_GAP, LIST_Y + 40, FlxG.width - splitX - COLUMN_GAP - LIST_X, "");
		descBody.setFormat(Paths.font('5by7_b.ttf'), 18, FlxColor.WHITE);
		add(descBody);

		buildList();

		visible = false;
		active = false;
	}

	function buildList():Void
	{
		modIds = [for (id in ModifierManager.all.keys()) id];
		modIds.sort((a, b) -> Reflect.compare(ModifierManager.all.get(a).name, ModifierManager.all.get(b).name));

		for (entry in entries) remove(entry, true);
		entries = [];

		for (i in 0...modIds.length)
		{
			var txt = new FlxText(LIST_X, LIST_Y + i * ENTRY_HEIGHT, (FlxG.width * COLUMN_SPLIT) - LIST_X - 10, "");
			txt.setFormat(Paths.font('5by7_b.ttf'), 20, FlxColor.WHITE);
			add(txt);
			entries.push(txt);
		}

		refreshEntryText();
	}

	function refreshEntryText():Void
	{
		for (i in 0...modIds.length)
		{
			final mod = ModifierManager.all.get(modIds[i]);
			final txt = entries[i];

			final valueLabel = mod.valueType == RANGE ? ' (${Math.round(mod.value * 100) / 100})' : '';

			txt.text = '${i == curSelected ? "> " : "  "}${mod.name}$valueLabel  ${mod.active ? "[ON]" : "[off]"}';

			if (i == curSelected) txt.color = FlxColor.YELLOW;
			else if (mod.active) txt.color = FlxColor.LIME;
			else
				txt.color = FlxColor.WHITE;
		}

		refreshDescription();
	}

	function refreshDescription():Void
	{
		if (modIds.length <= 0)
		{
			descTitle.text = "";
			descBody.text = "";
			return;
		}

		var mod = ModifierManager.all.get(modIds[curSelected]);

		descTitle.text = mod.name;
		descBody.text = mod.description;
	}

	public function open():Void
	{
		isOpen = true;
		visible = true;
		active = true;
		curSelected = 0;
		buildList();
	}

	public function close():Void
	{
		isOpen = false;
		visible = false;
		active = false;
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!isOpen || modIds.length <= 0) return;

		if (MoonInput.justPressed(UI_DOWN))
		{
			curSelected = FlxMath.wrap(curSelected + 1, 0, modIds.length - 1);
			refreshEntryText();
		}

		if (MoonInput.justPressed(UI_UP))
		{
			curSelected = FlxMath.wrap(curSelected - 1, 0, modIds.length - 1);
			refreshEntryText();
		}

		var mod = ModifierManager.all.get(modIds[curSelected]);

		if (mod.valueType == RANGE)
		{
			if (MoonInput.justPressed(UI_LEFT))
			{
				ModifierManager.setValue(mod.id, mod.value - VALUE_STEP);
				refreshEntryText();
			}

			if (MoonInput.justPressed(UI_RIGHT))
			{
				ModifierManager.setValue(mod.id, mod.value + VALUE_STEP);
				refreshEntryText();
			}
		}

		if (MoonInput.justPressed(ACCEPT))
		{
			if (mod.active)
			{
				ModifierManager.deactivate(mod.id);

				Paths.playSFX('menus/modifiers/modifierEnable.wav', 'sounds', true, 0.6);
			}
			else
			{
				final blockers = ModifierManager.getBlockingModifiers(mod.id);
				if (blockers.length > 0) ModifierManager.activate(mod.id, true);
				else
					ModifierManager.activate(mod.id);

				Paths.playSFX('menus/modifiers/modifierEnable.wav', 'sounds', true);
			}

			refreshEntryText();
		}

		if ((FlxG.keys.justPressed.TAB))
		{
			if (Freeplay.instance != null) Freeplay.instance.modTmr = 0;
			close();
		}
	}
}
