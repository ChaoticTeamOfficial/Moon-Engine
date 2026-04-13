package moon.menus.obj.freeplay;

import flixel.group.FlxGroup;
import moon.backend.data.SongData;

using StringTools;

//TODO: finish documenting this
class FreeplaySongSelector extends FlxGroup
{
    public static final VISIBLE_RADIUS:Int = 2;

    static final Y_SPACING:Float = 95.0;
    static final WIGGLE_SPEED = 1.2;
    static final SCROLL_LERP:Float = 10;
    static final DEG_PER_SONG:Float = -25;
    static final DOT_RADIUS:Int = 5;
    static final LINE_W:Int = 512;
    static final LINE_H:Int = 3;

    var scrollDelta:Float = 0;
    var diskTargetAngle:Float = 0;
    var selectPulse:Float = 0.0;

    var disk:MoonSprite;
    var albumTitle:MoonSprite;

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
    var curSelected:Int = 0;

    private var preloadedCharts:Array<Chart> = [];
    private var curAlb:String = '';

    public function new()
    {
        super();

        disk = new MoonSprite().loadGraphic(Paths.image('menus/freeplay/albums/volume1'));
        disk.shader = new VinylDiskShader(0.46, 0.12, 0.03, 0.03);
        disk.active = false;
        disk.screenCenter();
        disk.origin.set(disk.width / 2, disk.height / 2);
        add(disk);

        albumTitle = new MoonSprite();
        //albumTitle.scale.set(0.8, 0.8);
        add(albumTitle);

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
            dot.active = false;
            dots.push(dot);
            add(dot);

            final item = new FreeplaySongItem();
            items.push(item);
            add(item);
        }

