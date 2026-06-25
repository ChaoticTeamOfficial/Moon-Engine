package moon.menus;

import moon.game.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.game.obj.judgements.*;

class Offset extends FlxSubState
{
	var conductor:Conductor;
	var offsetDebug:FlxText;
	var lines:FlxGroup;
	var beatToLine:Map<Int, MoonSprite> = [];
	var centerIndicator:MoonSprite;
	var bar:RoundBar;
	var hitX:Float;
	var speed:Float = 400;
	var lineW:Int = 6;
	var lineH:Int = 80;

	public function new()
	{
		super();

		if (PlayState.instance != null) this.camera = PlayState.instance.camALT;

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/background'));
		add(bg);
		bg.alpha = 0.0001;
		FlxTween.tween(bg, {
			alpha: 1
		}, 0.9);

		var calibrate = new FlxText(0, 64, -1, "CALIBRATE YOUR GAME!");
		calibrate.setFormat(Paths.font('phantomuff/difficulty.ttf'), 34, CENTER);
		calibrate.antialiasing = true;
		calibrate.screenCenter(X);
		calibrate.alpha = 0.00001;
		add(calibrate);
		calibrate.y += 16;
		FlxTween.tween(calibrate, {
			y: calibrate.y - 16,
			alpha: 1
		}, 1, {
			startDelay: 0.2,
			ease: FlxEase.quadInOut
		});

		var instructText = new FlxText(
			0,
			calibrate.y + 60,
			FlxG.width,
			"Tap space to the beat to calibrate your game!\nyour offset will be calibrated to the beat you're tapping."
		);
		instructText.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE, CENTER);
		instructText.antialiasing = true;
		add(instructText);
		instructText.alpha = 0.00001;
		FlxTween.tween(instructText, {
			alpha: 1
		}, 1, {
			startDelay: 0.7,
			ease: FlxEase.quadInOut
		});

