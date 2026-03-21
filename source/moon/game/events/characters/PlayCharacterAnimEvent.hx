package moon.game.events.characters;

class PlayCharacterAnimEvent extends BaseEvent
{
    override public function execute():Void
    {
        final char = game.getChar(event.values.target);

        if (char != null)
        {
            if (event.values.forceOverride)
                char.forcePlayAnim(event.values.anim, event?.values?.force ?? true, event?.values?.reversed ?? false, event?.values?.frame ?? 0);
            else
                char.playAnim(event.values.anim, event?.values?.force ?? true, event?.values?.reversed ?? false, event?.values?.frame ?? 0);
        }
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Play Character Animation',
            description: 'Plays a selected Character animation.',
            category: CHARACTERS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'target', label: 'Target', type: DROPDOWN,
                defaultValue: 'player',
                options: ['player', 'opponent', 'spectator']
            },
            {
                name: 'anim', label: 'Animation', type: TEXT,
                defaultValue: 'idle-0'
            },
            {
                name: 'force', label: 'Force', type: CHECKBOX,
                defaultValue: true
            },
            {
                name: 'forceOverride', label: 'Override Current', type: CHECKBOX,
                defaultValue: true
            },
            {
                name: 'reversed', label: 'Reversed', type: CHECKBOX,
                defaultValue: false
            },
            {
                name: 'frame', label: 'Start Frame', type: NUMBER,
                defaultValue: 0, min: 0, max: 9999, step: 1
            }
        ];
    }
}
