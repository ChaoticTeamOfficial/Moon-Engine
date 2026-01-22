package moon.global_obj;

/**
 * A text component that scrolls horizontally when the text is too wide to fit in the specified width.
 * Similar to marquee-style scrolling text seen in music players!
 */
class ScrollingText extends MoonSprite
{
    public var textField:FlxText;
    public var maskRect:FlxRect;

    public var scrollOffset:Float = 0;

    /**
     * The text's scroll speed. Pixels per second.
     */
    public var scrollSpeed:Float = 45;

    /**
     * The text's pause duration when reaching an end.
     */
    public var pauseDuration:Float = 2;

    private var pauseTimer:Float = 0;
    private var scrollingRight:Bool = false;
    private var needsScroll:Bool = false;
    
    public var displayWidth:Float;
    
    /**
     * @param X The x position
     * @param Y The y position
     * @param Width The maximum width for the text display
     * @param Text The text to display
     * @param Size The font size
     */
    public function new(X:Float = 0, Y:Float = 0, Width:Float = 200, ?Text:String, Size:Int = 16)
    {
        super(X, Y);
        
        displayWidth = Width;
        
        textField = new FlxText(0, 0, 0, Text, Size);
        textField.scrollFactor.set(0, 0);
        
        maskRect = FlxRect.get(0, 0, Width, textField.height);
        makeGraphic(Std.int(Width), Std.int(textField.height), FlxColor.TRANSPARENT, true);
        setText(Text);
    }
    
    /**
     * Set the text content
     */
    public function setText(text:String):Void
    {
        textField.text = text;
        scrollOffset = 0;
        pauseTimer = pauseDuration;
        scrollingRight = false;
        updateScrollState();
    }
    
    public function updateScrollState():Void
    {
        needsScroll = textField.width > displayWidth - 19;
        
        if (!needsScroll)
            scrollOffset = 0;
    }
    
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        
        if (!needsScroll)
            return;
        
        // handle pause timer
        if (pauseTimer > 0)
        {
            pauseTimer -= elapsed;
            return;
        }
        
        // calculates max scroll distances
        final maxScroll = textField.width - displayWidth;
        
        if (scrollingRight)
        {
            scrollOffset -= scrollSpeed * elapsed;
            
            if (scrollOffset <= 0)
            {
                scrollOffset = 0;
                scrollingRight = false;
                pauseTimer = pauseDuration;
            }
        }
        else
        {
            scrollOffset += scrollSpeed * elapsed;
            
            if (scrollOffset >= maxScroll)
            {
                scrollOffset = maxScroll;
                scrollingRight = true;
                pauseTimer = pauseDuration;
            }
        }
    }
    
    override public function draw():Void
    {
        pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);
        
        final sourceRect = new flash.geom.Rectangle(
            scrollOffset,
            0,
            Math.min(displayWidth, textField.width - scrollOffset),
            textField.height
        );
        
        // stamp the text onto this sprite's canvas
        pixels.copyPixels(
            textField.updateFramePixels(),
            sourceRect,
            new flash.geom.Point(0, 0)
        );
        
        dirty = true;
        super.draw();
    }
    
    override public function destroy():Void
    {
        textField = null;
        if (maskRect != null)
        {
            maskRect.put();
            maskRect = null;
        }
        super.destroy();
    }

    override public function set_antialiasing(antialiasing:Bool):Bool
    {
    	this.antialiasing = antialiasing;
    	textField.antialiasing = antialiasing;
    	return antialiasing;
    }
}