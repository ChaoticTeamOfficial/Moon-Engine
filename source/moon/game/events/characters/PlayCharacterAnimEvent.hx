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
            description: "Plays a selected Character animation.",
            category: CHARACTERS
        };
    }
}
