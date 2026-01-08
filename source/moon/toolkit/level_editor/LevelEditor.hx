package moon.toolkit.level_editor;

import flixel.math.FlxMath;
import flixel.group.*;
import flixel.addons.display.FlxTiledSprite;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import moon.toolkit.ui.*;
import moon.game.obj.*;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;
import moon.backend.data.Chart.ChartStruct;
import openfl.filters.ColorMatrixFilter;
import flixel.math.FlxRect;

enum GridType {
    NOTES;
    EVENTS;
    CHARACTERS;
    GIMMICKS;
    SOUNDS;
}

class LevelEditor extends FlxState
{
    // --- OBJECTS --- //
    public static var chart:Chart;
    public var conductor:Conductor;
    public var playback:Song;
    private var camBACK:MoonCamera = new MoonCamera();
    private var camMID:MoonCamera = new MoonCamera();
    private var camFRONT:MoonCamera = new MoonCamera();
    
    var scrollbar:ScrollBar;
    var strum:Strums;
    var cursor:FlxSprite;

    private var gridGroup:FlxSpriteGroup;
    //private var sectionTexts:FlxSpriteGroup;
    private var noteGroup:FlxSpriteGroup;
    private var miscGroup:FlxSpriteGroup;

    // --- NUMBER VARIABLES --- //
    public static final LANE_WIDTH:Int = 40;
    public static final LANE_HEIGHT:Int = 40;
    public static final initialGridY:Float = 48;

    public static var NUM_LANES:Int = 8;

    // --- GRID STUFF --- //
    var snapIndex:Int = 1;
    var curSnap:Int = 4;
    final snaps:Array<Int> = [0, 4, 8, 12, 16, 20, 24, 32, 48, 64, 96, 192];
    final allTypes:Array<GridType> = [NOTES, EVENTS, CHARACTERS, GIMMICKS, SOUNDS];
    var curType(default, set):GridType;

    // --- CHART-RELATED VARIABLES --- //
    private var _internalChart:ChartStruct;
    public var song:String = 'darnell';
    public var diff:String = 'hard';
    public var mix:String = 'bf';

    // --- OTHER/MISC --- //
    var changes:Array<{time:Float, bpm:Float, numerator:Float, denominator:Float}>;
    var segments:Array<{startTime:Float, startY:Float, stepCrochet:Float}> = [];
    var sectionStarts:Array<{num:Int, y:Float}> = [];
    var graphicCache:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

    public var grayscale:GrayscaleShader = new GrayscaleShader();
    public var invertColors:InvertColor = new InvertColor();

    override public function create()
    {
        //SELF NOTE; 
        // umm I should look into note rendering or sum shit
        // memory usage at start is... terrible, woah.

        // NOTE 2:
        // It isn't the notes, it's the tiled grid sprite!!! I gotta fix it ;v;

        // NOTE 3:
        // Fixed it ;D

        // --- SETUP BACKEND STUFF --- //
        camBACK.bgColor = 0xFF1e1d1f;
        camMID.bgColor = 0x00000000;
        camFRONT.bgColor = 0x00000000;

        FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
        FlxG.cameras.add(camBACK, true);
        FlxG.cameras.add(camMID, false);
        FlxG.cameras.add(camFRONT, false);

        Tilemap.addAtlas('MELE-buttons', 'toolkit/level-editor/icons/gridTypes');
        Tilemap.addAtlas('btnIcons', 'toolkit/ui/googleIcons');
        Tilemap.addAtlas('mainUI', 'toolkit/ui/uiStuff');

        chart = new Chart(song, diff, mix);
        _internalChart = chart.content;
        NUM_LANES = 4 * chart.content.meta.lanes.length;

        conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);
        playback = new Song(
            song,
            mix,
            (diff == 'erect' || diff == 'nightmare'),
            conductor
        );

        // --- GENERATE OBJECTSS --- //

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
        //sectionTexts = new FlxSpriteGroup();
        //gridGroup.add(sectionTexts);

