package moon.game.events.visuals;

class SetCameraMode extends BaseEvent
{
    /**
     * The currently active note-hit handler for dynamic singing.
     */
    private static var _singHandler:Dynamic = null;

    /**
     * Accumulates the current nudge offset applied to the camera follower.
     */
    private static var _nudgeOffset:FlxPoint = FlxPoint.get();

    private static var _nudgeTween:FlxTween = null;

    // Direction impulse vectors: [left, down, up, right]
    private static final DIRS:Array<Array<Float>> = [[-1.0,  0.0], [ 0.0,  1.0], [ 0.0, -1.0], [ 1.0,  0.0]];

    override public function execute():Void
    {
        //separate em nicely cuz why not!?
        _applyHandheld();
        _applyDynamicSinging();
    }

    private function _applyHandheld():Void
    {
        final mode:String = event?.values?.handheld ?? 'off';

        game.camGAME.handheldVFX = switch (mode)
        {
            case 'low': { distance: 1.5, xIntensity: 1.0,  yIntensity: 0.7,  speed: 2.0 };
            case 'medium': { distance: 3.0, xIntensity: 1.2,  yIntensity: 0.8,  speed: 3.0 };
            case 'strong': { distance: 6.0, xIntensity: 1.5,  yIntensity: 1.0,  speed: 4.0 };
            default: null;
        };
    }

    private function _applyDynamicSinging():Void
    {
        final mode:String = event?.values?.dynamicSinging ?? 'off';

        if (_singHandler != null)
        {
            game.playField.onNoteHit.remove(_singHandler);
            _singHandler = null;
        }

        if (mode == 'off') return;

        _singHandler = (playerID:String, note:moon.game.obj.notes.Note, timing:String, isSustain:Bool) ->
        {
            if (isSustain) return;

            final shouldNudge:Bool = switch (mode)
            {
                case 'opponent': playerID == 'opponent';
                case 'player': playerID == 'p1';
                case 'both': true;
                default: false;
            };

            if (!shouldNudge || note.direction < 0 || note.direction > 3) return;

            _doNudge(game, note.direction);
        };

        game.playField.onNoteHit.add(_singHandler);
    }

    private static function _doNudge(game:PlayState, direction:Int):Void
    {
        final strength = 8.0;
        final outDur = 0.4;
        final backDur = 0.3;

        final dx = DIRS[direction][0] * strength;
        final dy = DIRS[direction][1] * strength;

        //if(game.camMov != null && game.camMov.active) return;

        //whoops
        MoonUtils.cancelActiveTwn(_nudgeTween);

        // Undo whatever offset is currently applied so we always start from neutral!!!
        game.camFollower.x -= _nudgeOffset.x;
        game.camFollower.y -= _nudgeOffset.y;
        _nudgeOffset.set(0, 0);

        var prevX:Float = 0.0;
        var prevY:Float = 0.0;

        _nudgeTween = FlxTween.tween(_nudgeOffset, {x: dx, y: dy}, outDur,
        {
            ease: FlxEase.quadOut,
            onUpdate: (_) ->
            {
                game.camFollower.x += _nudgeOffset.x - prevX;
                game.camFollower.y += _nudgeOffset.y - prevY;
                prevX = _nudgeOffset.x;
                prevY = _nudgeOffset.y;
            },
            onComplete: (_) ->
            {
                _nudgeTween = FlxTween.tween(_nudgeOffset, {x: 0.0, y: 0.0}, backDur,
                {
                    ease: FlxEase.quadInOut,
                    onUpdate: (_) ->
                    {
                        game.camFollower.x += _nudgeOffset.x - prevX;
                        game.camFollower.y += _nudgeOffset.y - prevY;
                        prevX = _nudgeOffset.x;
                        prevY = _nudgeOffset.y;
                    },
                    onComplete: (_) -> _nudgeOffset.set(0, 0)
                });
            }
        });
    }

    override public function getEditorData():EventInfo
    {
        return {
            name: 'Set Camera Mode',
            description: 'Switches how dynamic the camera can be.',
            category: VISUALS
        };
    }

    override public function getEditorFields():Array<EventFieldDef>
    {
        return [
            {
                name: 'dynamicSinging', label: 'Dynamic Singing', type: DROPDOWN,
                defaultValue: 'off',
                options: ['off', 'player', 'opponent', 'both']
            },
            {
                name: 'handheld', label: 'Handheld Movement', type: DROPDOWN,
                defaultValue: 'off',
                options: ['off', 'low', 'medium', 'strong']
            }
        ];
    }
}
