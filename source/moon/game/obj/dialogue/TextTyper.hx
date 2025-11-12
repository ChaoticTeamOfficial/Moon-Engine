package moon.game.obj.dialogue;

import flixel.text.FlxText;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import moon.backend.data.Dialogue.DialogueEvent;
import moon.backend.data.Dialogue.DialogueParser;
import flixel.util.FlxSignal;

using StringTools;

/**
 * A text typer that reveals text character by character, with support for EFFECTS!
 */
class TextTyper extends FlxSpriteGroup
{
    public var defaultFont:String = "vcr.ttf";
    public var defaultSize:Int = 32;
    public var defaultColor:Int = 0xFFFFFFFF;
    public var lineHeight:Float = 40;

    public var text:String;
    public var events:Array<DialogueEvent>;
    public var speed:Float = 30;

    private var chars:Array<CharData> = [];
    private var currentIndex:Int = 0;
    private var timer:Float = 0;
    private var finished:Bool = false;

    public final onFinish:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();
    public final onType:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

    /**
	 * Creates a TextTyper instance.
	 * @param x X Position.
	 * @param y Y Position.
	 * @param text The text to be displayed.
	 * @param events The array containing all events.
	 * @param speed The typer speed.
	 */
    public function new(x:Float = 0, y:Float = 0, text:String, events:Array<DialogueEvent>, ?speed:Float = 30)
    {
        super(x, y);
        this.text = text;
        this.events = events ?? [];
        this.speed = speed;

        buildCharacters();
    }

    public function resetTyper():Void {
        clear();
        chars = [];
        currentIndex = 0;
        timer = 0;
        finished = false;
        buildCharacters();
    }

    public function finish():Void {
        for (cd in chars) {
            cd.sprite.visible = true;
            cd.appearTime = FlxG.game.ticks / 1000;
        }
        currentIndex = chars.length;
        if (!finished)
        {
            finished = true;
            onFinish.dispatch();
        }
    }

    private function buildCharacters():Void {
        var curX:Float = 0;
        var curY:Float = 0;
        var lineChars:Array<CharData> = [];

        for (i in 0...text.length) {
            final ch:String = text.charAt(i);
            if (ch == "\n") {
                alignLine(lineChars);
                lineChars = [];
                curX = 0;
                curY += lineHeight;
                continue;
            }

            final props = { font: defaultFont, size: defaultSize, color: defaultColor };
            final effs:Array<TextEffect> = [];
            collectEffects(i, props, effs);

            var sprite = new FlxText(0, 0, 0, ch, props.size);
            sprite.font = Paths.font(props.font);
            sprite.color = props.color;
            sprite.visible = false;
            add(sprite);

            var cd:CharData = {
                sprite: sprite,
                baseX: curX,
                baseY: curY,
                effects: effs,
                appearTime: 0,
                index: i
            };

            chars.push(cd);
            lineChars.push(cd);
            curX += sprite.width;
        }

        alignLine(lineChars);
        for(char in members) char.active = false;
    }

    private function alignLine(line:Array<CharData>):Void
    {
        if (line.length == 0) return;
        var maxH = 0.0;
        for (c in line) maxH = Math.max(maxH, c.sprite.height);
        for (c in line)
        {
            var diff = maxH - c.sprite.height;
            c.sprite.y += diff;
            c.baseY += diff;
        }
    }

    private function collectEffects(index:Int, props:{font:String, size:Int, color:Int}, effs:Array<TextEffect>):Void
    {
    	// this parses effects
    	// not really 'parses', rather adds them to the list
        for (ev in events)
        {
            if (ev.range.start <= index && index < ev.range.end)
            {
                switch (ev.name.toLowerCase())
                {
                    case "shake": effs.push(new ShakeEffect(ev.values));
                    case "wave": effs.push(new WaveEffect(ev.values));
                    case "color":
                        final colorVal:Dynamic = Reflect.field(ev.values, "color") != null ? Reflect.field(ev.values, "color") : ev.values;
                        props.color = parseColor(colorVal);
                    case "font":
                        var fontVal:Dynamic = Reflect.field(ev.values, "path") != null ? Reflect.field(ev.values, "path") : ev.values;
                        props.font = Std.string(fontVal);
                    case "size":
                        props.size = Std.int(Reflect.field(ev.values, "size") != null ? Reflect.field(ev.values, "size") :
                            (Std.isOfType(ev.values, Float) || Std.isOfType(ev.values, Int) ? ev.values : defaultSize));
                    default:
                        trace('Unknown effect: ${ev.name}', "WARNING");
                }
            }
        }
    }

    // well this sucks
    // but better compatibility I guess
    final colorsMap:Map<String, FlxColor> = [
    	'black' => FlxColor.BLACK, 'blue' => FlxColor.BLUE, 'brown' => FlxColor.BROWN,
    	'cyan' => FlxColor.CYAN, 'gray' => FlxColor.GRAY, 'green' => FlxColor.GREEN,
    	'lime' => FlxColor.LIME, 'magenta' => FlxColor.MAGENTA, 'orange' => FlxColor.ORANGE,
    	'pink' => FlxColor.PINK, 'purple' => FlxColor.PURPLE, 'red' => FlxColor.RED,
    	'white' => FlxColor.WHITE, 'yellow' => FlxColor.YELLOW, 'transparent' => FlxColor.TRANSPARENT
    ];

    private function parseColor(val:Dynamic):Int {
        if (Std.isOfType(val, Int)) return val;
        if (Std.isOfType(val, String)) {
            var str:String = val;
            if (str.startsWith("#")) return Std.parseInt("0x" + str.substr(1));
        	return colorsMap.get(str.toLowerCase());
        }
        return defaultColor;
    }

    override public function update(elapsed:Float):Void {
        super.update(elapsed);

        // typing behavior
        if (currentIndex < chars.length) {
            timer += elapsed;
            var charTime = 1 / speed;
            while (timer >= charTime) {
                final cd = chars[currentIndex];
                //trace('typing: ${cd.sprite.text}');

                cd.sprite.visible = true;
                cd.appearTime = FlxG.game.ticks / 1000;
                onType.dispatch();

                currentIndex++;
                timer -= charTime;
                if (currentIndex >= chars.length && !finished) {
                    finished = true;
                    onFinish.dispatch();
                }
            }
        }

        // dynamic updates
        final globalTime = FlxG.game.ticks / 1000;
        for (cd in chars) {
            if (!cd.sprite.visible) continue;
            cd.sprite.x = cd.baseX + this.x;
            cd.sprite.y = cd.baseY + this.y;
            for (eff in cd.effects)
                eff.applyDynamic(cd.sprite, elapsed, globalTime, globalTime - cd.appearTime);
        }
    }
}

/** Character metadata */
typedef CharData = {
    sprite:FlxText,
    baseX:Float,
    baseY:Float,
    effects:Array<TextEffect>,
    appearTime:Float,
    index:Int
}
