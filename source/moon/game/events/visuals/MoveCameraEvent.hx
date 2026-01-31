package moon.game.events.visuals;

class MoveCameraEvent extends BaseEvent
{
    override public function execute():Void
    {
        game.setCameraFocus(
            event.values.character,
            [event?.values?.x ?? 0, event?.values?.y ?? 0],
            game.conductor.stepCrochet / 1000 * event.values.duration,
            {ease: game.resolveEase(event.values.ease)},
            (event.values.ease.toUpperCase() == 'INSTANT' || event.values.duration == 0)
        );
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Move Camera',
            description: "Move the camera to wherever you want.",
            category: VISUALS
        };
    }
}
