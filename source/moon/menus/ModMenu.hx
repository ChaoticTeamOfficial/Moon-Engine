package moon.menus;

#if sys
import sys.FileSystem;
#end

//TODOS:
//Check why this class causes a memory leak when putting a mod up or down in priority
// documment this class too ofc
// and lastly uhhh polish it up.

class ModObj extends FlxSpriteGroup
{
	public var mod:Mod;
	public var selected(default, set):Bool = false;
	public var dragging(default, set):Bool;
	public var isActive(default, set):Bool;

	public static final WIDTH:Float = 596;

	private var highlight:MoonSprite;
	private var icon:MoonSprite;
	private var nameTxt:ScrollingText;
	private var byTxt:ScrollingText;
	var curCol:FlxColor;

	public function new(mod:Mod)
	{
	    super();
	    this.mod = mod;

	    highlight = new MoonSprite(0, -8);
	    highlight.makeGraphic(Std.int(WIDTH), 64, FlxColor.TRANSPARENT);
	    highlight.visible = highlight.active = false;
	    add(highlight);

	    icon = new MoonSprite(16, 8);
	    final iconPath = mod.getAsset("icon.png");
	    #if sys
	    if (iconPath != null && FileSystem.exists(iconPath))
	    {
	        final bmp = openfl.display.BitmapData.fromFile(iconPath);
	        if (bmp != null) icon.loadGraphic(flixel.graphics.FlxGraphic.fromBitmapData(bmp, false, iconPath, false));
	        else icon.makeGraphic(32, 32, FlxColor.WHITE);
	    }
	    else icon.makeGraphic(32, 32, FlxColor.WHITE);
	    #else
	    icon.makeGraphic(32, 32, FlxColor.WHITE);
	    #end
	    icon.setGraphicSize(32, 32);
	    icon.updateHitbox();
	    icon.active = icon.antialiasing = false;
	    add(icon);

	    nameTxt = new ScrollingText(64, 5, WIDTH - 85, (mod.metadata.name != null && mod.metadata.name != "None") ? mod.metadata.name : mod.name, 32);
	    nameTxt.textField.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE, LEFT);
	    nameTxt.textField.antialiasing = true;
	    add(nameTxt);

	    var authorStr = "BY: ";
	    authorStr += (mod.metadata.team != null && mod.metadata.team.length > 0) ? mod.metadata.team.map(t -> t.name).join(", ") : "UNKNOWN";

	    byTxt = new ScrollingText(nameTxt.x, 26, WIDTH - 85, authorStr.toUpperCase(), 19);
	    byTxt.textField.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 20, FlxColor.GRAY, LEFT);
	    byTxt.textField.antialiasing = true;
	    add(byTxt);

	    FlxSpriteUtil.drawRoundRect(highlight, 0, 0, highlight.width, highlight.height, 16, 16, FlxColor.TRANSPARENT, {thickness: 4, color: FlxColor.WHITE});

	    dragging = false;
	}

	private function refreshColor():Void
	    nameTxt.textField.color = (isActive ? 0xFFFFA500 : FlxColor.WHITE);

	public function set_selected(sel:Bool):Bool
	{
	    selected = sel;
	    highlight.visible = sel;
	    refreshColor();
	    return sel;
	}

	public function set_dragging(drag:Bool):Bool
	{
	    dragging = drag;
	    refreshColor();
	    return drag;
	}

	public function set_isActive(ia:Bool):Bool
	{
	    isActive = ia;
	    refreshColor();
	    return ia;
	}
}

class ModMenu extends FlxTransitionableState
{
	private var inactiveList:Array<Mod> = [];
	private var activeList:Array<Mod> = [];
	private var inactiveObjs:Array<ModObj> = [];
	private var activeObjs:Array<ModObj> = [];

	private var currentSide:Int = 0;
	private var selectedIndex:Array<Int> = [0, 0];

	private var confirmingActivate:Bool = false;
	private var reorderingActive:Bool = false;
	private var scroll:Array<Float> = [0, 0];
	private var targetScroll:Array<Float> = [0, 0];

	override public function create():Void
	{
		super.create();

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/background'));
		add(bg);
		bg.alpha = 0.0001;
		FlxTween.tween(bg, {alpha: 1}, 0.9);

		var mid = new MoonSprite().makeGraphic(5, FlxG.height - 38, FlxColor.WHITE);
		add(mid);
		mid.screenCenter();
		mid.scale.set(1, 0);
		FlxTween.tween(mid.scale, {y: 1}, 1, {ease: FlxEase.expoOut});

		Mods.scanMods();
		refreshLists();

		var colors = [FlxColor.BLACK];
		for (i in 0...4)
			colors.push(FlxColor.TRANSPARENT);
		colors.push(FlxColor.BLACK);
		add(FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, colors));

