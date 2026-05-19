package moon.toolkit.level_editor;

import moon.backend.data.Chart.NoteStruct;
import moon.backend.data.Chart.EventStruct;

enum EditorAction
{
    /** A note was placed. */
    NotePlace(note:NoteStruct);

    /** A note was deleted. */
    NoteDelete(note:NoteStruct);

    /** A note's sustain duration was changed. */
    NoteDuration(note:NoteStruct, oldDuration:Float, newDuration:Float);

    /** An event was placed. */
    EventPlace(event:EventStruct);

    /** An event was deleted. */
    EventDelete(event:EventStruct);
}

@:publicFields
class History
{
    /** Maximum number of steps kept in either stack. */
    static var maxSteps:Int = 100;

    private static var undoStack:Array<EditorAction> = [];
    private static var redoStack:Array<EditorAction> = [];

    /** Called once when the editor opens. */
    static function reset():Void
    {
        undoStack = [];
        redoStack = [];
    }

    /** Record a new action. */
    static function push(action:EditorAction):Void
    {
        undoStack.push(action);
        if (undoStack.length > maxSteps)
            undoStack.shift();

        // any new action invalidates the redo history
        redoStack = [];
    }

    /** Undo the last action. Returns true when something was actually undone. */
    static function undo():Bool
    {
        if (undoStack.length == 0) return false;

        final action = undoStack.pop();
        apply(invert(action));
        redoStack.push(action);
        return true;
    }

    /** Redo the last action. Returns true when something was actually redone. */
    static function redo():Bool
    {
        if (redoStack.length == 0) return false;

        final action = redoStack.pop();
        apply(action);
        undoStack.push(action);
        return true;
    }

    static var canUndo(get, never):Bool;
    static function get_canUndo() return undoStack.length > 0;

    static var canRedo(get, never):Bool;
    static function get_canRedo() return redoStack.length > 0;

    static function pushNotePlace(n:NoteStruct):Void
        push(NotePlace(cloneNote(n)));

    static function pushNoteDelete(n:NoteStruct):Void
        push(NoteDelete(cloneNote(n)));

    static function pushNoteDuration(n:NoteStruct, oldDur:Float, newDur:Float):Void
    {
        if (Math.abs(oldDur - newDur) < 0.01) return;
        push(NoteDuration(cloneNote(n), oldDur, newDur));
    }

    static function pushEventPlace(e:EventStruct):Void
        push(EventPlace(cloneEvent(e)));

    static function pushEventDelete(e:EventStruct):Void
        push(EventDelete(cloneEvent(e)));

    private static function invert(action:EditorAction):EditorAction
    {
        return switch (action)
        {
            case NotePlace(n): NoteDelete(n);
            case NoteDelete(n): NotePlace(n);
            case NoteDuration(n, old, now_): NoteDuration(n, now_, old);
            case EventPlace(e): EventDelete(e);
            case EventDelete(e): EventPlace(e);
        };
    }

    private static function apply(action:EditorAction):Void
    {
        final ed = LevelEditor.instance;
        if (ed == null) return;

        switch (action)
        {
            case NotePlace(n):
                ed.createNote(n);
                LevelEditor.chart.content.notes.push(n);
                LevelEditor.chart.content.notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

            case NoteDelete(n):
                LevelEditor.chart.content.notes = LevelEditor.chart.content.notes.filter(existing ->
                    !(Math.abs(existing.time - n.time) < 0.01
                    && existing.data == n.data
                    && existing.lane == n.lane)
                );

                ed.removeNoteSpr(n);

            case NoteDuration(n, _, newDur):
                for (existing in LevelEditor.chart.content.notes)
                {
                    if (Math.abs(existing.time - n.time) < 0.01
                        && existing.data == n.data
                        && existing.lane == n.lane)
                    {
                        existing.duration = newDur;
                        break;
                    }
                }

                ed.updateNoteDurSpr(n, newDur);

            case EventPlace(e):
                ed.createEvent(e);
                LevelEditor.chart.events.push(e);
                LevelEditor.chart.events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);

            case EventDelete(e):
                LevelEditor.chart.events = LevelEditor.chart.events.filter(existing ->
                    !(existing.tag == e.tag && Math.abs(existing.time - e.time) < 0.01)
                );
                ed.removeEventSpr(e);
        }
    }

    static function cloneNote(n:NoteStruct):NoteStruct
        return {time: n.time, data: n.data, lane: n.lane, type: n.type, duration: n.duration, values: n.values};

    static function cloneEvent(e:EventStruct):EventStruct
        return {tag: e.tag, values: e.values, time: e.time, lane: e.lane};
}