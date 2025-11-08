package moon.toolkit.level_editor;

import flixel.tweens.FlxTween;
import flixel.FlxG;
import flixel.FlxState;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteContainer;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import openfl.geom.ColorTransform;
import moon.toolkit.ui.*;
import moon.toolkit.level_editor.EditorActions;

import moon.game.obj.Song;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;

enum GridTypes {
    NOTES;
    EVENTS;
    CHARACTERS;
    SOUNDS;
    GIMMICKS;
}

/**
 * TODO LIST:
 * REMOVE HAXEUI, AND BUILD UP MY OWN UI FRAMEWORK FOR ALL THE TOOLKIT*.
 * FINISH ALL EVENT ICONS (Luna's Task)
 * SUSTAIN RESIZING
 * NOTE/EVENT SELECTING
 * CHART CONFIG
 * MINIPLAYER???
 * ICON TO DISPLAY WHO'S WHO
 * WAVEFORMS
 * HITSOUNDS
 * DRAG N DROP STUFF
 * EXPORT CHART TO OTHER ENGINES
 * blegh
 **/

class LevelEditor extends FlxState
{
    // ----------------------- //
    // Setup
    public var chart:Chart;
    public var conductor:Conductor;
    public var playback:Song;

    //public var miniPlayer:Miniplayer;

    private var camBACK:MoonCamera = new MoonCamera();
    private var camMID:MoonCamera = new MoonCamera();
    private var camFRONT:MoonCamera = new MoonCamera();

    public static var isMetronomeActive:Bool = false;

    // ----------------------- //
    // Grid Stuff
    public var allTypes:Array<GridTypes> = [NOTES, EVENTS, CHARACTERS, SOUNDS, GIMMICKS];
    public var curGrid(default, set):Int = 0;
    public var gridSize:Int = 64;
    public var laneCount:Int = 2;
    public var snapDiv:Int = 1;

    // ----------------------- //
    // Grid Sprites & Groups
    public var strumline:MoonSprite;
    public var strumArrows:FlxSpriteContainer;
    public var laneLines:FlxTypedSpriteGroup<MoonSprite>;
    public var gridContainer:FlxSpriteContainer;
    public var gridBG:FlxTiledSprite;
    var snapCursor:MoonSprite;

    public var notes:Array<Note> = [];
    public var noteData:Array<NoteStruct> = [];
    public var noteStructs:Map<Note, NoteStruct> = new Map();
    public var sustainSprites:Map<Note, MoonSprite> = new Map();

    // ----------------------- //
    // uhhh misc?
    public var selectedNotes:Array<Note> = [];
    public var sustainHandles:Map<Note, MoonSprite> = new Map();
    var selectionRect:MoonSprite;
    var selecting:Bool = false;
    var adjustingSustain:Bool = false;
    var dragStartX:Float = 0;
    var dragStartY:Float = 0;
    var startDurations:Map<Note, Float> = new Map();

    var editorActions:EditorActions;

    var tabGroup:FlxSpriteGroup;

    override public function create()
    {
        //TODO: get actual song selected by user.
        final song = 'tko2';
        final diff = 'hard';
        final mix = 'bf';

        camBACK.bgColor = 0x00000000;
        camMID.bgColor = 0x00000000;
        camFRONT.bgColor = 0x00000000;

        FlxG.mouse.visible = true;

        FlxG.cameras.add(camBACK, true);
        FlxG.cameras.add(camMID, false);
        FlxG.cameras.add(camFRONT, false);

        chart = new Chart(song, diff, mix);

        conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[0]);
        conductor.onBeat.add(beatHit);
        
        playback = new Song(
            song,
            mix,
            (diff == 'erect' || diff == 'nightmare'),
            conductor
        );

