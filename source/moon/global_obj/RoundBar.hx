package moon.global_obj;

import flixel.FlxG;
import flixel.ui.FlxBar;
import flixel.ui.FlxBar.FlxBarFillDirection;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFrame.FlxFrameType;
import openfl.display.BitmapData;
import openfl.display.Shape;
import openfl.geom.Point;
import openfl.geom.Rectangle;

/**
 * Just a FlxBar with rounded corners, nothing really fancy.
 */
class RoundBar extends FlxBar
{
    public var cornerRadius:Float = 10.0;
    private var emptyColor:FlxColor;
    private var fillColor:FlxColor;
    private var borderColor:FlxColor;
    private var borderSize:Int = 1;
    private var showBorder:Bool = false;

    private var drawShape:Shape;

    @:inheritDoc(FlxBar.new)
    public function new(x:Float = 0, y:Float = 0, ?direction:FlxBarFillDirection, width:Int = 100, height:Int = 10, 
        ?parentRef:Dynamic, variable:String = "", min:Float = 0, max:Float = 100, showBorder:Bool = false, 
        cornerRadius:Float = 10.0, borderSize:Int = 1)
    {
        this.cornerRadius = cornerRadius;
        this.borderSize = borderSize;
        super(x, y, direction, width, height, parentRef, variable, min, max, showBorder);

        drawShape = new Shape();

        _emptyBar = null;
        _filledBar = null;

        if (FlxG.renderTile)
            makeGraphic(barWidth, barHeight, FlxColor.TRANSPARENT, true);

        var dummyBitmap = new BitmapData(1, 1, true, 0);
        var dummyGraphic = FlxGraphic.fromBitmapData(dummyBitmap, false, "dummy");
        _frontFrame = new FlxFrame(dummyGraphic);
        _frontFrame.type = EMPTY;
    }

    override public function createFilledBar(empty:FlxColor, fill:FlxColor, showBorder:Bool = false, border:FlxColor = FlxColor.WHITE, borderSize:Int = 1):FlxBar
    {
        this.emptyColor = empty;
        this.fillColor = fill;
        this.borderColor = border;
        this.showBorder = showBorder;
        this.borderSize = borderSize;
        return this;
    }

    override function updateBar():Void
    {
        if (pixels == null)
            return;

        pixels.lock();
        pixels.fillRect(pixels.rect, FlxColor.TRANSPARENT);

        var fillAmount:Float = (value - min) / range;
        if (fillAmount < 0) fillAmount = 0;
        if (fillAmount > 1) fillAmount = 1;

        var fillWidth:Float = barWidth * fillAmount;
        var fillHeight:Float = barHeight * fillAmount;

        var fillX:Float = 0;
        var fillY:Float = 0;

        switch (fillDirection)
        {
            case LEFT_TO_RIGHT:
                fillWidth = barWidth * fillAmount;
                fillX = 0;
                fillY = 0;

            case RIGHT_TO_LEFT:
                fillWidth = barWidth * fillAmount;
                fillX = barWidth - fillWidth;
                fillY = 0;

            case TOP_TO_BOTTOM:
                fillHeight = barHeight * fillAmount;
                fillX = 0;
                fillY = 0;

            case BOTTOM_TO_TOP:
                fillHeight = barHeight * fillAmount;
                fillX = 0;
                fillY = barHeight - fillHeight;

            case HORIZONTAL_INSIDE_OUT:
                fillWidth = barWidth * fillAmount;
                fillX = (barWidth - fillWidth) / 2;
                fillY = 0;

            case HORIZONTAL_OUTSIDE_IN:
                fillWidth = barWidth * (1 - fillAmount);
                fillX = (barWidth - fillWidth) / 2;
                fillY = 0;

            case VERTICAL_INSIDE_OUT:
                fillHeight = barHeight * fillAmount;
                fillX = 0;
                fillY = (barHeight - fillHeight) / 2;

            case VERTICAL_OUTSIDE_IN:
                fillHeight = barHeight * (1 - fillAmount);
                fillX = 0;
                fillY = (barHeight - fillHeight) / 2;
        }

        drawShape.graphics.clear();
        drawShape.graphics.beginFill(emptyColor);
        drawShape.graphics.drawRoundRect(0, 0, barWidth, barHeight, cornerRadius, cornerRadius);
        drawShape.graphics.endFill();
        pixels.draw(drawShape);

        if (fillAmount > 0)
        {
            drawShape.graphics.clear();
            drawShape.graphics.beginFill(fillColor);
            drawShape.graphics.drawRoundRect(fillX, fillY, _fillHorizontal ? fillWidth : barWidth, _fillHorizontal ? barHeight : fillHeight, cornerRadius, cornerRadius);
            drawShape.graphics.endFill();
            pixels.draw(drawShape);
        }

        if (showBorder)
        {
            drawShape.graphics.clear();
            drawShape.graphics.lineStyle(borderSize, borderColor);
            drawShape.graphics.drawRoundRect(0, 0, barWidth, barHeight, cornerRadius, cornerRadius);
            pixels.draw(drawShape);

            if (fillAmount > 0)
            {
                drawShape.graphics.clear();
                drawShape.graphics.lineStyle(borderSize, borderColor);
                drawShape.graphics.drawRoundRect(fillX, fillY, _fillHorizontal ? fillWidth : barWidth, _fillHorizontal ? barHeight : fillHeight, cornerRadius, cornerRadius);
                pixels.draw(drawShape);
            }
        }

        pixels.unlock();

        dirty = false;
    }

    override public function destroy():Void
    {
        drawShape = null;
        super.destroy();
    }
}