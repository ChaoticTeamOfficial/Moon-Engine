package moon.toolkit.level_editor;

import flixel.math.FlxMath;
import flixel.group.*;
import flixel.addons.display.FlxTiledSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import moon.toolkit.ui.*;
import moon.game.obj.Song;
import moon.backend.data.Chart;
import moon.game.obj.notes.Note;

class LevelEditor extends FlxState
{
    public var chart:Chart;
    public var conductor:Conductor;
    public var playback:Song;
    private var camBACK:MoonCamera = new MoonCamera();
    private var camMID:MoonCamera = new MoonCamera();
    private var camFRONT:MoonCamera = new MoonCamera();

    public static final LANE_WIDTH:Int = 40;
    public static final LANE_HEIGHT:Int = 40;
    var NUM_LANES:Int = 8;
    final initialGridY:Float = 0;

    var gridGroup:FlxSpriteGroup;
    var sectionTexts:FlxSpriteGroup;
    var noteGroup:FlxSpriteGroup;
    var changes:Array<{time:Float, bpm:Float, numerator:Float, denominator:Float}>;
    var segments:Array<{startTime:Float, startY:Float, stepCrochet:Float}> = [];
    var sectionStarts:Array<{num:Int, y:Float}> = [];
    var changeIndex:Int = 1;
    var graphicCache:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

    override public function create()
    {
        // --- SETUP BACKEND STUFF --- //
        final song = 'bittersweet sunset';
        final diff = 'hard';
        final mix = 'luna';

        camBACK.bgColor = 0x00000000;
        camMID.bgColor = 0x00000000;
        camFRONT.bgColor = 0x00000000;

        FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
        FlxG.cameras.add(camBACK, true);
        FlxG.cameras.add(camMID, false);
        FlxG.cameras.add(camFRONT, false);

        chart = new Chart(song, diff, mix);
        NUM_LANES = 4 * chart.content.meta.lanes.length;

        conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);
        playback = new Song(
            song,
            mix,
            (diff == 'erect' || diff == 'nightmare'),
            conductor
        );