        var bg = new MoonSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromRGB(30, 29, 31));
        add(bg);

        //miniPlayer = new Miniplayer(this);
        //miniPlayer.camera = camMID;
        //add(miniPlayer);

        
        gridContainer = new FlxSpriteContainer();
        add(gridContainer);
        
        laneLines = new FlxTypedSpriteGroup<MoonSprite>();

        drawGrid(playback.fullLength);
        
        gridContainer.add(laneLines);

        for (n in chart.content.notes)
        {
            final laneIndex = chart.content.meta.lanes.indexOf(n.lane);
            if (laneIndex >= 0)
                addNote(n, laneIndex);
        }

        //TODO: change x pos
        gridContainer.x = (FlxG.width - gridContainer.width) / 2;
        gridContainer.y = 0;

        snapCursor = new MoonSprite().makeGraphic(gridSize, gridSize, FlxColor.WHITE);
        snapCursor.alpha = 0.4;
        snapCursor.camera = camMID;
        add(snapCursor);

        strumline = new MoonSprite().makeGraphic(Std.int(gridContainer.width), 5, FlxColor.WHITE);
        strumline.x = gridContainer.x;
        strumline.y = 120;
        strumline.alpha = 0.3;
        strumline.camera = camMID;
        add(strumline);

        strumArrows = new FlxSpriteContainer();
        for(a in 0...laneCount)
        {
            for(i in 0...4)
                {
                    var ok = new MoonSprite().loadGraphic(Paths.image('toolkit/level-editor/strumline'), true, 32, 32);
                    ok.animation.add('a', [i], 1, true);
                    ok.animation.play('a');
                    strumArrows.add(ok);

                ok.setGraphicSize(gridSize, gridSize);
                ok.antialiasing = false;
                ok.updateHitbox();

                ok.x = strumline.x + ((a * 4 + i) * gridSize);
                ok.y = strumline.y;

                ok.color = getColor(i);
                ok.alpha = 0.0001;
                ok.blend = ADD;

                ok.ID = i;
                ok.strID = chart.content.meta.lanes[a];
                //trace('${chart.content.meta.lanes[a]} & $i', "DEBUG");
            }
        }

        strumArrows.camera = camMID;
        add(strumArrows);

        playback.state = PAUSE;

        isFullscreen = false;
        changeTab(0);

        selectionRect = new MoonSprite();
        selectionRect.makeGraphic(1, 1, FlxColor.fromRGB(0, 0, 255, 100));
        add(selectionRect);
        selectionRect.visible = false;
        
        editorActions = new EditorActions();
        
        tabGroup = new FlxSpriteGroup();
        tabGroup.camera = camFRONT;
        add(tabGroup);
        camFRONT.scroll.x = -500;
        for (i in 0...allTypes.length)
        {
            var type = allTypes[i];
            var tab = new MoonSprite(300, 528 + i * 196);
            final str:String = '$type';
            tab.loadGraphic(Paths.image('toolkit/level-editor/button-${str.toLowerCase()}'));
            tab.ID = i;
            tab.scale.set(6, 6);
            tab.updateHitbox();
            tab.antialiasing = false;
            tabGroup.add(tab);
        }

        updateGridAppearance();
    }

    var isFullscreen(default, set):Bool = false;
    override public function update(elapsed:Float)
    {
        conductor.time = playback.time;
        strumline.alpha = FlxMath.lerp(strumline.alpha, 0.3, elapsed * 2);

        super.update(elapsed);

        if(FlxG.keys.justPressed.F)
            isFullscreen = !isFullscreen;

        if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z)
            editorActions.undo(this);

        if(FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Y)
            editorActions.redo(this);

        if(!isFullscreen)
        {
            // ----- DATA ------ //
            final localX = FlxG.mouse.x - gridContainer.x;
            final localY = FlxG.mouse.y - gridContainer.y; //idk it seems wrong

            final col = Math.floor(localX / gridSize);
            final laneIndex = Math.floor(col / 4);
            final data = col % 4;
            final snappedTime = getSnappedTime(localY);

            final addition = (FlxG.keys.pressed.SHIFT) ? 3 : 1;
            final advanceSecs = 500 * addition;

            // ----- Input Stuff ----- //
            if(FlxG.keys.justPressed.SPACE) playback.state = (playback.state != PLAY) ? PLAY : PAUSE;

            if(MoonInput.justPressed(UI_LEFT)) playback.time -= advanceSecs;
            else if (MoonInput.justPressed(UI_RIGHT)) playback.time += advanceSecs;

            if (FlxG.keys.justPressed.TAB) changeTab(1);

            for (tab in tabGroup.members)
            {
                if (FlxG.mouse.overlaps(tab, camFRONT) && FlxG.mouse.justPressed)
                {
                    curGrid = tab.ID;
                }
            }

            if (curGrid == 0)
            {
                if (FlxG.keys.pressed.CONTROL && FlxG.mouse.justPressed && !adjustingSustain)
                {
                    selecting = true;
                    dragStartX = FlxG.mouse.x;
                    dragStartY = FlxG.mouse.y;
                    selectionRect.visible = true;
                }

                if (selecting)
                {
                    if (FlxG.mouse.pressed)
                    {
                        var minX = Math.min(dragStartX, FlxG.mouse.x);
                        var minY = Math.min(dragStartY, FlxG.mouse.y);
                        var w = Math.abs(FlxG.mouse.x - dragStartX);
                        var h = Math.abs(FlxG.mouse.y - dragStartY);
                        selectionRect.setPosition(minX, minY);
                        selectionRect.setGraphicSize(Std.int(w), Std.int(h));
                        selectionRect.updateHitbox();
                    }
                    else
                    {
                        selecting = false;
                        selectionRect.visible = false;
                        deselectAll();
                        for (n in notes)
                            if (selectionRect.overlaps(n))
                                selectNote(n);
                    }
                }

                if (FlxG.keys.justPressed.DELETE && selectedNotes.length > 0)
                {
                    var toRemove:Array<{ns:NoteStruct, li:Int}> = [];
                    for (n in selectedNotes) {
                        var ns = noteStructs.get(n);
                        var li = chart.content.meta.lanes.indexOf(n.lane);
                        toRemove.push({ns: cloneNoteStruct(ns), li: li});
                    }
                    editorActions.push(new RemoveNotesAction(toRemove));

                    for (n in selectedNotes.copy())
                        removeNote(n);

                    deselectAll();
                }

                // Handle right-click deletion for single note
                if (FlxG.mouse.justPressedRight)
                {
                    final hoveredNote = getHoveredNote();
                    if (hoveredNote != null)
                    {
                        var ns = noteStructs.get(hoveredNote);
                        var li = chart.content.meta.lanes.indexOf(hoveredNote.lane);
                        var toRemove = [{ns: cloneNoteStruct(ns), li: li}];
                        editorActions.push(new RemoveNotesAction(toRemove));

                        removeNote(hoveredNote);
                        if (selectedNotes.contains(hoveredNote))
                            deselectNote(hoveredNote);
                    }
                }

                // Handle sustain adjusting or note selection/placement
                if (!selecting && !adjustingSustain && FlxG.mouse.justPressed && FlxG.mouse.viewY > strumline.y)
                {
                    final hoveredHandle = getHoveredHandle();
                    if (hoveredHandle != null)
                    {
                        adjustingSustain = true;
                        if (!selectedNotes.contains(hoveredHandle))
                        {
                            deselectAll();
                            selectNote(hoveredHandle);
                        }
                        dragStartY = FlxG.mouse.y;
                        startDurations = new Map();
                        for (n in selectedNotes)
                        {
                            startDurations.set(n, n.duration);
                            if (n.duration > 0 && !sustainSprites.exists(n))
                                drawSustain(n);
                        }
                    }
                    else
                    {
                        var hoveredNote = getHoveredNote();
                        var hoveredSustain = getHoveredSustain();
                        
                        if (hoveredNote != null || hoveredSustain != null)
                        {
                            // Use the note from either the note itself or the sustain
                            var targetNote = (hoveredNote != null) ? hoveredNote : hoveredSustain;
                            
                            if (!FlxG.keys.pressed.CONTROL)
                            {
                                deselectAll();
                                selectNote(targetNote);
                            }
                            else
                            {
                                if (selectedNotes.contains(targetNote))
                                    deselectNote(targetNote);
                                else
                                    selectNote(targetNote);
                            }
                        }
                        else
                            placeNote(col, localY);
                    }
                }

                // Handle adjusting sustains
                if (adjustingSustain && FlxG.mouse.pressed)
                {
                    final currentLocalY = FlxG.mouse.y - gridContainer.y;
                    final startLocalY = dragStartY - gridContainer.y;
                    final deltaTime = getSnappedTime(currentLocalY) - getSnappedTime(startLocalY);

                    for (n in selectedNotes)
                    {
                        var newDur = startDurations.get(n) + deltaTime;
                        if (newDur < 0) newDur = 0;
                        n.duration = newDur;
                        noteStructs.get(n).duration = newDur;

                        if (newDur > 0)
                        {
                            var susHeight = Math.max(8, getTimePos(n.time + newDur) - getTimePos(n.time));
                            var sus = sustainSprites.get(n);
                            if (sus == null)
                                drawSustain(n);
                            else
                            {
                                sus.makeGraphic(gridSize - 4, Std.int(susHeight), getColor(n.direction));
                                final capHeight = Math.min(16, susHeight);
                                sus.pixels.fillRect(new openfl.geom.Rectangle(0, susHeight - capHeight, sus.width, capHeight), FlxColor.WHITE);
                            }
                            final sus = sustainSprites.get(n);
                            // Center the sustain properly
                            sus.x = n.x + 2; // Small padding from grid edge
                            sus.y = n.y + gridSize;
                        }
                        else if (sustainSprites.exists(n))
                        {
                            gridContainer.remove(sustainSprites.get(n));
                            sustainSprites.get(n).destroy();
                            sustainSprites.remove(n);
                        }

                        updateHandlePos(n);
                    }
                }
                else if (adjustingSustain)
                {
                    adjustingSustain = false;

                    var changes:Array<{key:NoteKey, oldDur:Float, newDur:Float}> = [];
                    for (n in selectedNotes) {
                        var newDur = n.duration;
                        var oldDur = startDurations.get(n);
                        if (newDur != oldDur) {
                            var key:NoteKey = {time: n.time, lane: n.lane, data: n.direction, type: n.type};
                            changes.push({key: key, oldDur: oldDur, newDur: newDur});
                        }
                    }
                    if (changes.length > 0) {
                        editorActions.push(new ChangeDurationsAction(changes));
                    }
                }
            }

            // ----- Upon note hit ----- //
            for (n in notes)
            {
                // If not hit yet, and time has passed, and the song is playing
                if (n.strID != 'h' && conductor.time >= n.time && playback.state == PLAY)
                {
                    n.strID = 'h';
                    for(i in 0...strumArrows.members.length)
                    {
                        final s = cast(strumArrows.members[i], MoonSprite);
                        
                        if (s.strID.toLowerCase() == n.lane.toLowerCase() && s.ID == n.direction)
                        {
                            s.alpha = 1;
                            s.scale.set(1, 1);
                            //trace('${s.strID.toLowerCase()} to ${n.lane.toLowerCase()}', "DEBUG");
                        }
                    }
                }

                if (n.strID == 'h' && conductor.time < n.time)
                    n.strID = 'a';
            }

            // ----- Other ----- //
            for(s in strumArrows.members)
            {
                s.alpha = FlxMath.lerp(s.alpha, 0.0001, elapsed * 6);
                s.scale.x = s.scale.y = FlxMath.lerp(s.scale.x, 1.6, elapsed * 9);
            }

            FlxG.mouse.enabled = FlxG.mouse.visible = true;

            snapCursor.visible = (col >= 0 && col < chart.content.meta.lanes.length * 4);
            if (snapCursor.visible)
            {
                snapCursor.x = (laneIndex * 4 + data) * gridSize + gridContainer.x;
                snapCursor.y = getTimePos(snappedTime) + gridContainer.y;
            }

            gridContainer.y = strumline.y - getTimePos(playback.time);

            for (obj in notes)
                obj.active = obj.visible = obj.isOnScreen();
        }
        else
            FlxG.mouse.enabled = FlxG.mouse.visible = false;
    }

    function drawGrid(songLength:Float):Void
    {
        //---- grid ----//

        if (gridBG != null) gridContainer.remove(gridBG);

        final totalHeight = Math.ceil((songLength / conductor.stepCrochet) * gridSize);
        var base = FlxGridOverlay.create(gridSize, gridSize, gridSize * laneCount, gridSize * 2, true, 0xFF2a2a2c, 0xFF373639);

        final totalCols = chart.content.meta.lanes.length * 4;

        gridBG = new FlxTiledSprite(null, gridSize * totalCols, gridSize);
        gridBG.loadGraphic(base.graphic);
        gridBG.height = totalHeight;
        gridContainer.add(gridBG);

        //---- lines ----//

        if(laneLines.members.length > 0) laneLines.clear();

        final lineWidth = gridSize * totalCols;
        final beatCount = Math.ceil(songLength / conductor.crochet);

        for (i in 0...beatCount)
        {
            var line = new MoonSprite().makeGraphic(lineWidth, 2, (i % conductor.numerator == 0) ? 0xFF777777 : FlxColor.BLACK);
            line.x = 0;
            line.y = getTimePos(i * conductor.crochet);

            laneLines.add(line);
        }

        for (i in 0...chart.content.meta.lanes.length + 1)
        {
            var line = new MoonSprite().makeGraphic(2, Std.int(totalHeight), FlxColor.BLACK);
            line.x = i * 4 * gridSize;
            line.y = 0;
            laneLines.add(line);
        }
    }

    public function placeNote(col, y):Void
    {
        if (col < 0 || col >= chart.content.meta.lanes.length * 4) return;

        final laneIndex = Math.floor(col / 4);
        final snappedTime = getSnappedTime(y);

        var ns:NoteStruct = {
            lane: chart.content.meta.lanes[laneIndex],
            data: col % 4,
            time: snappedTime,
            type: "normal",
            duration: 0
        };

        noteData.push(ns);
        final note = addNote(ns, laneIndex);

        var toAdd = [{ns: cloneNoteStruct(ns), li: laneIndex}];
        editorActions.push(new AddNotesAction(toAdd));

        deselectAll();
        selectNote(note);
        sfx('addNote-${FlxG.random.int(1, 6)}');
    }

    public function addNote(data:NoteStruct, laneIndex:Int):Note
    {
        var note = new Note(data.data, data.time, data.type, 'mooncharter', data.duration, conductor);
        note.state = CHART_EDITOR;
        note.setGraphicSize(gridSize, gridSize);
        note.updateHitbox();
        note.lane = data.lane;

        note.x = (laneIndex * 4 + data.data) * gridSize;
        note.y = getTimePos(data.time);
        note.strID = 'a';

        gridContainer.add(note);

        if (note.duration > 0)
            drawSustain(note);

        noteStructs.set(note, data);
        notes.push(note);
        return note;
    }

    public function drawSustain(note:Note)
    {
        var susHeight = Math.max(8, getTimePos(note.time + note.duration) - getTimePos(note.time));
        var sus = new MoonSprite().makeGraphic(gridSize - 4, Std.int(susHeight), getColor(note.direction));

        sus.x = note.x + 2;
        sus.y = note.y + gridSize;
        
        var capHeight = Math.min(8, susHeight);
        sus.pixels.fillRect(new openfl.geom.Rectangle(0, susHeight - capHeight, sus.width, capHeight), FlxColor.WHITE);
        gridContainer.add(sus);
        sustainSprites.set(note, sus);
    }

    public function updateSustain(note:Note):Void
    {
        if (note.duration > 0) {
            var susHeight = Math.max(8, getTimePos(note.time + note.duration) - getTimePos(note.time));
            var sus = sustainSprites.get(note);
            if (sus == null) {
                drawSustain(note);
            } else {
                sus.makeGraphic(gridSize - 4, Std.int(susHeight), getColor(note.direction));
                var capHeight = Math.min(8, susHeight);
                sus.pixels.fillRect(new openfl.geom.Rectangle(0, susHeight - capHeight, sus.width, capHeight), FlxColor.WHITE);
                sus.x = note.x + 2;
                sus.y = note.y + gridSize;
            }
        } else if (sustainSprites.exists(note)) {
            gridContainer.remove(sustainSprites.get(note));
            sustainSprites.get(note).destroy();
            sustainSprites.remove(note);
        }
    }

    public function beatHit(curBeat:Float)
    {
        if(curBeat % conductor.numerator == 0)
        {
            strumline.alpha = 1;
        }
    }

    function getTimePos(time:Float):Float
        return FlxMath.remapToRange(time, 0, playback.fullLength, 0, (playback.fullLength / conductor.stepCrochet) * gridSize);

    function getSnappedTime(localY:Float):Float
    {
        final snapLen = conductor.stepCrochet / snapDiv;
        final rawTime = localY / gridSize * conductor.stepCrochet;
        return Math.round(rawTime / snapLen) * snapLen;
    }

    function getColor(data:Int):FlxColor
    {
        final colors = [0xFF7f16ff, 0xFF37a5ff, 0xFF61d041, 0xFFff3f3f];
        return colors[data % colors.length];
    }

    public function sfx(p:String)
    {
        if(playback.state != PLAY)
            Paths.playSFX('toolkit/level-editor/$p');
    }

    function changeTab(change:Int = 0):Void
        curGrid = flixel.math.FlxMath.wrap(curGrid + change, 0, allTypes.length - 1);

    @:noCompletion function set_curGrid(curGrid:Int):Int
    {
        this.curGrid = curGrid;

        final strType = '${allTypes[curGrid]}';
        sfx(strType.toLowerCase() + 'Tab');

        updateGridAppearance();

        return this.curGrid;
    }

    function updateGridAppearance():Void
    {
        var isNotes = (curGrid == 0);

        for (n in notes)
        {
            if (!selectedNotes.contains(n))
                n.color = isNotes ? FlxColor.WHITE : FlxColor.GRAY;
        }

        for (n => s in sustainSprites)
        {
            s.alpha = isNotes ? 1 : 0.3;
        }

        for (s in strumArrows.members)
        {
            s.color = isNotes ? getColor(s.ID) : FlxColor.GRAY;
        }

        try{
            for (tab in tabGroup.members)
                tab.alpha = (tab.ID == curGrid) ? 1 : 0.5;
        } catch(e){}
    }

    @:noCompletion function set_isFullscreen(isFS:Bool):Bool
    {
        this.isFullscreen = isFS;

        if(!isFullscreen)
        {
            camFRONT.zoom = 0.25;
            camFRONT.setPosition(-400, -170);
        }
        else
        {
            camFRONT.zoom = 1;
            camFRONT.setPosition();
        }

        return this.isFullscreen;
    }

    public function getHoveredNote():Note
    {
        for (n in notes)
            if (FlxG.mouse.overlaps(n) && curGrid == 0)
                return n;
        return null;
    }

    public function getHoveredSustain():Note
    {
        for (n => s in sustainSprites)
            if (FlxG.mouse.overlaps(s) && curGrid == 0)
                return n;
        return null;
    }

    public function getHoveredHandle():Note
    {
        for (n => h in sustainHandles)
            if (FlxG.mouse.overlaps(h) && curGrid == 0)
                return n;
        return null;
    }

    public function selectNote(note:Note):Void
    {
        if (!selectedNotes.contains(note))
        {
            selectedNotes.push(note);
            note.color = FlxColor.GRAY;
            createHandle(note);
        }
    }

    public function deselectNote(note:Note):Void
    {
        selectedNotes.remove(note);
        note.color = curGrid == 0 ? FlxColor.WHITE : FlxColor.GRAY;
        if (sustainHandles.exists(note))
        {
            gridContainer.remove(sustainHandles.get(note));
            sustainHandles.get(note).destroy();
            sustainHandles.remove(note);
        }
    }

    public function deselectAll():Void
    {
        for (n in selectedNotes)
        {
            n.color = curGrid == 0 ? FlxColor.WHITE : FlxColor.GRAY;
            if (sustainHandles.exists(n))
            {
                gridContainer.remove(sustainHandles.get(n));
                sustainHandles.get(n).destroy();
                sustainHandles.remove(n);
            }
        }
        selectedNotes = [];
    }

    public function createHandle(note:Note):Void
    {
        if (!sustainHandles.exists(note))
        {
            var handle = new MoonSprite().makeGraphic(Std.int(gridSize), Std.int(gridSize / 2), FlxColor.YELLOW);
            gridContainer.add(handle);
            sustainHandles.set(note, handle);
            updateHandlePos(note);
        }
    }

    public function updateHandlePos(note:Note):Void
    {
        if (sustainHandles.exists(note))
        {
            final h = sustainHandles.get(note);
            if (note.duration == 0)
            {
                h.visible = true;
                h.alpha = 0.6;
                h.x = note.x + (note.width - h.width) / 2;
                h.y = note.y + (note.height / 2 - h.height / 2);
            }
            else
            {
                h.visible = false;
                updateSustain(note);
            }
        }
    }

    public function findNote(time:Float, lane:String, data:Int, type:String):Note
    {
        for (n in notes)
            if (n.time == time && n.lane == lane && n.direction == data && n.type == type)
                return n;

        return null;
    }

    public static function cloneNoteStruct(ns:NoteStruct):NoteStruct
    {
        return {
            lane: ns.lane,
            data: ns.data,
            time: ns.time,
            type: ns.type,
            duration: ns.duration
        };
    }

    public function removeNote(note:Note):Void
    {
        notes.remove(note);
        final ns = noteStructs.get(note);
        noteData.remove(ns);
        noteStructs.remove(note);

        if (sustainSprites.exists(note))
        {
            gridContainer.remove(sustainSprites.get(note));
            sustainSprites.get(note).destroy();
            sustainSprites.remove(note);
        }

        if (sustainHandles.exists(note))
        {
            gridContainer.remove(sustainHandles.get(note));
            sustainHandles.get(note).destroy();
            sustainHandles.remove(note);
        }

        gridContainer.remove(note);
        note.destroy();
    }
}