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

        if (!event.values.absolute)
            scroll *= game.playField.chart.content.meta.scrollSpd;

        if (event.values.ease.toLowerCase() == 'instant')
            spawner.scrollSpeed = scroll;
        else
            scrollTween = FlxTween.tween(
                spawner, {scrollSpeed: scroll},
                game.conductor.stepCrochet / 1000 * event.values.duration,
                {ease: MoonUtils.resolveEase(event.values.ease)}
            );

        //trace('Changing scroll speed to ${scroll}!', "DEBUG");
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Set Lane Scroll Speed',
            description: 'Changes a scroll speed of a specified lane.',
            category: GIMMICKS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'scroll', label: 'Speed', type: NUMBER,
                defaultValue: 1.0, min: 0.1, max: 10.0, step: 0.05
            },
            {
                name: 'duration', label: 'Duration (steps)', type: NUMBER,
                defaultValue: 8, min: 0, max: 999, step: 1
            },
            {
                name: 'ease', label: 'Easing', type: DROPDOWN,
                defaultValue: 'expoOut',
                options: [
                    'expoOut', 'expoIn', 'expoInOut',
                    'circOut', 'circIn', 'circInOut',
                    'quadOut', 'quadIn', 'quadInOut',
                    'linear', 'INSTANT'
                ]
            },
            {
                name: 'absolute', label: 'Absolute Speed', type: CHECKBOX,
                defaultValue: true
            }
        ];
    }
}