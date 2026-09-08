package moon.menus;

import moon.dependency.user.MoonAchievements;
import moon.menus.obj.achievements.*;
import flixel.FlxCamera;

class AchievementsMenu extends FlxSubState
{
	public function new():Void
	{
		super();
	}

	// hardcoded order of the categories.
	// custom ones go at the bottom
	static var categoriesOrder:Array<String> = ['Story Mode', 'Freeplay', 'Extras'];

	var camMain:FlxCamera; // main camera that contains the achievements icon
	var camUI:FlxCamera; // for the side bar
	// user cursor
	var userPointer:MoonSprite;
	var userPointerLag:MoonSprite;
	var selectSound:MoonSound; // move sound so it doesn't overlap with itself
	// lerp position for the cursor
	var targetX:Float = 48.0;
	var targetY:Float = 196.0;
	var categories:Array<AchievementCategory> = []; // currently unused
	var pageText:FlxText; // name of the achievement "page" (mod name)
	var pos:Array<Int> = [0, 0]; // 2d array for the position of the cursor
	var achievementRows:Array<Array<AchievementIcon>> = []; // achievements per row
	// achievement info display
	var achievementName:FlxText;
	var achievementIcon:MoonSprite;
	var achievementCategory:FlxText;
	var achievementDescription:FlxText;
	var achievementSeparator:MoonSprite;

	override function create():Void
	{
		super.create();

		camMain = new FlxCamera();
		camMain.bgColor = 0;
		FlxG.cameras.add(camMain, false);

		camUI = new FlxCamera();
		camUI.bgColor = 0;
		FlxG.cameras.add(camUI, false);

		selectSound = new MoonSound().load(Paths.sound('ui/scrollMenu.ogg', 'sounds'));
		selectSound.volume = MoonSettings.callSetting('SFX Volume') / 100;

		var bg = new MoonSprite(-300, 0).loadGraphic(Paths.image('menus/menuDesat'));
		bg.color = 0xFFE5D059;
		add(bg);
		// bg.camera = camMain;

		var sideBar = new MoonSprite().makeGraphic(420, FlxG.height, 0xFF202020);
		add(sideBar);
		sideBar.camera = camUI;
		sideBar.skew.x = -2;
		sideBar.x = FlxG.width - sideBar.width + 50;

		var topBar = new MoonSprite().makeGraphic(FlxG.width, 64, FlxColor.BLACK);
		add(topBar);
		topBar.camera = camUI;

		// page text, this would be the mod name
		pageText = new FlxText(0, 0, 500);
		pageText.setFormat(Paths.font('phantomuff/full.ttf'), 32, FlxColor.WHITE, CENTER, OUTLINE, FlxColor.BLACK);
		add(pageText);
		pageText.borderSize = 2.5;
		pageText.x += 215;
		pageText.y += 100;
		pageText.text = 'Friday Night Funkin\'';
		pageText.fieldHeight = 200;
		pageText.camera = camMain;

		// side bar stuff
		achievementSeparator = new MoonSprite().makeGraphic(304, 3, 0xFF7A7A7A);
		achievementSeparator.setPosition(944, 400);
		add(achievementSeparator);
		achievementSeparator.camera = camUI;

		achievementIcon = new MoonSprite().loadGraphic(Paths.getGraphic('placeholder-icon', 'achievements'), true, 250);
		add(achievementIcon);
		achievementIcon.setGraphicSize(128);
		achievementIcon.updateHitbox();
		achievementIcon.setPosition(1028, 150);
		achievementIcon.camera = camUI;

		achievementName = new FlxText(0, 0, 300, 'placeholder');
		achievementName.setFormat(Paths.font('phantomuff/difficulty.ttf'), 28, FlxColor.WHITE, CENTER);
		add(achievementName);
		achievementName.setPosition(944, 300);
		achievementName.camera = camUI;

		achievementCategory = new FlxText(0, 0, 300, 'placeholder • Friday Night Funkin\'');
		achievementCategory.setFormat(Paths.font('phantomuff/full.ttf'), 16, 0xFF8C8C8C, CENTER);
		add(achievementCategory);
		achievementCategory.setPosition(944, 340);
		achievementCategory.camera = camUI;

		achievementDescription = new FlxText(0, 0, 300, 'Description');
		achievementDescription.setFormat(Paths.font('phantomuff/full.ttf'), 16, FlxColor.WHITE, CENTER);
		add(achievementDescription);
		achievementDescription.setPosition(944, 400);
		achievementDescription.camera = camUI;

		loadAchievements();

		userPointer = new MoonSprite().loadGraphic(Paths.getGraphic('pointer', 'achievements'));
		userPointer.scale.set(3, 3);
		userPointer.updateHitbox();
		userPointer.color = 0xFFCBDBFC;
		userPointer.camera = camMain;

		userPointerLag = new MoonSprite().loadGraphic(Paths.getGraphic('pointer', 'achievements'));
		userPointerLag.scale.set(3, 3);
		userPointerLag.updateHitbox();
		userPointerLag.color = 0xFFFFC480;
		userPointerLag.camera = camMain;
		add(userPointerLag);
		add(userPointer);

		// camera movement
		camMain.follow(userPointer);
		camMain.maxScrollX = 1280;
		camMain.minScrollX = 0;
		camMain.minScrollY = 0;
		camMain.deadzone = FlxRect.weak(0, 200, 0, 500);

		moveSelection();
	}

	var elapsedTime:Float = 0.0;
	var holdTimer:Float = 0.0;
	var randomizeName:Bool = false;
	var randomizeDesc:Bool = false;

