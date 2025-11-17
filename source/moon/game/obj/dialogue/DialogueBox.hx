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
	 * The current dialogue skin.
	 */
	public var skin:String = '';

	/**
	 * Whether or not will the dialogue box automatically proceed. If true, player inputs will no longer count.
	 */
	public var autoProceed:Bool = false;

	private var box:MoonSprite;
	private var typer:TextTyper;

	/**
	 * Creates the Dialogue Box.
	 * @param x X Position.
	 * @param y Y Position.
	 * @param skin The dialogue box skin.
	 */
	public function new(x:Float = 0, y:Float = 0, skin:String = 'default', dialoguePath:String)
	{
		super(x, y);
		this.skin = skin;

		data = Dialogue.getDialogue(dialoguePath);
		//trace(data);

		for(dialogue in data.lines)
		{
			if(!characters.contains(dialogue.character))
			{
				characters.push(dialogue.character);

				//this is the most dumb shit i've done
				var tryData:Array<Int> = [];
				final ogdata = DialogueCharacter.getChar(dialogue.character);
				final chardata = Paths.JSON('characters/${dialogue.character}/data');
				try{tryData =  (ogdata == null) ? chardata.healthbarColors : ogdata.color ?? chardata.healthbarColors;}
				catch(e){tryData = [255,255,255];}

				charColors.set(dialogue.character, FlxColor.fromRGB(tryData[0], tryData[1], tryData[2]));
			}
		}

		//trace(characters);

		box = new MoonSprite().loadGraphic(Paths.image('ingame/dialogue-box/$skin/box'));
		add(box);

        typer = new TextTyper(64, 32);
        typer.defaultFont = 'vcr.ttf';
        typer.defaultSize = 28;
        typer.defaultColor = FlxColor.WHITE;
        typer.lineHeight = 30;
        typer.lineWidth = box.width - typer.x;
        typer.spacing = -3;
        add(typer);

		this.visible = false;
	}

	private var curIdx = 0;
	private var charColors:Map<String, FlxColor> = [];
	override public function update(elapsed:Float)
	{
		if(!visible) return;
		super.update(elapsed);

		if(!autoProceed)
		{
			if(MoonInput.justPressed(ACCEPT) && curIdx < data.lines.length - 1){
				curIdx++;
				show(curIdx);
			}
		}
	}

	public function show(index:Int = 0)
	{
		final line = data.lines[index];

		//TODO: make this better...
        final schema:Map<String, Array<String>> = [
            "wave" => ["intensity", "frequency", "delay"],
            "shake" => ["intensity"],
            "size" => ["size"],
            "color" => ["color"],
            "font" => ["path"]
        ];

        final parsed = DialogueParser.parseTaggedText(line.text, schema);

        box.color = charColors.get(line.character);

		typer.text = parsed.text ?? '';
		typer.events = parsed.events ?? [];
		typer.speed = line.speed ?? 16;
		typer.resetTyper();

		//typer.onType.addOnce(()->{
		for(ye in typer.members)
			if(Std.isOfType(ye, FlxText))
				cast(ye, FlxText).setBorderStyle(SHADOW, charColors.get(line.character), 2);
		//});
	}
}