        // --- GENERATE OBJECTSS --- //
        var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(30, 29, 31));
        add(bg);

        // Collects BPM and time signature changes
        // TODO: Make... the... added events also push to this?
        // got lost writing that lol
        changes = [
            {time: 0, bpm: chart.content.meta.bpm, numerator: chart.content.meta.timeSignature[0], denominator: chart.content.meta.timeSignature[1]}
        ];
        for (e in chart.events)
        {
            if (e.tag == 'ChangeBPM')
            {
                changes.push({
                    time: e.time,
                    bpm: e.values.bpm,
                    numerator: e.values.timeSignature[0],
                    denominator: e.values.timeSignature[1]
                });
            }
        }
        changes.sort((a, b) -> Std.int(a.time - b.time));

        gridGroup = new FlxSpriteGroup(FlxG.width / 2 + 64, initialGridY);
        sectionTexts = new FlxSpriteGroup();
        gridGroup.add(sectionTexts);

        final gridWidth:Int = LANE_WIDTH * NUM_LANES;
        var currentY:Float = 0;
        var sectionNum:Int = 0;
        var tempConductor:Conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);

        //make grid!
        for (i in 0...changes.length)
        {
            var ch = changes[i];
            tempConductor.time = ch.time;
            tempConductor.changeBpmAt(ch.time, ch.bpm, ch.numerator, ch.denominator);

            final nextTime:Float = (i < changes.length - 1) ? changes[i + 1].time : playback.fullLength;
            if (nextTime - ch.time <= 0) continue;

            final segSteps:Float = (nextTime - ch.time) / tempConductor.stepCrochet;
            final segHeight:Int = Std.int(Math.ceil(segSteps * LANE_HEIGHT));
            final stepsPerSection = ch.numerator * ch.denominator;
            final beatHeight:Int = Std.int(ch.numerator * LANE_HEIGHT);
            final sectionHeight:Int = Std.int(stepsPerSection * LANE_HEIGHT);

            var tileGraphic:FlxGraphic;
            final cacheKey = ch.numerator + "," + ch.denominator;
            if (!graphicCache.exists(cacheKey))
            {
                //why not make a tile myself?! >:3
                // its fun actuallyy
                // I like openfl renctangless,,
                // RECTANGLES WOOOOO
                var tileSprite = new MoonSprite().makeGraphic(gridWidth, sectionHeight, FlxColor.TRANSPARENT);

                for (b in 0...Std.int(ch.denominator))
                    tileSprite.pixels.fillRect(new Rectangle(0, b * beatHeight, gridWidth, beatHeight), (b % 2 == 0) ? FlxColor.fromRGB(100, 100, 100) : FlxColor.fromRGB(80, 80, 80));

                for (s in 0...Std.int(stepsPerSection) + 1)
                    tileSprite.pixels.fillRect(new Rectangle(0, s * LANE_HEIGHT, gridWidth, 1), FlxColor.GRAY);

                tileSprite.pixels.fillRect(new Rectangle(0, 0, gridWidth, 2), FlxColor.WHITE);

                for (l in 0...NUM_LANES + 1)
                    tileSprite.pixels.fillRect(new Rectangle(l * LANE_WIDTH, 0, 1, sectionHeight), FlxColor.BLACK);

                tileSprite.pixels.fillRect(new Rectangle(4 * LANE_WIDTH - 1, 0, 3, sectionHeight), FlxColor.BLACK);
                tileSprite.dirty = true;
                graphicCache.set(cacheKey, tileSprite.graphic);
            }

            tileGraphic = graphicCache.get(cacheKey);
            var segBG:FlxTiledSprite = new FlxTiledSprite(tileGraphic, gridWidth, segHeight, false, true);
            segBG.antialiasing = false;
            segBG.y = currentY;
            gridGroup.add(segBG);

            // Add section texts
            // Because I enjoy having them
            // It's also a nice help :P
            final numSectionsSeg = Math.ceil(segSteps / stepsPerSection);
            for (sec in 0...numSectionsSeg)
            {
                var txt:FlxText = new FlxText(0, 0, 100, '${sectionNum + sec + 1}', 16);
                txt.setFormat(Paths.font('KodeMono-Bold.ttf'), 28, RIGHT);
                txt.updateHitbox();
                var secY:Float = currentY + (sec * sectionHeight);
                txt.setPosition(-16, secY - (txt.height / 2));
                txt.x -= txt.width;
                sectionTexts.add(txt);

                sectionStarts.push({num: sectionNum + sec + 1, y: secY});
            }

            segments.push({startTime: ch.time, startY: currentY, stepCrochet: tempConductor.stepCrochet});
            sectionNum += numSectionsSeg;
            currentY += segHeight;
        }
        add(gridGroup);

        // Add notes to the grid
        noteGroup = new FlxSpriteGroup();
        gridGroup.add(noteGroup);

        for (n in chart.content.notes)
        {
            var note = new Note(n.data, n.time, n.type, "v-slice", n.duration, conductor);
            note.state = CHART_EDITOR;
            note.active = false; //doesnt need updates, so!
            note.setGraphicSize(LANE_WIDTH, LANE_HEIGHT);
            note.updateHitbox();

            //TODO: update this once we have p2 support.
            final laneIndex = (n.lane == "p1") ? 4 : 0;
            note.x = (laneIndex + n.data) * LANE_WIDTH;
            note.y = timeToY(n.time);

            note.x += (LANE_WIDTH - note.width) / 2;

            noteGroup.add(note);
        }

        var scrollbar = new ScrollBar(sectionStarts, currentY, conductor, segments, playback);
        add(scrollbar);
        scrollbar.setPosition(FlxG.width - scrollbar.width + 128, 0);
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        // ----- Input Stuff ----- //
        if (FlxG.keys.justPressed.SPACE)
            playback.state = (playback.state != PLAY) ? PLAY : PAUSE;

        final addition = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
        final advanceSecs = conductor.stepCrochet * 2 * addition;

        if(MoonInput.justPressed(UI_LEFT)) playback.time -= advanceSecs;
        else if (MoonInput.justPressed(UI_RIGHT)) playback.time += advanceSecs;

        if (FlxG.mouse.wheel != 0)
            playback.time -= FlxG.mouse.wheel * conductor.stepCrochet * addition;

        // this should HOPEFULLY reduce update calls and draw calls :3
        // update: YEAHH IT DID nice.
        for(yeah in sectionTexts.members)
        {
            final spr = cast(yeah, FlxSprite);
            spr.active = spr.visible = spr.isOnScreen();
        }

        // Do the same for notes to optimize
        for(yeah in noteGroup.members)
        {
            final spr = cast(yeah, FlxSprite);
            spr.active = spr.visible = spr.isOnScreen();
        }

        playback.update(elapsed);

        // update grid pos stuff
        while (changeIndex < changes.length && conductor.time >= changes[changeIndex].time)
        {
            final ch = changes[changeIndex];
            conductor.changeBpmAt(ch.time, ch.bpm, ch.numerator, ch.denominator);
            changeIndex++;
        }
        conductor.time = playback.time;

        gridGroup.y = initialGridY - timeToY(conductor.time);
    }

    function timeToY(time:Float):Float
    {
        if (time <= 0) return 0;
        for (i in 0...segments.length)
        {
            final seg = segments[i];
            final nextStart = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
            if (time < nextStart)
                return seg.startY + ((time - seg.startTime) / seg.stepCrochet * LANE_HEIGHT);
        }
        final last = segments[segments.length - 1];
        return last.startY + ((time - last.startTime) / last.stepCrochet * LANE_HEIGHT);
    }

    function durationToHeight(startTime:Float, duration:Float):Float
        return timeToY(startTime + duration) - timeToY(startTime);

    public function sfx(p:String)
    {
        if (playback.state != PLAY)
            Paths.playSFX('toolkit/level-editor/$p.ogg');
    }
}