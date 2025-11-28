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

        final currentSection = getCurrentSection();
        final str = 'Section ${currentSection}';
        if(sectionText.text != str) sectionText.text = str;
        sectionText.y = indY - (sectionText.height / 2);

        if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(bar, this.camera))
        {
            isDragging = true;
            updateTimeFromMouse(FlxG.mouse.viewY);
        }

        if (isDragging)
        {
            if (FlxG.mouse.pressed) updateTimeFromMouse(FlxG.mouse.viewY);
            else isDragging = false;
        }

        sectionText.alpha = FlxMath.lerp(sectionText.alpha, (FlxG.mouse.overlaps(bar, this.camera) || isDragging) ? 1 : 0, elapsed * 6);
    }

    private function getCurrentSection():Int
    {
        final currentY:Float = timeToY(conductor.time);

        for (i in 0...sections.length - 1)
        {
            if (currentY >= sections[i].y && currentY < sections[i + 1].y)
                return sections[i].num;
        }

        return sections[sections.length - 1].num;
    }

    function updateTimeFromMouse(mouseY:Float)
    {
        final normPos = (FlxMath.bound(mouseY, bar.y, bar.y + bar.height) - bar.y) / bar.height;
        playback.time = yToTime(normPos * totalHeight);
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