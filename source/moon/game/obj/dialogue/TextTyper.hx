package moon.game.obj.dialogue;

import flixel.group.FlxSpriteGroup;
import moon.backend.data.Dialogue.DialogueEvent;
import moon.backend.data.Dialogue.DialogueParser;
import flixel.util.FlxSignal;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;
import openfl.geom.ColorTransform;

using StringTools;

/**
 * TODO List:
 * When advancing to a text, the game lags, so check that.
 * Some effects look weirdly exagerated.
 * The rainbow one doesn't... seem to work?
 * If there's too much text, some of them may appear cutting the ones above, probably related to the text size.
 * 
 */
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
	 * Typing animation applied to each character as it is revealed.
	 */
	public var typingAnimation:TypingAnimation = INSTANT;

	/**
	 * Duration (seconds) for FADE / SLIDE_UP typing animations.
	 * BOUNCE uses its own built-in duration.
	 */
	public var typingAnimDuration:Float = 0.2;

	/**
	 * The current text that will be displayed.
	 */
	public var text:String;

	/**
	 * A list of events that will happen on this typer.
	 */
	public var events:Array<DialogueEvent>;

	/**
	 * The speed for this text.
	 * TODO: maybe change it to work differently?
	 */
	public var speed:Float = 30;

	/**
	 * A signal dispatched when the text finishes.
	 */
	public final onFinish:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	/**
	 * A signal dispatched when a text character is typed.
	 */
	public final onType:FlxTypedSignal<Void->Void> = new FlxTypedSignal<Void->Void>();

	private var chars:Array<CharData> = [];
	private var currentIndex:Int = 0;
	private var timer:Float = 0;
	private var finished:Bool = false;
	private var _textSprite:MoonSprite;

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

		// buildCharacters();
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
		final now = FlxG.game.ticks / 1000;
		for (cd in chars)
		{
			cd.sprite.visible = true;
			cd.appearTime = now;
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

		var i = 0;
		while (i < text.length)
		{
			final ch:String = text.charAt(i);

			if (ch == "\n")
			{
				alignLine(lineChars);
				lineChars = [];
				curX = 0;
				curY += lineHeight;
				i++;
				continue;
			}

			// these are for non explicits line changes
			// needed otherwise would look weird sometimes
			if (ch != " " && curX > 0)
			{
				final wordW = measureNextWord(i);
				if (curX + wordW > lineWidth)
				{
					alignLine(lineChars);
					lineChars = [];
					curX = 0;
					curY += lineHeight;
				}
			}

			final props = {
				font: defaultFont,
				size: defaultSize,
				color: defaultColor
			};
			final effs:Array<TextEffect> = [];
			collectEffects(i, props, effs);

			// ok so here we build each text glyph
			final temp = new FlxText(0, 0, 0, ch, props.size);
			temp.font = Paths.font(props.font);
			temp.color = props.color;
			temp.antialiasing = this.antialiasing;
			temp.updateHitbox();

			for (eff in effs) eff.applyStatic(temp);
			temp.updateHitbox();

			temp.visible = false;

			final glyph:BitmapData = temp.graphic.bitmap.clone();

			final cd:CharData = {
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
			i++;
		}

		alignLine(lineChars);
		if (chars.length == 0) return;

		// build composite canvas
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

	/**
	 * Measures the pixel width of the next run of non-space characters starting at `start`.
	 */
	private function measureNextWord(start:Int):Float
	{
		var w:Float = 0;
		var i = start;
		while (i < text.length && text.charAt(i) != " " && text.charAt(i) != "\n")
		{
			final props = {
				font: defaultFont,
				size: defaultSize,
				color: defaultColor
			};
			collectEffects(i, props, []);
			final tmp = new FlxText(0, 0, 0, text.charAt(i), props.size);
			tmp.font = Paths.font(props.font);
			tmp.updateHitbox();
			w += tmp.width + spacing;
			tmp.destroy();
			i++;
		}
		return w;
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

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// reveal characters over time
		if (currentIndex < chars.length)
		{
			timer += elapsed;
			final charTime = 1.0 / speed;
			while (timer >= charTime && currentIndex < chars.length)
			{
				final cd = chars[currentIndex];
				cd.sprite.visible = true;
				cd.appearTime = FlxG.game.ticks / 1000;
				onType.dispatch();
				currentIndex++;
				timer -= charTime;
			}
			if (currentIndex >= chars.length && !finished)
			{
				finished = true;
				onFinish.dispatch();
			}
		}

		if (_textSprite == null) return;

		final globalTime = FlxG.game.ticks / 1000;
		final bd:BitmapData = _textSprite.graphic.bitmap;
		bd.fillRect(bd.rect, 0x00000000);

		// ummm
		for (cd in chars)
		{
			if (!cd.sprite.visible) continue;

			final localTime = globalTime - cd.appearTime;

			cd.sprite.x = cd.baseX + this.x;
			cd.sprite.y = cd.baseY + this.y;
			cd.sprite.alpha = 1.0;

			applyTypingAnim(cd.sprite, localTime);

			for (eff in cd.effects) eff.applyDynamic(cd.sprite, elapsed, globalTime, localTime);

			final drawX = cd.sprite.x - this.x;
			final drawY = cd.sprite.y - this.y;

			if (cd.sprite.alpha >= 1.0) bd.copyPixels(cd.glyph, new Rectangle(0, 0, cd.glyph.width, cd.glyph.height), new Point(drawX, drawY));
			else if (cd.sprite.alpha > 0)
			{
				final ct = new ColorTransform(1, 1, 1, cd.sprite.alpha);
				bd.copyPixels(cd.glyph, new Rectangle(0, 0, cd.glyph.width, cd.glyph.height), new Point(drawX, drawY), null, null, true);
			}
		}
	}

	/**
	 * Applies the selected typing-reveal animation to a character.
	 */
	private function applyTypingAnim(sprite:FlxText, localTime:Float):Void
	{
		// TODO: maybe more anims?
		switch (typingAnimation)
		{
			case INSTANT:
				// nothing

			case FADE:
				sprite.alpha = Math.min(1.0, localTime / typingAnimDuration);

			case BOUNCE:
				final height:Float = 14;
				final duration:Float = 0.3;
				final stiffness:Float = 10;
				if (localTime < duration * 2)
				{
					final decay = Math.exp(-stiffness * localTime);
					final osc = Math.sin(Math.PI * localTime / duration);
					sprite.y -= height * decay * osc;
				}

			case SLIDE_UP:
				final t = Math.min(1.0, localTime / typingAnimDuration);
				final ease = 1 - Math.pow(1 - t, 3);
				final offset = (1 - ease) * 10;
				sprite.y += offset;
				sprite.alpha = ease;
		}
	}

	private function collectEffects(index:Int, props:
		{font:String, size:Int, color:Int}, effs:Array<TextEffect>):Void
	{
		for (ev in events)
		{
			if (ev.range.start > index || index >= ev.range.end) continue;
			switch (ev.name.toLowerCase())
			{
				case "shake":
					effs.push(new ShakeEffect(ev.values));
				case "wave":
					effs.push(new WaveEffect(ev.values));
				case "bounce":
					effs.push(new BounceEffect(ev.values));
				case "fadein":
					effs.push(new FadeInEffect(ev.values));
				case "rainbow":
					effs.push(new RainbowEffect(ev.values));
				case "jitter":
					effs.push(new JitterEffect(ev.values));
				case "shadow":
					effs.push(new ShadowEffect(ev.values));
				case "outline":
					effs.push(new OutlineEffect(ev.values));

				case "color":
					final colorVal:Dynamic = Reflect.field(ev.values, "color") ?? ev.values;
					props.color = parseColor(colorVal);

				case "font":
					var fontVal:Dynamic = Reflect.field(ev.values, "path") ?? ev.values;
					props.font = Std.string(fontVal);

				case "size":
					props.size = Std.int(
						Reflect.field(ev.values, "size") ?? (Std.isOfType(ev.values, Float) || Std.isOfType(ev.values, Int) ? ev.values : defaultSize)
					);

				default:
					trace('[DIALOGUE] Unknown effect: ${ev.name}', "WARNING");
			}
		}
	}

	final colorsMap:Map<String, FlxColor> = [
		"black" => FlxColor.BLACK,
		"blue" => FlxColor.BLUE,
		"brown" => FlxColor.BROWN,
		"cyan" => FlxColor.CYAN,
		"gray" => FlxColor.GRAY,
		"green" => FlxColor.GREEN,
		"lime" => FlxColor.LIME,
		"magenta" => FlxColor.MAGENTA,
		"orange" => FlxColor.ORANGE,
		"pink" => FlxColor.PINK,
		"purple" => FlxColor.PURPLE,
		"red" => FlxColor.RED,
		"white" => FlxColor.WHITE,
		"yellow" => FlxColor.YELLOW,
		"transparent" => FlxColor.TRANSPARENT
	];

	private function parseColor(val:Dynamic):Int
	{
		if (Std.isOfType(val, Int)) return val;
		if (Std.isOfType(val, String))
		{
			var str:String = val;
			if (str.startsWith("#")) return Std.parseInt("0x" + str.substr(1));
			final named = colorsMap.get(str.toLowerCase());
			if (named != null) return named;
		}
		return defaultColor;
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

enum TypingAnimation
{
	/** 
	 * Character appears instantly.
	 */
	INSTANT;

	/** 
	 * Character fades in from transparent.
	 */
	FADE;

	/**
	 *  Character bounces in from above with a spring.
	 */
	BOUNCE;

	/** 
	 * Character slides up and fades in. 
	 */
	SLIDE_UP;
}

typedef CharData =
{
	sprite:FlxText,
	baseX:Float,
	baseY:Float,
	effects:Array<TextEffect>,
	appearTime:Float,
	index:Int,
	glyph:BitmapData
}
