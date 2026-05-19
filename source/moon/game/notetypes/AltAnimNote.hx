package moon.game.notetypes;

import moon.game.events.EventFieldDef;
import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.toolkit.level_editor.LevelEditor.GridType;

/**
 * Note type that forces an alternate animation on hit.
 */
class AltAnimNote extends BaseNoteType
{
    override public function onHit(timing:String, isSustain:Bool):Void
    {
        if (game == null || isSustain) return;

        final handler = game.playField.inputHandlers.get(note.lane);
        if (handler?.attachedChar != null)
            handler.attachedChar.playAnim(note?.values?.anim ?? 'singLEFT-alt', true);
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Alt Animation Note',
            description: 'Plays a custom animation on the player character instead of the default sing animation.',
            category: NOTES
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'anim', label: 'Animation Name', type: TEXT,
                defaultValue: 'sing${MoonUtils.intToDir(note?.direction ?? 0).toUpperCase()}-alt'
            }
        ];
    }
}
