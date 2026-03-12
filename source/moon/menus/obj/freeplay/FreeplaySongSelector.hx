package moon.menus.obj.freeplay;

import flixel.group.FlxGroup;
import moon.backend.data.SongData;

using StringTools;

class FreeplaySongSelector extends FlxGroup
{
    public static var VISIBLE_RADIUS:Int = 2;

    static final Y_SPACING:Float = 95.0;

    var scrollDelta:Float = 0;
    static final SCROLL_LERP:Float = 14;

    static final DEG_PER_SONG:Float = -25;
    var diskTargetAngle:Float = 0;

    static final DOT_RADIUS:Int = 5;
    static final LINE_W:Int = 512;
    static final LINE_H:Int = 3;

    var selectPulse:Float = 0.0;

    var disk:MoonSprite;
    var diskShader:VinylDiskShader;

    var lineSprites:Array<MoonSprite> = [];
    var dots:Array<MoonSprite> = [];
    var items:Array<FreeplaySongItem> = [];

    var slotBaseY:Array<Float> = [];

    var diskCX(get, never):Float;
    inline function get_diskCX() return disk.x + disk.width * 0.5 + 28;

    var diskCY(get, never):Float;
    inline function get_diskCY() return disk.y + disk.height * 0.5;

    var diskRingR(get, never):Float;
    inline function get_diskRingR() return disk.width * 0.46 * 0.5 + 35;

    var itemX(get, never):Float;
    inline function get_itemX() return disk.x + disk.width + 20;

    var songList:Array<SongBase> = [];
    var charCache:Array<String> = [];
    var curSelected:Int = 0;

    public function new()
    {
        super();

        disk = new MoonSprite(600 - 330 / 2, 345 - 330 / 2).loadGraphic(Paths.image('menus/freeplay/albums/volume1'));
        diskShader = new VinylDiskShader(0.46, 0.12, 0.03, 0.03);
        disk.shader = diskShader;
        disk.origin.set(disk.width / 2, disk.height / 2);
        add(disk);

        final poolSize = VISIBLE_RADIUS * 2 + 1;
        for (i in 0...poolSize)
        {
            final relIdx = i - VISIBLE_RADIUS;
            slotBaseY.push(diskCY + relIdx * Y_SPACING);

            final line = new MoonSprite(0, 0);
            line.makeGraphic(LINE_W, LINE_H, FlxColor.WHITE);
            line.origin.set(0, LINE_H * 0.5);
            line.visible = false;
            lineSprites.push(line);
            add(line);

            final dot = new MoonSprite(0, 0);
            dot.makeGraphic(DOT_RADIUS * 2, DOT_RADIUS * 2, FlxColor.TRANSPARENT);
            FlxSpriteUtil.drawCircle(dot, DOT_RADIUS, DOT_RADIUS, DOT_RADIUS, FlxColor.WHITE);
            dot.visible = false;
            dots.push(dot);
            add(dot);

            final item = new FreeplaySongItem();
            items.push(item);
            add(item.icon);
            add(item.scoreText);
            add(item.nameText);
        }
    }

    public function loadSongs(songs:Array<SongBase>, selected:Int = 0):Void
    {
        songList  = songs;
        curSelected = (songs.length > 0) ? FlxMath.wrap(selected, 0, songs.length - 1) : 0;

        charCache = [];
        for (e in songs)
        {
            var ch = 'dad';
            try
            {
                final d = Paths.JSON('songs/${e.song}/${e.mix}/chart-${e.difficulty}');
                if (d?.meta?.opponents != null && (d.meta.opponents:Array<String>).length > 0)
                    ch = d.meta.opponents[0];
            }
            catch (_:Dynamic) {}
            charCache.push(ch);
        }

        scrollDelta = 0;
        refreshItems(true);
    }

    public function changeSelection(delta:Int):Void
    {
        if (songList.length == 0) return;
        curSelected = FlxMath.wrap(curSelected + delta, 0, songList.length - 1);
        scrollDelta += delta * Y_SPACING;
        diskTargetAngle += delta * DEG_PER_SONG;
        refreshItems();
    }

    public function getSelected():SongBase
        return songList[curSelected];


    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        disk.angle   = FlxMath.lerp(disk.angle, diskTargetAngle, elapsed * SCROLL_LERP);
        scrollDelta  = FlxMath.lerp(scrollDelta, 0, elapsed * SCROLL_LERP);
        selectPulse += elapsed * 6.0;

