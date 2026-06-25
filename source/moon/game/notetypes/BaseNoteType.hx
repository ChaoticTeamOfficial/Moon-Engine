package moon.game.notetypes;

import moon.backend.gameplay.Timings.Judgement;
import moon.game.obj.notes.Note;
import moon.game.PlayState;
import moon.game.events.EventFieldDef;
import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.toolkit.level_editor.LevelEditor.GridType;

/**
 * Base class for all hardcoded note types.
 */
class BaseNoteType
{
	public var game:PlayState;
	public var note:Note;

	public function new(game:PlayState, note:Note)
	{
		this.game = game;
		this.note = note;
	}

	/**
	 * Called when the note is hit by the player.
	 * @param timing    The judgement. (E.G. 'sick' or SICK)
	 * @param isSustain Whether this is a sustain tick.
	 */
	public function onHit(timing:Judgement, isSustain:Bool):Void
	{
	}

	/**
	 * Called when the note is missed.
	 */
	public function onMiss():Void
	{
	}

	/**
	 * Called when the note is spawned.
	 */
	public function onSpawn():Void
	{
	}

	/**
	 * Get editor metadata for this note.
	 */
	public function getEditorData():EventInfo
	{
		return {
			name: 'Unknown Note Type',
			description: 'No description.',
			category: NOTES
		};
	}

	/**
	 * Returns the interactive field definitions shown in the Level Editor's Library panel.
	 */
	public function getEditorFields():Array<EventFieldDef> return [];

	/**
	 * Remaps flat form values from EventFormUI into the structure stored in note.values.
	 */
	public function processValues(raw:Dynamic):Dynamic return raw;
}
