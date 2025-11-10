package moon.game.obj.notes;

import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import moon.backend.data.Chart.NoteStruct;
import flixel.group.FlxGroup;

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
        _noteOffset = MoonSettings.callSetting('Note Offset');
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
            struct.time - _noteOffset,
            struct.type,
            strum.members[struct.data].skin,
            struct.duration,
            conductor
        );
        note.speed = scrollSpeed;
        note.lane = struct.lane;
        return note; 
    }

    // === GETTERS === //
    inline function get_notes():Array<Note> return _notes;

    // === SETTERS === //
    function set_scrollSpeed(sp:Float):Float
    {
        scrollSpeed = sp / 2.4; // adoro sao paulo...
        for (note in _notes)
            note.speed = scrollSpeed;
        return scrollSpeed;
    }
}