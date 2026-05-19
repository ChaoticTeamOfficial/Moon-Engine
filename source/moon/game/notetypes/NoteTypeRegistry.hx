package moon.game.notetypes;

import moon.game.obj.notes.Note;
import moon.game.PlayState;
import moon.game.events.EventFieldDef;
import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.toolkit.level_editor.LevelEditor.GridType;

/**
 * Registry for hardcoded and script-based note types.
 */
class NoteTypeRegistry
{
    private static var typeMap:Map<String, Class<BaseNoteType>>;

    @:dox(hide)
    public static function init():Void
    {
        typeMap = [
            'No Animation Note'  => NoAnimNote,
            'Alt Animation Note' => AltAnimNote
        ];
    }

    public static function isHardcoded(type:String):Bool
        return typeMap != null && typeMap.exists(type);

    public static function getHardcodedNames():Array<String>
        return [for (k in typeMap.keys()) k];

    /**
     * Executes onHit for the given note type, if it has one.
     */
    public static function executeHit(game:PlayState, note:Note, timing:String, isSustain:Bool):Void
    {
        if (typeMap == null) init();
        if (typeMap.exists(note.type))
        {
            getCls(note.type, game, note).onHit(timing, isSustain);
            return;
        }

        //TODO: this is NOT a good way to deal with this.
        /*if (Paths.exists('data/notetypes/${note.type}.hx'))
        {
            var script = new MoonScript();
            script.load('data/notetypes/${note.type}.hx');
            script.set('game', game);
            script.set('note', note);
            script.call('onHit', [timing, isSustain]);
        }*/
    }

    /**
     * Executes onMiss for the given note type, if it has one.
     */
    public static function executeMiss(game:PlayState, note:Note):Void
    {
        if (typeMap == null) init();

        if (typeMap.exists(note.type))
        {
            getCls(note.type, game, note).onMiss();
            return;
        }
    }

    /**
     * Executes onSpawn for the given note type, if it has one.
     */
    public static function executeSpawn(note:Note):Void
    {
        if (typeMap == null) init();

        if (typeMap.exists(note.type))
        {
            getCls(note.type, null, note).onSpawn();
            return;
        }
    }

    public static function getEditorData(type:String):Null<EventInfo>
    {
        if (getCls(type) != null)
            return getCls(type).getEditorData();

        return null;
    }

    public static function getEditorFields(type:String):Array<EventFieldDef>
    {
        if (getCls(type) != null)
            return getCls(type).getEditorFields();

        return [];
    }

    public static function processNoteValues(type:String, raw:Dynamic):Dynamic
    {
        if (getCls(type) != null)
            return getCls(type).processValues(raw);
        return raw;
    }

    private static function getCls(type:String, ?game:PlayState, ?note:Note)
    {
        if(typeMap == null) init();
        final cls = typeMap.get(type);
        if(cls != null)
            return Type.createInstance(cls, [game, note]);
        return null;
    }
}
