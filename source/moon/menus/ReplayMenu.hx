package moon.menus;

import moon.game.*;
import moon.game.obj.*;
import moon.menus.obj.replay.*;
import moon.backend.gameplay.Timings;
import moon.menus.obj.freeplay.FreeplayRank;
import flixel.group.FlxSpriteGroup;
import sys.FileSystem;

// import flixel.util.FlxSpriteUtil;
using StringTools;

class ReplayMenu extends FlxSubState
{
	var replays:Array<ReplayItem> = [];
	final dir = Paths.readDir('data/replays', ['.mrp']);
	var inSubMenu:Bool = false; // if on the button menu
	var pointer:Array<Int> = [0, 0]; // left and right, line
	var infoBoxGroup:FlxSpriteGroup;
	var songName:FlxText; // the name of the replay
	var chartName:FlxText; // the name of the chart
	var replayInfo:Array<FlxText> = []; // song info (replay code, date, combo, etc)
	var replayRank:FreeplayRank;
	var playButton:ReplayButton;
	var editButton:ReplayButton;
	var deleteButton:ReplayButton;

	public function new()
	{
		super();

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/replay/bg'));
		add(bg);

		bgColor = FlxColor.GRAY;

		for (i in 0...dir.length)
		{
			var replay = new ReplayItem(12, 52 + 84 * i, dir[i]);
			add(replay);
			replays.push(replay);
		}
		infoBoxGroup = new FlxSpriteGroup();
		add(infoBoxGroup);

		var infoBoxBG = new MoonSprite().makeGraphic(350, Std.int(FlxG.height * 0.85), FlxColor.BLACK);
		infoBoxGroup.add(infoBoxBG);
		infoBoxGroup.screenCenter();
		infoBoxGroup.x = FlxG.width - infoBoxGroup.width - 8;

		var placeholder = new MoonSprite().loadGraphic(Paths.image('menus/replay/placeholder'));
		placeholder.setGraphicSize(320);
		placeholder.updateHitbox();
		placeholder.x += 15;
		placeholder.y += 32;
		infoBoxGroup.add(placeholder);

		var infoDivider = new MoonSprite().makeGraphic(320, 4, FlxColor.GRAY);
		infoDivider.x = 15;
		infoDivider.y += placeholder.height + 104;
		infoDivider.antialiasing = true;
		infoBoxGroup.add(infoDivider);

		songName = new FlxText();
		songName.x = 15;
		songName.y += placeholder.height + 48;
		songName.setFormat(Paths.font('phantomuff/full.ttf'), 24, CENTER);
		songName.antialiasing = true;
		infoBoxGroup.add(songName);

		chartName = new FlxText();
		chartName.x = 15;
		chartName.y = placeholder.height + 78;
		chartName.setFormat(Paths.font('phantomuff/full.ttf'), 16, CENTER);
		chartName.color = FlxColor.GRAY;
		chartName.antialiasing = true;
		infoBoxGroup.add(chartName);

		replayRank = new FreeplayRank();
		replayRank.x = 285;
		replayRank.y += placeholder.height + 4;
		replayRank.setRank('PERFECT-GOLD');
		replayRank.updateHitbox();
		infoBoxGroup.add(replayRank);

		createButtons();

		var yy = placeholder.height + 124;
		for (i in 0...5)
		{
			var info = new FlxText();
			info.x = 15;
			info.y = yy + 24 * i;
			info.setFormat(Paths.font('phantomuff/full.ttf'), 16, LEFT);
			info.color = FlxColor.GRAY;
			info.antialiasing = true;
			infoBoxGroup.add(info);
			info.text = 'Replay Code: 16704595';

			replayInfo.push(info);
		}

		changeSelection(0);
	}

	function createButtons()
	{
		playButton = new ReplayButton(165, 48, 'Play Replay');
		playButton.x = 10;
		playButton.y += infoBoxGroup.height - playButton.height - 68;
		infoBoxGroup.add(playButton);

		editButton = new ReplayButton(165, 48, 'Edit Replay');
		editButton.x = 20 + playButton.width;
		editButton.y += infoBoxGroup.height - editButton.height - 68;
		infoBoxGroup.add(editButton);

		deleteButton = new ReplayButton(330, 48, 'Delete Replay', 0xFF600000);
		deleteButton.members[2].x = 84;
		deleteButton.x = 10;
		deleteButton.y += infoBoxGroup.height - deleteButton.height - 10;
		deleteButton.deselectColors[1] = 0xFFFF0000;
		deleteButton.setDeselect();
		deleteButton.selectColors[0] = 0xFFFF0000;
		infoBoxGroup.add(deleteButton);
	}

