package moon.game.obj.dialogue;

import flixel.group.FlxSpriteGroup;
import moon.backend.data.Dialogue.DialogueEvent;
import moon.backend.data.Dialogue.DialogueParser;
import flixel.util.FlxSignal;

import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

using StringTools;

/**
 * A text typer that reveals text character by character, with support for EFFECTS!
 */
class TextTyper extends FlxSpriteGroup
{
    /**
     * The default font for the typer.
     */
    public var defaultFont:String = "";

    /**
     * The default text size.
     */
    public var defaultSize:Int = 32;

    /**
     * The default text color.
     */
    public var defaultColor:Int = 0xFFFFFFFF;

    /**
     * The default line height.
     */
    public var lineHeight:Float = 40;

    /**
     * The default line width.
     */
    public var lineWidth:Float = 500;

    /**
     * The spacing between each text character.
     */
    public var spacing:Float = 0;

    /**
     * The current text that will be displayed.
     */
    public var text:String;

    /**
     * A list of events that will happen on this text.
     */
    public var events:Array<DialogueEvent>;

    /**
     * The speed for this text.
     * TODO: maybe change it to work differently?
     */
    public var speed:Float = 30;

    private var chars:Array<CharData> = [];
    private var currentIndex:Int = 0;
    private var timer:Float = 0;
    private var finished:Bool = false;

    private var _textSprite:MoonSprite;

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
    public function new(x:Float = 0, y:Float = 0, ?text:String, ?events:Array<DialogueEvent>, ?speed:Float = 30)
    {
        super(x, y);
        this.text = text;
        this.events = events ?? [];
        this.speed = speed;

        //buildCharacters();
    }

    public function resetTyper():Void
    {
        clear();

        for (cd in chars)
        {
            if (cd.glyph != null) cd.glyph.dispose();
            if (cd.sprite != null) cd.sprite.destroy();
        }

        chars = [];
        currentIndex = 0;
        timer = 0;
        finished = false;
        _textSprite = null;

        buildCharacters();
    }

    public function finish():Void
    {
        for (cd in chars)
        {
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

    private function buildCharacters():Void
    {
        var curX:Float = 0;
        var curY:Float = 0;
        var lineChars:Array<CharData> = [];

        for (i in 0...text.length)
        {
            final ch:String = text.charAt(i);
            if (ch == "\n" || curX > lineWidth)
            {
                alignLine(lineChars);
                lineChars = [];
                curX = 0;
                curY += lineHeight;
                continue;
            }

            final props = {font: defaultFont, size: defaultSize, color: defaultColor};
            final effs:Array<TextEffect> = [];
            collectEffects(i, props, effs);

            final temp = new FlxText(0, 0, 0, ch, props.size);
            temp.font = Paths.font(props.font);
            temp.color = props.color;
            temp.antialiasing = this.antialiasing;
            temp.updateHitbox();

            temp.visible = false;

            final glyph:BitmapData = temp.graphic.bitmap.clone();

            var cd:CharData = {
                sprite: temp,
                baseX: curX,
                baseY: curY,
                effects: effs,
                appearTime: 0,
                index: i,
                glyph: glyph
            };

            chars.push(cd);
            lineChars.push(cd);
            curX += temp.width + spacing;
        }

        alignLine(lineChars);

        if (chars.length == 0) return;

        var totalW:Float = 0;
        var totalH:Float = 0;
        for (cd in chars)
        {
            totalW = Math.max(totalW, cd.baseX + cd.sprite.width);
            totalH = Math.max(totalH, cd.baseY + cd.sprite.height);
        }

        _textSprite = new MoonSprite(0, 0);
        _textSprite.makeGraphic(Std.int(totalW + 200), Std.int(totalH + 200), FlxColor.TRANSPARENT);
        _textSprite.antialiasing = this.antialiasing;
        add(_textSprite);
    }

    private function alignLine(line:Array<CharData>):Void
    {
        if (line.length == 0) return;
        var maxH = 0.0;
        for (c in line) maxH = Math.max(maxH, c.sprite.height);
        for (c in line)
        {
            final diff = maxH - c.sprite.height;
            c.sprite.y += diff;
            c.baseY += diff;
        }
    }

    private function collectEffects(index:Int, props:{font:String, size:Int, color:Int}, effs:Array<TextEffect>):Void
    {
        // this parses effects
        // not really 'parses', rather adds them to the list.
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
                    default: trace('[DIALOGUE] Unknown effect: ${ev.name}', "WARNING");
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

    private function parseColor(val:Dynamic):Int
    {
        if (Std.isOfType(val, Int)) return val;
        if (Std.isOfType(val, String))
        {
            var str:String = val;
            if (str.startsWith("#")) return Std.parseInt("0x" + str.substr(1));
            return colorsMap.get(str.toLowerCase());
        }
        return defaultColor;
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // typing behavior
        if (currentIndex < chars.length)
        {
            timer += elapsed;
            var charTime = 1 / speed;
            while (timer >= charTime)
            {
                final cd = chars[currentIndex];
                //trace('typing: ${cd.sprite.text}');

                cd.sprite.visible = true;
                cd.appearTime = FlxG.game.ticks / 1000;
                onType.dispatch();

                currentIndex++;
                timer -= charTime;
                if (currentIndex >= chars.length && !finished)
                {
                    finished = true;
                    onFinish.dispatch();
                }
            }
        }

        if (_textSprite == null) return;

        // time to change how this shit works.
        // draw quads? go to hell!
        // I'm doing this MY way and SCREW YOU DRAW QUADS! SCREW YOUUUUUUUU
        final globalTime = FlxG.game.ticks / 1000;
        final bd:BitmapData = _textSprite.graphic.bitmap;
        bd.fillRect(bd.rect, 0x00000000);

        for (cd in chars)
        {
            if (!cd.sprite.visible) continue;

            // apply base position + effects
            // wow the + alligned correctly with the others thats so fucking funny
            cd.sprite.x = cd.baseX + this.x;
            cd.sprite.y = cd.baseY + this.y;
            for (eff in cd.effects)
                eff.applyDynamic(cd.sprite, elapsed, globalTime, globalTime - cd.appearTime);

            // composite the glyph
            final drawX = cd.sprite.x - this.x;
            final drawY = cd.sprite.y - this.y;
            bd.copyPixels(cd.glyph, new Rectangle(0, 0, cd.glyph.width, cd.glyph.height), new Point(drawX, drawY));
        }
    }

    override function destroy()
    {
        for (cd in chars)
        {
            if (cd.glyph != null) cd.glyph.dispose();
            if (cd.sprite != null) cd.sprite.destroy();
        }
        super.destroy();
    }
}

/** Character metadata */
typedef CharData = {
    sprite:FlxText,
    baseX:Float,
    baseY:Float,
    effects:Array<TextEffect>,
    appearTime:Float,
    index:Int,
    glyph:BitmapData
}