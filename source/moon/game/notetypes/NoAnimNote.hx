package moon.game.notetypes;

import moon.backend.gameplay.Timings.Judgement;
import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.toolkit.level_editor.LevelEditor.GridType;

/**
 * Note type that skips singing animations entirely.
 */
class NoAnimNote extends BaseNoteType
{
    //lol!!!! I figured I don't need to code anything :V
    override public function onHit(timing:Judgement, isSustain:Bool):Void
    {}

    override public function getEditorData():EventInfo
    {
        return {
            name: 'No Animation Note',
            description: 'The character will not play a singing animation when hitting this note.',
            category: NOTES
        };
    }
}
