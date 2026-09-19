package moon.menus;

class CrashHandler extends FlxState
{
	public static var lastError:String = "Unknown error";
	public static var lastStack:String = "";

	var canReturn:Bool = false;

	public function new(?error:String, ?stack:String)
	{
		super();
		if (error != null) lastError = error;
		if (stack != null) lastStack = stack;
	}

	override public function create()
	{
		super.create();

		Global.allowInputs = true;
		Global.clearScriptList();

		var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF111111);
		add(bg);

		var title = new FlxText(0, 48, FlxG.width, "CRASH!");
		title.setFormat(Paths.font('phantomuff/difficulty.ttf'), 64, 0xFFFF4444, CENTER);
		title.setBorderStyle(OUTLINE, FlxColor.BLACK, 4);
		add(title);

		var subtitle = new FlxText(0, 120, FlxG.width, "An unexpected error occurred.");
		subtitle.setFormat(Paths.font('tardling/Solid/Tardling-Solid.ttf'), 32, FlxColor.WHITE, CENTER);
		subtitle.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(subtitle);

		var errorBox = new MoonSprite(40, 180).makeGraphic(FlxG.width - 80, 180, 0xFF1A1A1A);
		add(errorBox);

		var errorLabel = new FlxText(50, 190, FlxG.width - 100, "Error:");
		errorLabel.setFormat(Paths.font('phantomuff/full.ttf'), 24, 0xFFFF8888, LEFT);
		add(errorLabel);

		var errorText = new FlxText(50, 224, FlxG.width - 100, lastError);
		errorText.setFormat(Paths.font('phantomuff/full.ttf'), 20, FlxColor.WHITE, LEFT);
		add(errorText);

		var stackBox = new MoonSprite(40, 380).makeGraphic(FlxG.width - 80, 220, 0xFF1A1A1A);
		add(stackBox);

		var stackLabel = new FlxText(50, 390, FlxG.width - 100, "Call stack:");
		stackLabel.setFormat(Paths.font('phantomuff/full.ttf'), 20, 0xFFAAAAAA, LEFT);
		add(stackLabel);

		var stackText = new FlxText(50, 420, FlxG.width - 100, lastStack != "" ? lastStack : "(no stack available)");
		stackText.setFormat(Paths.font('phantomuff/full.ttf'), 16, 0xFFCCCCCC, LEFT);
		add(stackText);

		var prompt = new FlxText(0, FlxG.height - 80, FlxG.width, "Press ENTER to return to the menu");
		prompt.setFormat(Paths.font('phantomuff/full.ttf'), 24, 0xFFFFFF88, CENTER);
		prompt.setBorderStyle(OUTLINE, FlxColor.BLACK, 2);
		add(prompt);

		new FlxTimer().start(0.4, _ -> canReturn = true);

		if (FlxG.sound.music != null)
		{
			FlxG.sound.music.stop();
			FlxG.sound.music = null;
		}
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (canReturn && (MoonInput.justPressed(ACCEPT) || FlxG.keys.justPressed.ENTER))
		{
			canReturn = false;
			FlxTransitionableState.skipNextTransIn = FlxTransitionableState.skipNextTransOut = true;
			FlxG.switchState(() -> new MainMenu());
		}
	}
}