	override function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// repeat move if the player has held a key for over 0.5 seconds
		if ((MoonInput.pressed(UI_DOWN) != MoonInput.pressed(UI_UP)) || MoonInput.pressed(UI_LEFT) != MoonInput.pressed(UI_RIGHT))
		{
			holdTimer += elapsed;
			// only allow one key per press
			if (holdTimer > 0.15)
			{
				if (MoonInput.pressed(UI_DOWN)) moveSelection(0, 1);
				else if (MoonInput.pressed(UI_UP)) moveSelection(0, -1);
				if (MoonInput.pressed(UI_LEFT)) moveSelection(-1, 0);
				else if (MoonInput.pressed(UI_RIGHT)) moveSelection(1, 0);
			}
		}
		else
		{
			holdTimer = -0.5; // initial time
		}

		if (MoonInput.justPressed(UI_DOWN)) moveSelection(0, 1);
		if (MoonInput.justPressed(UI_UP)) moveSelection(0, -1);
		if (MoonInput.justPressed(UI_LEFT)) moveSelection(-1, 0);
		if (MoonInput.justPressed(UI_RIGHT)) moveSelection(1, 0);

		if (MoonInput.justPressed(BACK)) close();

		// move cursors
		userPointer.x = FlxMath.lerp(userPointer.x, targetX, 25 * elapsed);
		userPointer.y = FlxMath.lerp(userPointer.y, targetY, 25 * elapsed);
		userPointerLag.x = FlxMath.lerp(userPointerLag.x, targetX, 12 * elapsed);
		userPointerLag.y = FlxMath.lerp(userPointerLag.y, targetY, 12 * elapsed);

		// debug remove all saves
		/*
			if (FlxG.keys.justPressed.R)
			{
				MoonAchievements.resetUnlocks();
				close();
			}
		 */

		elapsedTime += elapsed;

		// shuffle name and description if either of them are hidden
		if (elapsedTime > 0.5)
		{
			elapsedTime = 0;
			if (randomizeName) achievementName.text = shuffleString(achievementName.text);
			if (randomizeDesc) achievementDescription.text = shuffleString(achievementDescription.text);
		}
	}

	override function destroy():Void
	{
		super.destroy();
		FlxG.cameras.remove(camMain);
		FlxG.cameras.remove(camUI);
	}

	private function loadAchievements():Void
	{
		// sort categories
		var categoriesList:Array<String> = MoonAchievements.categories.copy();
		for (i in categoriesOrder) categoriesList.remove(i);
		categoriesList = categoriesOrder.copy().concat(categoriesList);

		for (i in 0...categoriesList.length)
		{
			var achievementList:Array<AchievementData> = getAchievementsByCategory(categoriesList[i]);
			if (achievementList.length == 0) continue; // if all the achievements of the category are hidden, we just skip it

			var group = new AchievementCategory(40, 164, categoriesList[i], achievementList);
			add(group);
			if (i > 0) group.y = categories[i - 1].y + categories[i - 1].height + 32; // reposition each line based on the last

			// get achievements for the achievementRows array
			for (i in 0...Math.floor(achievementList.length / 9) + 1)
			{
				var list = group.achievementList.slice(9 * i, 9 * (i + 1));
				achievementRows.push(list);
			}

			categories.push(group);
			group.camera = camMain;
		}
	}

	private function moveSelection(?x:Int = 0, ?y:Int = 0, ?set:Bool = false):Void
	{
		if (holdTimer > 0.0) holdTimer = 0.0; // restart hold timer so the auto shift resets

		// play sound
		if (selectSound != null)
		{
			selectSound.stop();
			selectSound.play();
			selectSound.pitch = FlxG.random.float(0.85, 1.15);
		}

		pos[1] = FlxMath.wrap(pos[1] + y, 0, achievementRows.length - 1);
		pos[0] = FlxMath.wrap(pos[0] + x, 0, achievementRows[pos[1]].length - 1);

		var achivement:AchievementIcon = achievementRows[pos[1]][pos[0]]; // get achievement
		achievementIcon.frame = achivement.frame; // copy frame
		achievementIcon.setGraphicSize(128);
		achievementIcon.updateHitbox();
		// get position for the cursor
		var position:FlxRect = achivement.getGraphicBounds();
		targetX = position.x;
		targetY = position.y;

		achievementName.text = achivement.name;
		achievementCategory.text = '${achivement.category} • Friday Night Funkin\'';
		achievementDescription.text = achivement.description;

		achievementCategory.y = achievementName.y + achievementName.height + 4;
		achievementSeparator.y = achievementCategory.y + 48;
		achievementDescription.y = achievementSeparator.y + 16;
		randomizeName = achivement.hideName;
		randomizeDesc = achivement.hideDesc;
		elapsedTime = 134; // so it automatically shuffles the name if needed
	}

	// filter achievements by category, excluding secret ones

	private function getAchievementsByCategory(categoryName:String):Array<AchievementData>
	{
		var achievementsArray:Array<AchievementData> = MoonAchievements.getByCategory(categoryName);

		return achievementsArray.filter(function(achievement:AchievementData)
		{
			if (!achievement.secret)
			{
				return true; // always return if it's not hidden
			}
			else
			{
				// if its hidden, we check if we unlocked it first
				if (MoonAchievements.isUnlocked(achievement.id)) return true;
			}
			return false;
		});
	}

	private function shuffleString(string:String):String
	{
		var newString = '';
		var exclude:Array<Int> = [];
		for (i in 0...string.length)
		{
			var selectedCharacter:Int = FlxG.random.int(0, string.length - 1, exclude);
			newString += string.charAt(selectedCharacter);
			exclude.push(selectedCharacter);
		}

		return newString;
	}
}
