package moon.game.obj.dialogue;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import moon.backend.data.Dialogue.DialogueEvent;
import moon.backend.data.Dialogue.DialogueParser;

using StringTools;

/**
 * A neato dialogue box. status: wip
 */
class DialogueBox extends FlxSpriteGroup
{
	/**
	 * The data loaded for the current dialogue.
	 */
	public var data:Dialogue;

	/**
	 * An array containing all the characters on this dialogue.
	 */
	public var characters:Array<String> = [];

	/**
	 * An map contaning all the character portraits.
	 */
	public var chars:Map<String, Portrait> = [];

	/**
	 * The group the portraits are added on.
	 */
	public var portraitsGrp:FlxSpriteGroup = new FlxSpriteGroup();

	/**
	 * The current dialogue skin.
	 */
	public var skin:String = '';

	/**
	 * Whether or not will the dialogue box automatically proceed. If true, player inputs will no longer count.
	 */
	public var autoProceed:Bool = false;

	private var box:MoonSprite;
	private var typer:TextTyper;
	private var nameplate:FlxText;

	public function new(x:Float = 0, y:Float = 0, skin:String = 'default', dialoguePath:String)
	{
		super(x, y);
		this.skin = skin;
		portraitsGrp.setPosition(x, y);

		data = Dialogue.getDialogue(dialoguePath);

		for (dialogue in data.lines)
		{
			if (dialogue.character == null) dialogue.character = 'Narrator';
			if (!characters.contains(dialogue.character))
			{
				characters.push(dialogue.character);
				var portrait = new Portrait(dialogue.character);
				if (portrait.strID != 'noAnim') portraitsGrp.add(portrait);
				portrait.visible = false;
				chars.set(dialogue.character, portrait);
			}
		}

		box = new MoonSprite().loadGraphic(Paths.image('ingame/dialogue-box/$skin/box'));
		add(box);

		typer = new TextTyper(64, 32);
		typer.defaultFont = 'CRIKEY SQUATS REGULAR.TTF';
		typer.defaultSize = 24;
		typer.defaultColor = FlxColor.WHITE;
		typer.lineHeight = 30;
		typer.lineWidth = box.width - typer.x - typer.defaultSize;
		typer.spacing = -3;

		typer.typingAnimation = FADE;
		add(typer);

		for (a => c in chars)
		{
			typer.onType.add(() ->
			{
				if (c.char == data.lines[curIdx].character) c.playBeep();
			});
		}

		nameplate = new FlxText(64, 0, 0, '');
		nameplate.setFormat(Paths.font('CRIKEY SQUATS REGULAR.TTF'), 48, FlxColor.WHITE);
		add(nameplate);
		nameplate.y = -nameplate.height + 48;

		this.visible = false;
	}

	private var curIdx = 0;

	override public function update(elapsed:Float)
	{
		if (!visible) return;
		super.update(elapsed);

		if (!autoProceed)
		{
			if (MoonInput.justPressed(ACCEPT) && curIdx < data.lines.length - 1)
			{
				curIdx++;
				show(curIdx);
			}
		}
	}

	public function show(index:Int = 0)
	{
		portraitsGrp.camera = this.camera;
		final line = data.lines[index];
		final char = chars.get(line.character);

		final schema:Map<String, Array<String>> = [
			"wave" => ["intensity", "frequency", "delay"],
			"shake" => ["intensity"],
			"bounce" => ["height", "duration", "stiffness"],
			"jitter" => ["intensity", "frequency"],
			"fadein" => ["duration"],
			"rainbow" => ["speed", "spread"],
			"shadow" => ["color", "size"],
			"outline" => ["color", "size"],
			"size" => ["size"],
			"color" => ["color"],
			"font" => ["path"]
		];

		final parsed = DialogueParser.parseTaggedText(line.text, schema);
		final colorr:FlxColor = (line.color != null) ? FlxColor.fromRGB(
			line?.color[0] ?? 255,
			line?.color[1] ?? 255,
			line?.color[2] ?? 255
		) : (char != null) ? char.getColor() : 0xFFFFFFFF;

		box.color = colorr;

		// TODO: Make box and typer default properties softcoded by a json!
		nameplate.text = char.data.displayName;
		nameplate.setBorderStyle(SHADOW, colorr, 4);

		typer.text = parsed.text ?? '';
		typer.events = parsed.events ?? [];
		typer.speed = line.speed ?? 16;
		typer.antialiasing = true;
		typer.resetTyper();

		// for (ye in typer.members) if (Std.isOfType(ye, FlxText)) cast(ye, FlxText).setBorderStyle(SHADOW, colorr, 2);

		for (name => charac in chars)
		{
			// beep :3
			charac.resetBeeps();
			charac.alpha = (name == line.character) ? 1 : 0.5;
		}

		if (char != null && char.strID != 'noAnim')
		{
			char.playAnim(line.expression, true);
			char.visible = true;
			char.doAnim(line.anim ?? NONE);
		}
	}
}
