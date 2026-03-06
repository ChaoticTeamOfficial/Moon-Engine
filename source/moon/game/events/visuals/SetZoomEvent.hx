package moon.game.events.visuals;

class SetZoomEvent extends BaseEvent
{
    override public function execute():Void
    {
        final baseZoom = game.stage?.cameraSettings?.zoom ?? 1;
        var targetZoom:Float = baseZoom;
        targetZoom = (event.values.mode == 'stage') ? baseZoom + (event.values.zoom - 1) : event.values.zoom;
        
        game.setCameraZoom(
            targetZoom,
            game.conductor.stepCrochet / 1000 * event.values.duration,
            {ease: MoonUtils.resolveEase(event.values.ease)},
            (event.values.ease.toUpperCase() == 'INSTANT' || event.values.duration == 0)
        );
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Set Zoom',
            description: "Set a zoom in the game's camera.",
            category: VISUALS
        };
    }
}
