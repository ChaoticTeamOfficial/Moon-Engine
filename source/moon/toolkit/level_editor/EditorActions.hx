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

import moon.game.obj.Song;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;

typedef NoteKey = {
    time:Float,
    lane:String,
    data:Int,
    type:String
};

interface IUndoAction {
    function undo(editor:LevelEditor):Void;
    function redo(editor:LevelEditor):Void;
}

class AddNotesAction implements IUndoAction {
    var notesData:Array<{ns:NoteStruct, li:Int}>;

    public function new(data:Array<{ns:NoteStruct, li:Int}>) {
        this.notesData = [for (d in data) {ns: LevelEditor.cloneNoteStruct(d.ns), li: d.li}];
    }

    public function undo(editor:LevelEditor):Void {
        for (d in notesData) {
            var n = editor.findNote(d.ns.time, d.ns.lane, d.ns.data, d.ns.type);
            if (n != null) editor.removeNote(n);
        }
        editor.deselectAll();
    }

    public function redo(editor:LevelEditor):Void {
        for (d in notesData)
            editor.addNote(d.ns, d.li);
        editor.deselectAll();
    }
}

class RemoveNotesAction implements IUndoAction {
    var notesData:Array<{ns:NoteStruct, li:Int}>;

    public function new(data:Array<{ns:NoteStruct, li:Int}>) {
        this.notesData = [for (d in data) {ns: LevelEditor.cloneNoteStruct(d.ns), li: d.li}];
    }

    public function undo(editor:LevelEditor):Void {
        for (d in notesData) {
            editor.addNote(d.ns, d.li);
        }
        editor.deselectAll();
    }

    public function redo(editor:LevelEditor):Void {
        for (d in notesData) {
            var n = editor.findNote(d.ns.time, d.ns.lane, d.ns.data, d.ns.type);
            if (n != null) editor.removeNote(n);
        }
        editor.deselectAll();
    }
}

class ChangeDurationsAction implements IUndoAction {
    var changes:Array<{key:NoteKey, oldDur:Float, newDur:Float}>;

    public function new(changes:Array<{key:NoteKey, oldDur:Float, newDur:Float}>) {
        this.changes = changes;
    }

    public function undo(editor:LevelEditor):Void
    {
        for (c in changes) {
            var n = editor.findNote(c.key.time, c.key.lane, c.key.data, c.key.type);
            if (n != null) {
                n.duration = c.oldDur;
                editor.noteStructs.get(n).duration = c.oldDur;
                editor.updateSustain(n);
                if (editor.selectedNotes.contains(n)) editor.updateHandlePos(n);
            }
        }
        editor.deselectAll();
    }

    public function redo(editor:LevelEditor):Void
    {
        for (c in changes) {
            var n = editor.findNote(c.key.time, c.key.lane, c.key.data, c.key.type);
            if (n != null) {
                n.duration = c.newDur;
                editor.noteStructs.get(n).duration = c.newDur;
                editor.updateSustain(n);
                if (editor.selectedNotes.contains(n)) editor.updateHandlePos(n);
            }
        }
        editor.deselectAll();
    }
}

class EditorActions {
    var undoStack:Array<IUndoAction> = [];
    var redoStack:Array<IUndoAction> = [];

    public function new() {}

    public function push(action:IUndoAction):Void {
        undoStack.push(action);
        redoStack = [];
    }

    public function undo(editor:LevelEditor):Void {
        if (undoStack.length > 0) {
            var action = undoStack.pop();
            action.undo(editor);
            redoStack.push(action);
        }
    }

    public function redo(editor:LevelEditor):Void {
        if (redoStack.length > 0) {
            var action = redoStack.pop();
            action.redo(editor);
            undoStack.push(action);
        }
    }
}