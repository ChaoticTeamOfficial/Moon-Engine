package moon.toolkit.level_editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.backend.Conductor;
import moon.backend.data.Chart;

/**
 * A mini gameplay preview window for the level editor
 * Shows a scaled-down version of the actual gameplay
 */
class MiniPlayer extends FlxGroup
{
	public static var instance:MiniPlayer;
	// Display settings
	public static final MINI_WIDTH:Int = 580;
	public static final MINI_HEIGHT:Int = 326;
	public static final SCALE:Float = 0.5;

	// Components
	public var background:FlxSprite;
	// Position
	public var targetX:Float = 108;
	public var targetY:Float = 48;

	private var _internalCam:MoonCamera;

	public function new(x:Float, y:Float, chart:Chart, conductor:Conductor, playback:Song)
	{
		super();
		instance = this;

		targetX = x;
		targetY = y;

		background = new FlxSprite(x - 4, y - 4);
		background.makeGraphic(MINI_WIDTH + 8, MINI_HEIGHT + 8, FlxColor.BLACK);
		add(background);

		_internalCam = new MoonCamera(Std.int(x), Std.int(y), MINI_WIDTH, MINI_HEIGHT);
		_internalCam.bgColor = FlxColor.GRAY;
		FlxG.cameras.add(_internalCam, false);

		_internalCam.scroll.set(0, 0);
		_internalCam.zoom = 0.5;
		refreshChart();

		// FlxG.watch.add(playField.conductor, "time");
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// playField.conductor.time = conductor.time;
	}

	public function refreshChart():Void
	{
	}

	override public function destroy():Void
	{
		FlxG.cameras.remove(_internalCam);
		_internalCam.destroy();
		super.destroy();
	}
}