        for (i in 0...items.length)
        {
            final relIdx  = i - VISIBLE_RADIUS;
            final songIdx = curSelected + relIdx;
            final item    = items[i];

            if (songIdx < 0 || songIdx >= songList.length)
            {
                item.targetAlpha = 0;
                item.alpha = 0;
                item.hide();
                dots[i].visible = false;
                continue;
            }

            if (item.alpha < 0.01 && item.targetAlpha < 0.01) continue;

            item.lerpVisuals(elapsed);

            final baseY = slotBaseY[i] - item.icon.height * item.scale * 0.5 + scrollDelta;
            var itemY = baseY;
            if (relIdx == 0)
                itemY += Math.sin(selectPulse * 2.5) * 3.5;

            item.x = itemX;
            item.y = itemY;
            item.applyPositions();
        }

        for (i in 0...dots.length)
        {
            final dot = dots[i];
            if (!dot.visible) continue;

            final item   = items[i];
            final iconCX = item.icon.x + item.icon.width  * 0.5;
            var iconCY = item.icon.y + item.icon.height * 0.5;

            final relIdx = i - VISIBLE_RADIUS;
            if (relIdx == 0)
            {
                final wiggle = Math.sin(selectPulse * 2.5) * 3.5;
                iconCY -= wiggle;
            }

            final ang = Math.atan2(iconCY - diskCY, iconCX - diskCX);

            dot.x = diskCX + Math.cos(ang) * diskRingR - DOT_RADIUS;
            dot.y = diskCY + Math.sin(ang) * diskRingR - DOT_RADIUS;
        }

        updateLines();
    }

    function updateLines():Void
    {
        for (i in 0...items.length)
        {
            final item = items[i];
            final line = lineSprites[i];
            final dot  = dots[i];

            if (!dot.visible || item.alpha < 0.05)
            {
                line.visible = false;
                continue;
            }

            final cx0 = dot.x + DOT_RADIUS;
            final cy0 = dot.y + DOT_RADIUS;
            final dx = (item.icon.x + item.icon.width  * 0.5) - cx0;
            final dy = (item.icon.y + item.icon.height * 0.5) - cy0;
            final len = Math.sqrt(dx * dx + dy * dy);

            if (len < 1)
            { 
                line.visible = false;
                continue;
            }

            line.setPosition(cx0, cy0);
            line.scale.x = len / LINE_W;
            line.angle = Math.atan2(dy, dx) * (180.0 / Math.PI);
            line.alpha = item.alpha * 0.9;
            line.visible = true;
        }
    }

    function refreshItems(instant:Bool = false):Void
    {
        if (songList.length == 0)
        {
            for (item in items) { item.targetAlpha = 0; item.hide(); }
            for (dot  in dots)  dot.visible = false;
            for (line in lineSprites) line.visible = false;
            return;
        }

        for (i in 0...items.length)
        {
            final relIdx  = i - VISIBLE_RADIUS;
            final songIdx = curSelected + relIdx;
            final item = items[i];
            final rank = Math.abs(relIdx);

            if (songIdx < 0 || songIdx >= songList.length)
            {
                item.targetAlpha = 0;
                if (instant) { item.alpha = 0; item.hide(); }
                dots[i].visible = false;
                continue;
            }

            final scoreData = SongData.retrieveData(
                songList[songIdx].song,
                songList[songIdx].difficulty,
                songList[songIdx].mix
            );
            final scoreVal = scoreData != null ? scoreData.score : -1;
            final accPct = scoreData != null ? Std.int(scoreData.accuracy) : -1;

            item.loadEntry(songList[songIdx], charCache[songIdx], relIdx == 0, scoreVal, accPct);

            item.targetScale = Math.max(0.55, 1.0 - rank * 0.18);
            item.targetAlpha = Math.max(0.20, 1.0 - rank * 0.32);

            dots[i].visible = true;
            dots[i].alpha = item.targetAlpha;

            if (instant)
            {
                item.snapToTarget();
                item.x = itemX;
                item.y = slotBaseY[i] - item.icon.height * item.scale * 0.5;
                item.applyPositions();
            }
        }
    }
}