		for (i in 0...2)
		{
			var t = new FlxText();
			t.text = ((i == 0) ? 'INACTIVE' : 'ACTIVE') + ' MODS';
			t.setFormat(Paths.font('phantomuff/difficulty.ttf'), 42, FlxColor.WHITE, CENTER);
			add(t);
			t.antialiasing = true;
			t.y = 32;
			t.alpha = 0.00001;
			FlxTween.tween(t, {alpha: 1}, 1);
			t.x = (FlxG.width * (i == 0 ? 0.25 : 0.75)) - (t.width / 2);
		}
	}

	private function refreshLists():Void
	{
		for (obj in inactiveObjs) remove(obj);
		for (obj in activeObjs) remove(obj);
		inactiveObjs = [];
		activeObjs = [];

		inactiveList = [];
		for (m in Mods.allMods)
			if (!Mods.config.enabled.contains(m.name))
				inactiveList.push(m);

		activeList = Mods.activeMods;

		final leftX = FlxG.width * 0.25 - (ModObj.WIDTH / 2);
		final rightX = FlxG.width * 0.75 - (ModObj.WIDTH / 2);

		for (i in 0...inactiveList.length)
		{
			var obj = new ModObj(inactiveList[i]);
			obj.x = leftX;
			obj.y = 115 + i * 95;
			obj.isActive = false;
			add(obj);
			inactiveObjs.push(obj);
		}

		for (i in 0...activeList.length)
		{
			var obj = new ModObj(activeList[i]);
			obj.x = rightX;
			obj.y = 115 + i * 95;
			obj.isActive = true;
			add(obj);
			activeObjs.push(obj);
		}

		if (currentSide == 0 && inactiveList.length == 0) currentSide = 1;
		if (currentSide == 1 && activeList.length == 0) currentSide = 0;

		selectedIndex[0] = inactiveList.length > 0 ? Std.int(Math.min(selectedIndex[0], inactiveList.length - 1)) : 0;
		selectedIndex[1] = activeList.length > 0 ? Std.int(Math.min(selectedIndex[1], activeList.length - 1)) : 0;

		updateSelectionVisuals();

		updateScrollTarget(0);
		updateScrollTarget(1);

		scroll[0] = targetScroll[0];
		scroll[1] = targetScroll[1];

		applyScroll();
	}

	private function applyScroll():Void
	{
		for (i in 0...inactiveObjs.length) inactiveObjs[i].y = 115 + i * 95 + scroll[0];
		for (i in 0...activeObjs.length) activeObjs[i].y = 115 + i * 95 + scroll[1];
	}

	private function updateSelectionVisuals():Void
	{
		for (obj in inactiveObjs) obj.selected = false;
		for (obj in activeObjs) obj.selected = false;

		if (currentSide == 0 && inactiveObjs.length > 0)
			inactiveObjs[selectedIndex[0]].selected = true;
		else if (currentSide == 1 && activeObjs.length > 0)
			activeObjs[selectedIndex[1]].selected = true;
	}

	private function updateDraggingVisuals():Void
	{
		final active = reorderingActive && currentSide == 1;
		for (i in 0...activeObjs.length)
			activeObjs[i].dragging = active && i == selectedIndex[1];
	}

	private function changeSelection(dir:Int):Void
	{
		final listLength = (currentSide == 0) ? inactiveList.length : activeList.length;
		if (listLength == 0) return;

		selectedIndex[currentSide] = FlxMath.wrap(selectedIndex[currentSide] + dir, 0, listLength - 1);
		Paths.playSFX('ui/scrollMenu.ogg');

		updateSelectionVisuals();
		updateScrollTarget(currentSide);
	}

	private function updateScrollTarget(side:Int):Void
	{
		final len = (side == 0 ? inactiveObjs : activeObjs).length;
		if (len == 0) return;

		final minScroll = Math.min(0.0, (FlxG.height - 150) - (115 + (len - 1) * 95));
		targetScroll[side] = FlxMath.bound(FlxG.height * 0.5 - (115 + selectedIndex[side] * 95 + 32), minScroll, 0);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		scroll[0] = FlxMath.lerp(scroll[0], targetScroll[0], 0.25);
		scroll[1] = FlxMath.lerp(scroll[1], targetScroll[1], 0.25);
		applyScroll();

		if (reorderingActive)
		{
		    if (MoonInput.justPressed(UI_UP) || MoonInput.justPressed(UI_DOWN))
		    {
		        final up = MoonInput.justPressed(UI_UP);
		        Paths.playSFX('menus/mods/mod${up ? "Higher" : "Lower"}.wav');
		        final newIdx = selectedIndex[1] + (up ? -1 : 1);
		        if (newIdx >= 0 && newIdx < activeList.length)
		        {
		            swapActiveOrder(selectedIndex[1], newIdx);
		            selectedIndex[1] = newIdx;
		            refreshLists();
		            updateSelectionVisuals();
		            updateScrollTarget(currentSide);
		        }
		    }

		    if (MoonInput.justPressed(UI_LEFT))
		    {
		        final modName = activeList[selectedIndex[1]].name;
		        Mods.toggleMod(modName);
		        refreshLists();

		        var newIndex = -1;
		        for (i in 0...inactiveList.length)
		            if (inactiveList[i].name == modName) { newIndex = i; break; }

		        if (newIndex != -1)
		        {
		            currentSide = 0;
		            selectedIndex[0] = newIndex;
		            reorderingActive = false;
		            confirmingActivate = true;
		        }
		        else reorderingActive = false;

		        updateSelectionVisuals();
		        updateScrollTarget(currentSide);

		        Paths.playSFX('menus/mods/modInactive.wav');
		    }
		}
		else if (confirmingActivate)
		{
			if (MoonInput.justPressed(UI_RIGHT))
			{
				final mod = inactiveList[selectedIndex[0]];
				if (!Mods.loadOrder.contains(mod.name)) Mods.loadOrder.push(mod.name);

				Mods.toggleMod(mod.name);
				refreshLists();

				var newIndex = -1;
				for (i in 0...activeList.length)
					if (activeList[i].name == mod.name) { newIndex = i; break; }

				if (newIndex != -1)
				{
					currentSide = 1;
					selectedIndex[1] = newIndex;
					confirmingActivate = false;
					reorderingActive = true;
				}
				else confirmingActivate = false;

				updateSelectionVisuals();
				updateScrollTarget(currentSide);

				Paths.playSFX('menus/mods/modActive.wav');
			}
		}

		if ((confirmingActivate || reorderingActive) && (MoonInput.justPressed(ACCEPT) || MoonInput.justPressed(BACK)))
		{
			confirmingActivate = reorderingActive = false;
			updateSelectionVisuals();
			updateScrollTarget(currentSide);
			Paths.playSFX('menus/mods/modRelease.wav');
			return;
		}

		if (!confirmingActivate && !reorderingActive)
		{
			if (MoonInput.justPressed(UI_LEFT) && inactiveList.length > 0)
			{
				currentSide = 0;
				updateSelectionVisuals();
				updateScrollTarget(currentSide);
			}
			if (MoonInput.justPressed(UI_RIGHT) && activeList.length > 0)
			{
				currentSide = 1;
				updateSelectionVisuals();
				updateScrollTarget(currentSide);
			}

			if (MoonInput.justPressed(UI_UP) || MoonInput.justPressed(UI_DOWN))
				changeSelection(MoonInput.justPressed(UI_UP) ? -1 : 1);

			if (MoonInput.justPressed(ACCEPT))
			{
				if (currentSide == 0 && inactiveList.length > 0) confirmingActivate = true;
				else if (currentSide == 1 && activeList.length > 0) reorderingActive = true;
				updateSelectionVisuals();
				updateScrollTarget(currentSide);
				Paths.playSFX('menus/mods/modHold.wav');
			}

			if(MoonInput.justPressed(BACK)) FlxG.switchState(new MainMenu());
		}

		updateDraggingVisuals();
	}

	private function swapActiveOrder(idxA:Int, idxB:Int):Void
	{
	    final posA = Mods.loadOrder.indexOf(activeList[idxA].name);
	    final posB = Mods.loadOrder.indexOf(activeList[idxB].name);
	    final tmp = Mods.loadOrder[posA];
	    Mods.loadOrder[posA] = Mods.loadOrder[posB];
	    Mods.loadOrder[posB] = tmp;
	    Mods.rebuildActiveMods();
	    Mods.saveConfig();
	}
}