        final TOTAL_LANES:Int = NUM_LANES + 1;
        final gridWidth:Int = LANE_WIDTH * TOTAL_LANES;
        var currentY:Float = 0;
        //var sectionNum:Int = 0;
        var tempConductor:Conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);

        //make grid!
        for (i in 0...changes.length)
        {
            final ch = changes[i];
            tempConductor.time = ch.time;
            tempConductor.changeBpmAt(ch.time, ch.bpm, ch.numerator, ch.denominator);

            final nextTime = (i < changes.length - 1) ? changes[i + 1].time : playback.fullLength;
            if (nextTime - ch.time <= 0) continue;

            final segSteps = (nextTime - ch.time) / tempConductor.stepCrochet;
            final stepsPerSection = ch.numerator * ch.denominator;
            final sectionHeight:Int = Std.int(stepsPerSection * LANE_HEIGHT);
            final beatHeight:Int = Std.int(ch.numerator * LANE_HEIGHT);

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
                    tileSprite.pixels.fillRect(new Rectangle(0, b * beatHeight, gridWidth, beatHeight), (b % 2 == 0) ? 0xFF2a2a2c : 0xFF373739);
                tileSprite.pixels.fillRect(new Rectangle(NUM_LANES * LANE_WIDTH, 0, LANE_WIDTH, sectionHeight), FlxColor.BLACK);

                for (s in 0...Std.int(stepsPerSection) + 1)
                    tileSprite.pixels.fillRect(new Rectangle(0, s * LANE_HEIGHT, gridWidth, 1), FlxColor.GRAY);

                tileSprite.pixels.fillRect(new Rectangle(0, 0, gridWidth, 2), FlxColor.WHITE);

                for (l in 0...TOTAL_LANES + 1)
                    tileSprite.pixels.fillRect(new Rectangle(l * LANE_WIDTH, 0, 1, sectionHeight), FlxColor.BLACK);

                tileSprite.pixels.fillRect(new Rectangle(4 * LANE_WIDTH - 1, 0, 3, sectionHeight), FlxColor.BLACK);

                tileSprite.dirty = true;
                graphicCache.set(cacheKey, tileSprite.graphic);
            }

            tileGraphic = graphicCache.get(cacheKey);

            // break the segment into per-section sprites
            final numFullSections:Int = Std.int(Math.floor(segSteps / stepsPerSection));
            var secY:Float = currentY;
            for (sec in 0...numFullSections)
            {
                var secSprite = new MoonSprite(0, secY).loadGraphic(tileGraphic);
                secSprite.antialiasing = false;
                secSprite.active = false;
                gridGroup.add(secSprite);
                secY += sectionHeight;
            } 
            final remainderSteps = segSteps - (numFullSections * stepsPerSection);
            if (remainderSteps > 0)
            {
                final remainderHeight = remainderSteps * LANE_HEIGHT;
                var lastSprite = new MoonSprite(0, secY).loadGraphic(tileGraphic);
                lastSprite.antialiasing = false;
                lastSprite.active = false;
                lastSprite.clipRect = new FlxRect(0, 0, gridWidth, remainderHeight);
                lastSprite.height = remainderHeight;
                lastSprite.updateHitbox();
                gridGroup.add(lastSprite);
                secY += remainderHeight;
            }

            // Add section texts
            // Because I enjoy having them
            // It's also a nice help :P

            // well UHH!! New design removes em!
            // soo bye bye section indicators...
            /*final numSectionsSeg = Math.ceil(segSteps / stepsPerSection);
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
            }*/

            segments.push({startTime: ch.time, startY: currentY, stepCrochet: tempConductor.stepCrochet});
            //sectionNum += numSectionsSeg;
            currentY = secY;
        }
        add(gridGroup);

        // Add notes to the grid
        noteGroup = new FlxSpriteGroup();
        gridGroup.add(noteGroup);

        for (nData in chart.content.notes)
            createNote(nData);

        miscGroup = new FlxSpriteGroup();
        gridGroup.add(miscGroup);

        scrollbar = new ScrollBar(currentY, conductor, segments, playback);
        add(scrollbar);
        scrollbar.y = initialGridY + 8;
        scrollbar.x = gridGroup.x + gridWidth + 16;

        //debugTxt = new FlxText(10, 10, 200, "Snap: 1/4", 16);
        //debugTxt.setFormat(Paths.font('KodeMono-Bold.ttf'), 16, FlxColor.WHITE);
        //add(debugTxt);

        cursor = new MoonSprite();
        cursor.makeGraphic(LANE_WIDTH, LANE_HEIGHT, FlxColor.WHITE);
        cursor.antialiasing = false;
        cursor.alpha = 0.55;
        cursor.visible = false;
        add(cursor);

        // lol
        final ogC = 0xFF1e1d1f;
        var colors = [ogC];
        for(i in 0...10)
            colors.push(FlxColor.TRANSPARENT);
        colors.push(ogC);

        add(FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, colors));

        strum = new Strums(gridGroup.x, initialGridY);
        add(strum);

        for(i in 0...allTypes.length)
        {
            final gType = allTypes[i];
            final s:String = '$gType'.toLowerCase();

            var button = new MoonSprite(0, -16);
            button.frames = Tilemap.getAtlasFrames('MELE-buttons');
            button.animation.addByPrefix('idle', 'type-$s-normal-', 1, false);
            button.animation.addByPrefix('click', 'type-$s-click-', 1, false);
            //button.shader = invertColors; HELL YEAH IT WORKS
            add(button);
            button.centerAnimations = true;

            button.scale.set(0.65, 0.65);
            button.updateHitbox();
            button.antialiasing = true;

            button.x = gridGroup.x - button.width;
            button.y += (button.height + 52 * i);

            button.animation.play('idle');
            button.active = false; // I think we wont need it active?
            typeButtons.set(gType, button);
        }

        var library = new Library();
        library.camera = camMID;
        add(library);

        var leftpanel = new LeftPanel(this);
        leftpanel.camera = camMID;
        add(leftpanel);

        //final stuff = {title: 'Welcome to the Editor!', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.', button1: 'Show me around.', button2: 'Okay.'};
        //openSubState(new EditorPopup(NOTICE, stuff));

        //me when I debug
        FlxG.watch.addMouse();

        FlxG.autoPause = false;
        playback.state = PAUSE;
        curType = NOTES;

        /*
        var ye = new FlxSprite().makeGraphic(100, 100, FlxColor.TRANSPARENT);
        ye.camera = camFRONT;
        FlxSpriteUtil.drawRoundRect(ye, 10, 10, 80, 80, 15, 15, FlxColor.BLUE);
        add(ye);
        */
    }

    var changeIndex:Int = 1;
    var typeButtons:Map<GridType, MoonSprite> = [];
    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        // ----- Input Stuff ----- //
        updateCursor();
        if (FlxG.keys.pressed.CONTROL)
        {
            // snapping!!
            if (MoonInput.justPressed(UI_LEFT) || MoonInput.justPressed(UI_RIGHT))
            {
                snapIndex = (MoonInput.justPressed(UI_LEFT) ? snapIndex - 1 + snaps.length : snapIndex + 1 ) % snaps.length;
                curSnap = snaps[snapIndex];
                //updatedebugTxt();
            }
        }
        else
        {
            final addition = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
            final advanceSecs = conductor.stepCrochet * 2 * addition;

            if (MoonInput.justPressed(UI_LEFT)) playback.time -= advanceSecs;
            else if (MoonInput.justPressed(UI_RIGHT)) playback.time += advanceSecs;
        }

        if (FlxG.keys.justPressed.SPACE)
            playback.state = (playback.state != PLAY) ? PLAY : PAUSE;

        if (FlxG.mouse.wheel != 0)
            playback.time -= FlxG.mouse.wheel * conductor.stepCrochet * (FlxG.keys.pressed.SHIFT ? 4 : 1);

        for(type => button in typeButtons)
            if(FlxG.mouse.overlaps(button, button.camera) && FlxG.mouse.justPressed)
                curType = type;

        // I should make this better...
        if(FlxG.keys.justPressed.ONE) curType = NOTES;
        else if(FlxG.keys.justPressed.TWO) curType = EVENTS;
        else if(FlxG.keys.justPressed.THREE) curType = CHARACTERS;
        else if(FlxG.keys.justPressed.FOUR) curType = GIMMICKS;
        else if(FlxG.keys.justPressed.FIVE) curType = SOUNDS;

        //////////////////////////////////

        // this should HOPEFULLY reduce update calls and draw calls :3
        // update: YEAHH IT DID nice.
        for(yeah in noteGroup.members)
        {
            final spr = cast(yeah, FlxSprite);
            spr.active = spr.visible = spr.isOnScreen();
        }

        for (member in gridGroup.members)
        {
            if (Std.isOfType(member, FlxSprite) && !Std.isOfType(member, FlxSpriteGroup))
            {
                final spr:FlxSprite = cast member;
                if (spr != cursor && spr != strum && !noteGroup.members.contains(spr))
                    spr.visible = spr.isOnScreen();
            }
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

        gridGroup.y = FlxMath.lerp(gridGroup.y, initialGridY - timeToY(conductor.time), elapsed * 28);

        // ----- Upon "note hit" ----- //
        for (note in noteGroup)
        {
            //TODO: toggle for both theese
            final n = cast(note, Note);

            if (n.strID != 'h' && conductor.time >= n.time && playback.state == PLAY)
            {
                n.strID = 'h';
                strum.onHit(n);

                //TOOD: make themmmm separate flxsoundses
                // so I cann like... what was I sayign?
                // oh yeah, so they can be stopped before playign to prvevent overlapping
                Paths.playSFX('toolkit/level-editor/hitsound-${n.lane.toLowerCase()}.wav');
            }

            if (n.strID == 'h' && conductor.time < n.time)
                n.strID = 'a';
        }
    }

    // this snaps the square cursor thing
    // ... I really should documment this code more. Before it turns into a giant mess of code...
    private function updateCursor():Void
    {
        final TOTAL_LANES:Int = NUM_LANES + 1;
        final relX = FlxG.mouse.viewX - gridGroup.x;
        final relY = FlxG.mouse.viewY - gridGroup.y - 24;

        if (relX < 0 || relX >= LANE_WIDTH * TOTAL_LANES || relY < 0)
        {
            cursor.visible = false;
            return;
        }

        cursor.visible = true;

        final laneNum:Int = Math.floor(relX / LANE_WIDTH);

        // snap its lane
        cursor.x = gridGroup.x + laneNum * LANE_WIDTH;

        // and snap its timee
        final unsnappedTime:Float = yToTime(relY);
        var snappedTime = unsnappedTime;

        if (curSnap != 0)
        {
            final seg = getTimeSeg(unsnappedTime);
            final lc = seg.stepCrochet * 4;
            final localTime = unsnappedTime - seg.startTime;
            final localBeat = localTime / lc;
            final snappedBeat = Math.round(localBeat * curSnap) / curSnap;
            snappedTime = seg.startTime + snappedBeat * lc;
        }

        cursor.y = gridGroup.y + timeToY(snappedTime);

        /// --- ON CLICK STUFFIES! --- ///
        //TODO: uhm, fix this?
        // "overlaps(noteGroup)" kinda sucks.

        // NOTE: THANKS TO GOATMYRIA (Luna) WE HAVE A DIFFERENT MODE FOR SELECTION
        //WOHOOOOO NO MORE THINKING ABOUT OVERLAPPING SHIT!!!
        if(FlxG.mouse.justPressed)
        {
            if(laneNum < NUM_LANES)
            {
                switch(curType)
                {
                    case NOTES:
                        final n = {
                            time: snappedTime,
                            data: laneNum % 4,
                            lane: (laneNum < 4) ? "opponent" : "p1",
                            type: 'default', //TODO: get current note type
                            duration: 0.0 //mf wants a float .`  _ .
                        };

                        createNote(n);
                        _internalChart.notes.push(n);
                        sfx('place-${FlxG.random.int(1, 6)}');

                    case EVENTS: trace('(place event)', "DEBUG");
                    case CHARACTERS: trace('(place character event)', "DEBUG");
                    case GIMMICKS: trace('(place gimmick event)', "DEBUG");
                    case SOUNDS: trace('(place sound event)', "DEBUG");
                }
            }
            else
            {
                if(!FlxG.mouse.overlaps(miscGroup))
                {
                    //trace('adding bookmark');
                    var bm = new Bookmark(laneNum * LANE_WIDTH, timeToY(snappedTime), LANE_HEIGHT);
                    miscGroup.add(bm);

                    scrollbar.addBookmark(snappedTime, bm.col);
                    bm.active = false;

                    if(_internalChart.bookmarks == null) _internalChart.bookmarks = [];
                    _internalChart.bookmarks.push({
                        text: bm.text,
                        time: snappedTime
                    });
                }
            }
        }
    }

    function createNote(n:NoteStruct)
    {
        var note = new Note(n.data, n.time, n.type, "v-slice", n.duration, conductor);
        note.state = CHART_EDITOR;
        note.active = false; //doesnt need updates, so!
        note.setGraphicSize(LANE_WIDTH, LANE_HEIGHT);
        note.updateHitbox();
        note.lane = n.lane;

        //TODO: update this once we have p2 support.
        final laneIndex = (n.lane == "p1") ? 4 : 0;
        note.x = (laneIndex + n.data) * LANE_WIDTH;
        note.y = timeToY(n.time);

        note.x += (LANE_WIDTH - note.width) / 2;

        noteGroup.add(note);
    }

    function timeToY(time:Float):Float
    {
        if (time <= 0) return 0;
        for (i in 0...segments.length)
        {
            final seg = segments[i];
            final nextStart:Float = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
            if (time < nextStart)
                return seg.startY + ((time - seg.startTime) / seg.stepCrochet * LANE_HEIGHT);
        }
        final last = segments[segments.length - 1];
        return last.startY + ((time - last.startTime) / last.stepCrochet * LANE_HEIGHT);
    }

    function yToTime(y:Float):Float
    {
        if (y <= 0) return 0;
        for (i in 0...segments.length)
        {
            final seg = segments[i];
            final nextY:Float = (i < segments.length - 1) ? segments[i + 1].startY : Math.POSITIVE_INFINITY;
            if (y < nextY)
                return seg.startTime + ((y - seg.startY) / LANE_HEIGHT * seg.stepCrochet);
        }
        final last = segments[segments.length - 1];
        return last.startTime + ((y - last.startY) / LANE_HEIGHT * last.stepCrochet);
    }

    function getTimeSeg(time:Float):{startTime:Float, startY:Float, stepCrochet:Float}
    {
        for (i in 0...segments.length)
        {
            final seg = segments[i];
            final nextStart:Float = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
            if (time < nextStart)
                return seg;
        }
        return segments[segments.length - 1];
    }

    function durationToHeight(startTime:Float, duration:Float):Float
        return timeToY(startTime + duration) - timeToY(startTime);

    public function sfx(p:String, general:Bool = false)
    {
        //TODO: CONVERT ALL SFX TO WAV
        if (playback.state != PLAY)
            FlxG.sound.play(Paths.sound((!general) ? 'toolkit/level-editor/$p.wav' : 'toolkit/general/$p.wav', 'sounds'), MoonSettings.callSetting('Editor Sounds') / 100);
    }

    function set_curType(curType:GridType):GridType
    {
        this.curType = curType;

        final typeStr:String = '$curType';
        sfx('${typeStr.toLowerCase()}Tab');

        for (member in noteGroup.members)
        {
            var note:Note = cast member;
            note.shader = (curType != NOTES) ? grayscale : null;
            note.alpha = (curType != NOTES) ? 0.20 : 1;
        }

        for(type => button in typeButtons)
            button.playAnim(type == curType ? 'click' : 'idle', true);

        return curType;
    }
}