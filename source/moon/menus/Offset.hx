package moon.menus;

import moon.game.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.game.obj.judgements.*;

class Offset extends FlxSubState
{
	var conductor:Conductor;
	var offsetDebug:FlxText;
	public function new()
	{
		super();

		if(PlayState.instance != null)
			this.camera = PlayState.instance.camALT;

		if(FlxG.sound.music != null){
			FlxG.sound.music.stop();
			FlxG.sound.music.destroy();
		}

		var bg = new MoonSprite().loadGraphic(Paths.image('menus/background'));
		add(bg);
		bg.alpha = 0.0001;
		FlxTween.tween(bg, {alpha: 1}, 0.9);

        var calibrate = new FlxText(0, 164, -1, "CALIBRATE YOUR GAME!");
        calibrate.setFormat(Paths.font('phantomuff/difficulty.ttf'), 34, CENTER);
        calibrate.antialiasing = true;
        calibrate.screenCenter(X);
        calibrate.alpha = 0.00001;
        add(calibrate);
        calibrate.y += 16;
        FlxTween.tween(calibrate, {y: calibrate.y - 16, alpha: 1}, 1, {startDelay: 0.2, ease: FlxEase.quadInOut});

        offsetDebug = new FlxText();
        offsetDebug.setFormat(Paths.font('phantomuff/full.ttf'), 24, CENTER);
        offsetDebug.antialiasing = true;
        add(offsetDebug);
        //offsetDebug.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);

		MoonUtils.playGlobalMusic('menus/offsetPlaceholder-88', true);
		conductor = new Conductor(88);

		setText('Please wait...');
		conductor.onBeat.add(beat ->{
			trace(beat, "DEBUG");

			switch(beat)
			{
				case 16: 
					setText('(Press on the beat!)');
					allowPress = true;
				case 48: 
					allowPress = false;
					setText('All done - Your offset is now ${Std.int(averageOffset)}ms.');
					MoonSettings.setSetting("Note Offset", Std.int(averageOffset));
				case 56: exit();
			}
		});
	}

	var allowPress:Bool = false;
	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if(FlxG.sound.music != null)
        	conductor.time = FlxG.sound.music.time;

		//TODO: MAKE MOON INPUT HAVE A "ANY" FIELD.
		if(FlxG.keys.justPressed.ANY && allowPress)
			calculateOffset();

		if(MoonInput.justPressed(BACK)) exit();
	}

	private var totalBeats:Int = 0;
	private var cumulativeOffset:Float = 0;
	private var averageOffset:Float = 0;
	function calculateOffset():Void
	{
		//stole this from rootbound :)
		totalBeats++;

		final beatLength = 60000 / conductor.bpm;
		final nearestBeatTime = Math.round(conductor.time / beatLength) * beatLength;
		var offset = conductor.time - nearestBeatTime;

		if (offset > beatLength / 2) offset -= beatLength;
		else if (offset < -beatLength / 2) offset += beatLength;

		cumulativeOffset += offset;
		averageOffset = cumulativeOffset / totalBeats;

		setText('${Std.int(averageOffset)}ms...');
	}

	function setText(text:String)
	{
		offsetDebug.alpha = 0.6;
		offsetDebug.text = text;
		//offsetDebug.text = "Offset: " + offset + "\nCumulative Offset: " + cumulativeOffset + "\nAverage Offset: " + averageOffset;
		offsetDebug.screenCenter();
		offsetDebug.y -= 32;
	}

	function exit()
	{
		if(FlxG.sound.music != null)
			FlxG.sound.music.stop();

		FlxG.state.openSubState(new Settings(true));
		close();
	}
}