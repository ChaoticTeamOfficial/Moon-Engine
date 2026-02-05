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
import flixel.util.FlxSpriteUtil;

class ScrollBar extends FlxSpriteGroup
{
    var totalHeight:Float;
    var conductor:Conductor;
    var segments:Array<{startTime:Float, startY:Float, stepCrochet:Float}>;
    var playback:Song;

    var bar:FlxSprite;
    var indicator:FlxSprite;
    var sectionText:FlxText;

    var bookmarks:Array<{time:Float, color:FlxColor}> = [];

    var isDragging:Bool = false;
    final barSize:Int = FlxG.height - 78;
    final w = 10;

    public function new(totalHeight:Float, conductor:Conductor, segments:Array<{startTime:Float, startY:Float, stepCrochet:Float}>, playback:Song)
    {
        super();
        this.totalHeight = totalHeight;
        this.conductor = conductor;
        this.segments = segments;
        this.playback = playback;

        bar = new FlxSprite().makeGraphic(w, barSize, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(bar, 0, 0, w, barSize, w, w, FlxColor.BLACK);
        add(bar);
        bar.active = false;
        
        indicator = new FlxSprite().makeGraphic(w, 30, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(indicator, 0, 0, w, 30, w, w, FlxColor.WHITE);
        indicator.alpha = 0.5;
        add(indicator);
        indicator.active = false;
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        final normPos = timeToY(conductor.time) / totalHeight;

        indicator.y = bar.y + normPos * (barSize - indicator.height);

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
    }

    public function addBookmark(time:Float, color:FlxColor)
    {
        bookmarks.push({time: time, color: color});
        redrawBar();
    }

    public function removeBookmark(time:Float)
    {
        final oldLength = bookmarks.length;
        bookmarks = [for (b in bookmarks) if (b.time != time) b];
        if (bookmarks.length < oldLength)
            redrawBar();
    }

    function redrawBar()
    {
        FlxSpriteUtil.fill(bar, FlxColor.TRANSPARENT);
        FlxSpriteUtil.drawRoundRect(bar, 0, 0, w, barSize, w, w, FlxColor.BLACK);
        for (bm in bookmarks)
        {
            final bookmarkY = Math.floor(timeToY(bm.time) / totalHeight * barSize);
            FlxSpriteUtil.drawRect(bar, 0, bookmarkY, w, 2, bm.color);
        }
    }

    function updateTimeFromMouse(mouseY:Float)
    {
        var normPos = (FlxMath.bound(mouseY, bar.y, bar.y + bar.height) - bar.y) / bar.height;
        normPos = (mouseY - bar.y - (indicator.height / 2)) / (barSize - indicator.height);
        normPos = FlxMath.bound(normPos, 0, 1);
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