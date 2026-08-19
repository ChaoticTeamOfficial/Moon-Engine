package moon.game.events.gimmicks;

class SetScrollSpeedEvent extends BaseEvent
{
	var scrollTweens:Map<String, FlxTween> = new Map();

	override public function execute():Void
	{
		final spawner = game.playField.noteSpawner;
		final baseSpeed = game.playField.chart.content.meta.scrollSpd;

		var scroll:Float = event.values.scroll;
		if (!event.values.absolute) scroll *= baseSpeed;

		final isInstant = event.values.ease.toLowerCase() == 'instant';
		final duration = game.conductor.stepCrochet / 1000 * event.values.duration;
		final ease = TweenUtils.resolveEase(event.values.ease);

		final strumline:String = event.values?.strumline ?? 'both';
		final lanes:Array<String> = switch (strumline)
		{
			case 'opponent':
				['opponent'];
			case 'p1':
				['p1'];
			default:
				['opponent', 'p1'];
		};

		// cancel existing tweens for affected lanes
		for (lane in lanes)
		{
			TweenUtils.cancelTwn(scrollTweens.get(lane));
			scrollTweens.remove(lane);
		}

		for (lane in lanes)
		{
			if (isInstant || duration <= 0) spawner.setStrumlineSpeed(lane, scroll);
			else
			{
				// reads current converted speed and un-convert for proxy start value!!
				final currentSpeed = spawner.getStrumlineSpeed(lane);
				final proxy = {
					speed: currentSpeed
				};
				final capLane = lane;

				final twn = FlxTween.tween(proxy, {
					speed: scroll
				}, duration, {
					ease: ease,
					onUpdate: (_) -> spawner.setStrumlineSpeed(capLane, proxy.speed)
				});
				scrollTweens.set(lane, twn);
			}
		}
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Set Lane Scroll Speed',
			description: 'Changes the scroll speed of a specified lane.',
			category: GIMMICKS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'scroll',
				label: 'Speed',
				type: NUMBER,
				defaultValue: 1.0,
				min: 0.1,
				max: 10.0,
				step: 0.05
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 8,
				min: 0,
				max: 999,
				step: 1
			},
			{
				name: 'ease',
				label: 'Easing',
				type: DROPDOWN,
				defaultValue: 'expoOut',
				options: TweenUtils.easeList
			},
			{
				name: 'strumline',
				label: 'Strumline',
				type: DROPDOWN,
				defaultValue: 'both',
				options: ['both', 'opponent', 'p1']
			},
			{
				name: 'absolute',
				label: 'Absolute Speed',
				type: CHECKBOX,
				defaultValue: false
			}
		];
	}
}