	var curSelected:Int = 0;

	function changeSelection(change:Int = 0):Void
	{
		curSelected = FlxMath.wrap(curSelected + change, 0, replays.length - 1);
		Paths.playSFX('ui/scrollMenu.ogg');

		songName.text = replays[curSelected].title.text;
		chartName.text = replays[curSelected].chartDisplayName;
		replayInfo[0].text = 'Replay Code: ${replays[curSelected].rpCode}';
		replayInfo[1].text = 'Recorded: ${replays[curSelected].recordDate}';
		replayInfo[2].text = 'MaxCombo: ${replays[curSelected].maxCombo}';
		replayInfo[3].text = 'Score: ${replays[curSelected].score}';
		replayInfo[4].text = 'Misses: ${replays[curSelected].misses}';
		if (replays[curSelected].acc != null)
		{
			final rank = Timings.getRank(replays[curSelected].acc).rank;
			replayRank.setRank(rank);
			replayRank.updateHitbox();
		}
		else
			replayRank.visible = false;

		for (i in 0...replays.length)
		{
			if (i == curSelected) replays[i].select();
			else
				replays[i].deselect();
		}
	}

	function changeButtonSelection(change:Int = 0, ?lineChange:Int = 0):Void
	{
		pointer[0] = FlxMath.wrap(pointer[0] + change, 0, 1);
		pointer[1] = FlxMath.wrap(pointer[1] + lineChange, 0, 1);
		Paths.playSFX('ui/scrollMenu.ogg');

		playButton.setDeselect();
		editButton.setDeselect();
		deleteButton.setDeselect();

		getButton()?.setSelect();
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!inSubMenu)
		{
			if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
			if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
		}
		else
		{
			if (MoonInput.justPressed(UI_LEFT)) changeButtonSelection(1);
			if (MoonInput.justPressed(UI_RIGHT)) changeButtonSelection(-1);
			if (MoonInput.justPressed(UI_DOWN)) changeButtonSelection(0, 1);
			if (MoonInput.justPressed(UI_UP)) changeButtonSelection(0, -1);
		}

		if (MoonInput.justPressed(ACCEPT))
		{
			if (!inSubMenu)
			{
				changeButtonSelection();
				inSubMenu = true;
			}
			else
			{
				if (pointer[1] == 1)
				{
					deleteReplay();
					backFromSubMenu();
					return;
				}

				switch (pointer[0])
				{
					case 0: // play
						loadReplay();
					case 1:
						return;
				}

				backFromSubMenu();
			}
		}

		if (MoonInput.justPressed(BACK))
		{
			if (inSubMenu)
			{
				backFromSubMenu();
				return;
			}

			close();
		}
	}

	function loadReplay()
	{
		final curThingie = replays[curSelected];
		PlayState.songData = {
			song: curThingie.id,
			difficulty: curThingie.difficulty,
			mix: curThingie.mix
		};

		final rep = PlayState.loadReplay('data/replays/${curThingie.replayPath}.mrp');
		if (rep != null) FlxG.switchState(() -> new PlayState(rep));

		if (FlxG.sound.music != null) FlxG.sound.music.stop();
	}

	function deleteReplay()
	{
		final curThingie = replays[curSelected];

		sys.FileSystem.deleteFile('assets/data/replays/${curThingie.replayPath}.mrp');
		replays.remove(curThingie);
		curThingie.destroy();

		if (replays.length == 0)
		{ // just close the substate for now, we should add a proper "No Replays!" check later
			close();
			return;
		}
		changeSelection(-1);

		reorderReplays();
	}

	function getButton():ReplayButton
	{
		if (pointer[1] == 1) // on the bottom line! (delete)
			return deleteButton;

		switch (pointer[0])
		{
			case 0: // play
				return playButton;
			case 1: // edit
				return editButton;
		}

		return null;
	}

	function backFromSubMenu()
	{
		inSubMenu = false;
		playButton.setDeselect();
		editButton.setDeselect();
		deleteButton.setDeselect();
		return;
	}

	function reorderReplays()
	{
		for (i in 0...replays.length)
		{
			replays[i].y = 52 + 84 * i;
		}
	}
}
