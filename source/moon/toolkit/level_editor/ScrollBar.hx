package moon.toolkit.level_editor;

import flixel.math.FlxMath;
import flixel.group.FlxGroup;
import flixel.group.FlxSpriteGroup;
import flixel.addons.display.FlxTiledSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import moon.toolkit.ui.*;
import moon.game.obj.Song;
import moon.backend.data.Chart;
import moon.game.obj.notes.Note;
import flixel.tweens.FlxTween;

class ScrollBar extends FlxSpriteGroup
{
    var sections:Array<{num:Int, y:Float}>;
    var totalHeight:Float;
    var conductor:Conductor;
    var segments:Array<{startTime:Float, startY:Float, stepCrochet:Float}>;
    var playback:Song;

    var bar:FlxSprite;
    var indicator:FlxSprite;
    var sectionText:FlxText;

    var isDragging:Bool = false;

    public function new(sections:Array<{num:Int, y:Float}>, totalHeight:Float, conductor:Conductor, segments:Array<{startTime:Float, startY:Float, stepCrochet:Float}>, playback:Song)
    {
        super();
        this.sections = sections;
        this.totalHeight = totalHeight;
        this.conductor = conductor;
        this.segments = segments;
        this.playback = playback;

        bar = new FlxSprite(0, 50).makeGraphic(24, FlxG.height - 100, FlxColor.GRAY);
        add(bar);

        indicator = new FlxSprite(0, 0).makeGraphic(24, 20, FlxColor.WHITE);
        add(indicator);

        sectionText = new FlxText(0, 0, 0, "Section 100");
        sectionText.setFormat(Paths.font('KodeMono-Bold.ttf'), 20);
        sectionText.x = -sectionText.width - 5;
        add(sectionText);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        var normPos = timeToY(conductor.time) / totalHeight;
        var barHeight = FlxG.height - 100;
        var indY = 50 + normPos * barHeight;

        indicator.y = indY - (indicator.height / 2);

        final currentSection = Std.int(conductor.curMeasure) + 1;
        final str = 'Section ${currentSection}';
        if(sectionText.text != str) sectionText.text = str;
        sectionText.y = indY - (sectionText.height / 2);

        final mousePos = FlxG.mouse.getPositionInCameraView(camera);
        if (FlxG.mouse.justPressed && bar.overlapsPoint(mousePos))
        {
            isDragging = true;
            updateTimeFromMouse(mousePos.y);
        }

        if (isDragging)
        {
            if (FlxG.mouse.pressed) updateTimeFromMouse(mousePos.y);
            else isDragging = false;
        }
    }

    function updateTimeFromMouse(mouseY:Float)
    {
        var clampedY = FlxMath.bound(mouseY, bar.y, bar.y + bar.height);
        var normPos = (clampedY - bar.y) / bar.height;
        var targetY = normPos * totalHeight;
        var targetTime = yToTime(targetY);
        playback.time = targetTime;
    }

    function timeToY(time:Float):Float
    {
        if (time <= 0) return 0;
        for (i in 0...segments.length)
        {
            final seg = segments[i];
            final nextStart = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
            if (time < nextStart)
                return seg.startY + ((time - seg.startTime) / seg.stepCrochet * LevelEditor.LANE_HEIGHT);
        }
        final last = segments[segments.length - 1];
        return last.startY + ((time - last.startTime) / last.stepCrochet * LevelEditor.LANE_HEIGHT);
    }

    function yToTime(y:Float):Float
    {
        if (y <= 0) return 0;
        for (i in 0...segments.length)
        {
            final seg = segments[i];
            final nextY = (i < segments.length - 1) ? segments[i + 1].startY : totalHeight;
            if (y < nextY)
                return seg.startTime + ((y - seg.startY) / LevelEditor.LANE_HEIGHT) * seg.stepCrochet;
        }
        return playback.fullLength;
    }
}