        disk.scale.set(0, 0);
        disk.updateHitbox();
        disk.angle = -360;
        FlxTween.tween(disk.scale, {x: 1, y: 1}, 0.7, {ease: FlxEase.expoOut, onUpdate: _->disk.updateHitbox(), onComplete: _-> Global.allowInputs = true});
    }

    /**
     * Loads the song list AND pre-creates every Chart.
     */
    public function loadSongs(songs:Array<SongBase>, selected:Int = 0):Void
    {
        songList = songs;
        curSelected = (songs.length > 0) ? FlxMath.wrap(selected, 0, songs.length - 1) : 0;

        refreshEntries();

        scrollDelta = 0;
        refreshItems(true);
    }

    public function refreshEntries():Void
    {
        preloadedCharts.resize(0);

        for (entry in songList)
            preloadedCharts.push(new Chart(entry.song, entry.difficulty, entry.mix));
    }

    public function changeSelection(delta:Int):Void
    {
        if (songList.length == 0) return;

        curSelected = FlxMath.wrap(curSelected + delta, 0, songList.length - 1);
        scrollDelta += delta * Y_SPACING;
        diskTargetAngle += delta * DEG_PER_SONG;

        refreshItems(false);
    }

    public function getSelected():SongBase
        return songList[curSelected];

    public function getSelectedItem():FreeplaySongItem
    {
        if (items.length == 0)
            return null;
            
        return items[VISIBLE_RADIUS];
    }

    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        SongPreview.update(elapsed);

        disk.angle = FlxMath.lerp(disk.angle, diskTargetAngle, elapsed * SCROLL_LERP);
        scrollDelta = FlxMath.lerp(scrollDelta, 0, elapsed * SCROLL_LERP);
        selectPulse += elapsed * 6.0;

        for (i in 0...items.length)
        {
            final relIdx = i - VISIBLE_RADIUS;
            final songIdx = curSelected + relIdx;
            final item = items[i];

            if (songIdx < 0 || songIdx >= songList.length)
            {
                item.targetAlpha = 0;
                item.lerpAlpha = 0;
                item.hide();
                dots[i].visible = false;
                item.icon.filters = null;
                item.bg.alpha = 0;
                continue;
            }

            //TODO: REMOVE THIS! ITS FOR debUGGING PURPOSES
            if(FlxG.keys.justPressed.O && relIdx == 0)
            {
                item.doRankReveal();
            }

            if (item.lerpAlpha < 0.01 && item.targetAlpha < 0.01) continue;

            item.lerpVisuals(elapsed);

            final baseY = slotBaseY[i] - item.icon.height * item.lerpScale * 0.5 + scrollDelta;
            var itemY = baseY;
            if (relIdx == 0)
                itemY += Math.sin(selectPulse * WIGGLE_SPEED) * 3.5;

            item.applyPositions(itemX, itemY);
        }

        for (i in 0...dots.length)
        {
            final dot = dots[i];
            if (!dot.visible) continue;

            final item = items[i];
            final iconCX = item.icon.x + item.icon.width  * 0.5;
            var iconCY = item.icon.y + item.icon.height * 0.5;

            final relIdx = i - VISIBLE_RADIUS;
            if (relIdx == 0)
                iconCY -= Math.sin(selectPulse * WIGGLE_SPEED) * 3.5;

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

            if (!dot.visible || item.lerpAlpha < 0.05)
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
            line.alpha = item.lerpAlpha * 0.9;
            line.visible = true;
        }
    }

    function refreshItems(instant:Bool = false):Void
    {
        if (songList.length == 0)
        {
            for (item in items) 
            {
                item.targetAlpha = 0; 
                item.icon.filters = null;
                item.bg.alpha = 0;
                item.hide();
            }
            for (dot  in dots)  dot.visible = false;
            for (line in lineSprites) line.visible = false;
            return;
        }

        for (i in 0...items.length)
        {
            final relIdx = i - VISIBLE_RADIUS;
            final songIdx = curSelected + relIdx;
            final item = items[i];
            final dist = Math.abs(relIdx);

            if (songIdx < 0 || songIdx >= songList.length)
            {
                item.targetAlpha = 0;
                if (instant) { item.lerpAlpha = 0; item.hide(); }
                dots[i].visible = false;
                item.icon.filters = null;
                item.bg.alpha = 0;
                continue;
            }

            final chart = preloadedCharts[songIdx];

            if (item.data != chart)
            {
                item.data = chart;
                item.resetRank();
                if (item.icon.character != chart.content.meta.opponents[0])
                    item.icon.character = chart.content.meta.opponents[0];

                final displayName = chart.content.meta.displayName ?? songList[songIdx].song;
                item.nameText.setText(displayName.toUpperCase());
            }

            final scoreData = SongData.retrieveData(songList[songIdx].song, songList[songIdx].difficulty, songList[songIdx].mix);
            //final rankStr:String = scoreData != null ? scoreData.rank : null;

            item.setSelected(relIdx == 0, scoreData?.score ?? -1, scoreData?.accuracy ?? -1);

            item.targetScale = Math.max(0.55, 1.0 - dist * 0.22);
            item.targetAlpha = Math.max(0.20, 1.0 - dist * 0.30);

            dots[i].visible = true;
            dots[i].alpha = item.targetAlpha;

            item.bg.alpha = (relIdx == 0) ? 0.9 : 0;

            if (instant)
            {
                item.snapToTarget();
                item.applyPositions(itemX, slotBaseY[i] - item.icon.height * item.lerpScale * 0.5);
            }

            if(relIdx == 0)
            {
                Freeplay.instance.stars.difficulty = Chart.calculateDifficultyRating(chart.content.notes, chart.content.meta.bpm);

                //lol
                try{ SongPreview.loadAndPlay(chart); } catch(e) { }

                final album = Paths.exists('images/menus/freeplay/albums/${chart.content.meta.album}.png') ? chart.content.meta.album : 'placeholder';
                if(curAlb != album) disk.loadGraphic(Paths.image('menus/freeplay/albums/$album'));
                if(!album.contains('placeholder'))
                {
                    if(curAlb != album)
                    {
                        albumTitle.frames = Paths.getSparrowAtlas('menus/freeplay/albums/$album-text');
                        albumTitle.centerAnimations = true;
                        albumTitle.animation.addByPrefix('switch', 'switch', 24, false);
                        albumTitle.animation.addByPrefix('idle', 'idle', 24, false);
                        albumTitle.animation.onFinish.addOnce(_->albumTitle.playAnim('idle'));
                        albumTitle.playAnim('switch', true);

                        albumTitle.scale.set(0.6, 0.6);
                        albumTitle.updateHitbox();
                        albumTitle.setPosition(disk.x, disk.y + disk.height - 48);
                        albumTitle.visible = true;
                    }
                }
                else albumTitle.visible = false;

                curAlb = album;
            }
        }
    }

    override public function destroy():Void
    {
        preloadedCharts.resize(0);
        super.destroy();
    }
}