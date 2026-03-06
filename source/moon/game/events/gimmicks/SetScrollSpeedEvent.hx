package moon.game.events.gimmicks;

class SetScrollSpeedEvent extends BaseEvent
{
	var scrollTween:FlxTween;
    override public function execute():Void
    {
    	MoonUtils.cancelActiveTwn(scrollTween);

        //TODO: Make it possible to change for each lane
        // currently it changes for both only.
        var scroll:Float = event.values.scroll;
        final spawner = game.playField.noteSpawner;

        if(!event.values.absolute)
        	scroll *= game.playField.chart.content.meta.scrollSpd;

        if(event.values.ease.toLowerCase() == 'instant') spawner.scrollSpeed = scroll;
        else scrollTween = FlxTween.tween(spawner, {scrollSpeed: scroll}, game.conductor.stepCrochet / 1000 * event.values.duration, {ease: MoonUtils.resolveEase(event.values.ease)});

        trace('Changing scroll speed to ${scroll}!', "DEBUG");
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Set Lane Scroll Speed',
            description: "Changes a scroll speed of a specified lane.",
            category: GIMMICKS
        };
    }
}