		var goback = new FlxText(0, 0, FlxG.width, "Press [ESC] to cancel");
		goback.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE, CENTER);
		goback.antialiasing = true;
		add(goback);
		goback.alpha = 0.00001;
		FlxTween.tween(goback, {
			alpha: 0.5
		}, 2, {
			startDelay: 2,
			ease: FlxEase.quadInOut
		});
		goback.y = FlxG.height - goback.height - 96;

		bar = new RoundBar(0, goback.y + 48, LEFT_TO_RIGHT, 600, 10, null, null, 0, 100);
		bar.createFilledBar(FlxColor.BLACK, FlxColor.WHITE);
		bar.screenCenter(X);
		add(bar);
		bar.value = 0;
		bar.alpha = 0.0001;
		FlxTween.tween(bar, {
			alpha: 1
		}, 2, {
			startDelay: 2,
			ease: FlxEase.quadInOut
		});

		offsetDebug = new FlxText();
		offsetDebug.setFormat(Paths.font('phantomuff/full.ttf'), 24, CENTER);
		offsetDebug.antialiasing = true;
		add(offsetDebug);
		setText('Please wait...');
		offsetDebug.alpha = 0.00001;
		FlxTween.tween(offsetDebug, {
			alpha: 0.6
		}, 2, {
			startDelay: 0.4,
			ease: FlxEase.quadInOut
		});
		// offsetDebug.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);

		hitX = FlxG.width / 2;

		lines = new FlxGroup();
		add(lines);

		centerIndicator = new MoonSprite(hitX - (lineW * 4) / 2, FlxG.height / 2 - lineH / 2).makeGraphic(lineW * 4, lineH, FlxColor.TRANSPARENT);
		centerIndicator.alpha = 0.00001;
		FlxSpriteUtil.drawRoundRect(centerIndicator, 0, 0, lineW * 4, lineH, 16, 16, FlxColor.WHITE);
		add(centerIndicator);
		FlxTween.tween(centerIndicator, {
			alpha: 0.6
		}, 1, {
			startDelay: 3,
			ease: FlxEase.quadInOut
		});

		MoonUtils.playGlobalMusic('menus/feelthetrack', true);
		conductor = new Conductor(120);

		conductor.onBeat.add(beat ->
		{
			// trace(beat, "DEBUG");
			if (allowPress) progress += 1.62;
			switch (beat)
			{
				case 8:
					linesAlpha = 1;
				case 12:
					setText('3');
				case 13:
					setText('2');
				case 14:
					setText('1');
				case 15:
					setText('Go!');
				case 16:
					setText('(Press on the beat!)');
					allowPress = true;
				case 80:
					linesAlpha = 0;
					allowPress = false;
					setText('All done - Your offset is now ${Std.int(averageOffset)}ms.');
					MoonSettings.setSetting("Note Offset", Std.int(averageOffset));
				case 88:
					exit();
			}
		});
	}

	var allowPress:Bool = false;
	var linesAlpha:Float = 0;
	var progress:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		bar.value = FlxMath.lerp(bar.value, progress, elapsed * 6);

		if (FlxG.sound.music != null) conductor.time = FlxG.sound.music.time;

		if (FlxG.sound.music != null && FlxG.sound.music.playing)
		{
			var curBeatInt:Int = Math.floor(conductor.curBeat);
			for (n in (curBeatInt - 10)...(curBeatInt + 11))
			{
				final deltaMs:Float = (conductor.offsetTime + (conductor.beatOffset + n) * conductor.crochet) - conductor.time + averageOffset;
				if (Math.abs(deltaMs) > 10000) continue;

				final x:Float = hitX - speed * (deltaMs / 1000);

				if (x < -100 || x > FlxG.width + 100)
				{
					if (beatToLine.exists(n))
					{
						var line:MoonSprite = beatToLine.get(n);
						lines.remove(line, true);
						line.destroy();
						beatToLine.remove(n);
					}
					continue;
				}

				var line:MoonSprite;
				if (!beatToLine.exists(n))
				{
					line = new MoonSprite().makeGraphic(lineW, lineH, FlxColor.TRANSPARENT);
					FlxSpriteUtil.drawRoundRect(line, 0, 0, lineW, lineH, 16, 16, FlxColor.WHITE);
					line.screenCenter(Y);
					line.antialiasing = true;
					lines.add(line);
					line.alpha = 0;
					beatToLine.set(n, line);
				}
				else
					line = beatToLine.get(n);

				line.x = FlxMath.lerp(line.x, x - lineW / 2, elapsed * 16);
			}
		}

		for (line in lines) if (line != null) cast(line, MoonSprite).alpha = FlxMath.lerp(cast(line, MoonSprite).alpha, linesAlpha, elapsed * 2);

		centerIndicator.scale.x = centerIndicator.scale.y = FlxMath.lerp(centerIndicator.scale.x, 1, elapsed * 16);

		if (MoonInput.justPressed(ACCEPT) && allowPress) calculateOffset();

		if (MoonInput.justPressed(BACK)) exit();
	}

	private var totalBeats:Int = 0;
	private var cumulativeOffset:Float = 0;
	private var averageOffset:Float = 0;

	function calculateOffset():Void
	{
		// stole this from rootbound :)
		totalBeats++;

		final beatLength = 60000 / conductor.bpm;
		final nearestBeatTime = Math.round(conductor.time / beatLength) * beatLength;
		var offset = conductor.time - nearestBeatTime;

		if (offset > beatLength / 2) offset -= beatLength;
		else if (offset < -beatLength / 2) offset += beatLength;

		cumulativeOffset += offset;
		averageOffset = cumulativeOffset / totalBeats;

		centerIndicator.scale.set(1.1, 1.1);
		setText('${Std.int(averageOffset)}ms...');
	}

	function setText(text:String)
	{
		offsetDebug.alpha = 0.6;
		offsetDebug.text = text;
		// offsetDebug.text = "Offset: " + offset + "\nCumulative Offset: " + cumulativeOffset + "\nAverage Offset: " + averageOffset;
		offsetDebug.screenCenter();
		offsetDebug.y -= 96;
	}

	function exit()
	{
		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		FlxG.state.openSubState(new Settings(true));
		close();
	}
}
