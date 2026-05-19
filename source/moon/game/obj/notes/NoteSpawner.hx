package moon.game.obj.notes;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import moon.backend.data.Chart.NoteStruct;
import flixel.group.FlxGroup;
import moon.game.notetypes.*;

class NoteSpawner extends FlxGroup
{
    public var notes(get, never):Array<Note>;
    final _notes:Array<Note> = [];
    final _strumlineMap:Map<String, Strumline> = new Map();

    var conductor:Conductor;
    var nextNoteIndex:Int = 0;

    public var scrollSpeed(default, set):Float = 1.0;
    public var spawnThreshold:Float = 700;

    var _noteOffset:Float = 0;
    public var noteOffset(get, set):Float;

    var _downscroll:Bool = false;

    public function new(noteStructs:Array<NoteStruct>, strumlines:Array<Strumline>, conductor:Conductor)
    {
        super();
        this.conductor = conductor;

        // build strumline lookup map
        for (strum in strumlines)
            _strumlineMap[strum.playerID] = strum;

        // create and sort notes
        for (struct in noteStructs)
        {
            final note = createNoteFromStruct(struct);
            if (note != null)
                _notes.push(note);
        }
        _notes.sort((a, b) -> Std.int(a.time - b.time));
        updateCachedSettings();
    }

    override function update(dt:Float):Void
    {
        updateCachedSettings();
        updateSpawnThreshold();

        super.update(dt);

        final spawnTime = conductor.time + spawnThreshold;
        var i = nextNoteIndex;
        while (i < _notes.length && _notes[i].time <= spawnTime)
            recycleNote(_notes[i++]);

        nextNoteIndex = i;
    }

    inline function updateCachedSettings():Void
    {
        noteOffset = MoonSettings.callSetting('Note Offset');
        _downscroll = MoonSettings.callSetting('Downscroll');
    }

    inline function updateSpawnThreshold():Void
    {
        final newThreshold = (scrollSpeed <= 0.9) ? 3000 : (scrollSpeed <= 0.4) ? 5000 : 700;
        if (spawnThreshold != newThreshold)
            spawnThreshold = newThreshold;
    }

    function recycleNote(note:Note):Void
    {
        final strum = _strumlineMap[note.lane];
        if (strum == null) return;

        final group = strum.members[note.direction];
        if (group?.notesGroup == null) return;

        group.notesGroup.recycle(Note, () -> {
            note.receptor = strum.members[note.direction];
            note.visible = false;
            note.speed = scrollSpeed;
            note.state = NONE;
            if (note.duration > 0)
                recycleSustain(note, group.sustainsGroup);
            return note;
        });
    }

    function recycleSustain(note:Note, sustainGroup:FlxTypedSpriteGroup<NoteSustain>):Void
    {
        sustainGroup.recycle(NoteSustain, () -> {
            var sustain = note.child;
            if (sustain == null)
            {
                sustain = new NoteSustain(note);
                note.child = sustain;
            }
            sustain.downscroll = _downscroll;
            return sustain;
        });
    }

    function createNoteFromStruct(struct:NoteStruct):Note
    {
        final strum = _strumlineMap[struct.lane];
        if (strum == null || strum.members[struct.data] == null) return null;

        final note = new Note(
            struct.data,
            struct.time + _noteOffset,
            struct.type,
            strum.members[struct.data].skin,
            struct.duration,
            conductor
        );
        note.values = struct.values;
        note.speed = scrollSpeed;
        note.lane = struct.lane;
        note.quantColor = getQuantColor(struct.time, conductor);
        NoteTypeRegistry.executeSpawn(note);
        return note; 
    }

    /**
     * Returns 0-9 based on how the note is snapped inside the current beat/step
     */
    public static function getQuantColor(time:Float, conductor:Conductor):Int
        return Std.int((Math.round((time % conductor.crochet) / (conductor.crochet / 32)) * 10) / 32);

    public function updateNoteScroll()
    {
        for (note in _notes)
            note.updateNotePos();
    }

    // === GETTERS === //
    inline function get_notes():Array<Note> return _notes;

    function get_noteOffset():Float return _noteOffset;

    // === SETTERS === //
    function set_scrollSpeed(sp:Float):Float
    {
        scrollSpeed = sp / 2.4; // adoro sao paulo...
        for (note in _notes)
            note.speed = scrollSpeed;
        return scrollSpeed;
    }

    function set_noteOffset(value:Float):Float
    {
        final diff = value - _noteOffset;
        _noteOffset = value;

        for (note in _notes)
            note.time += diff;

        return value;
    }
}