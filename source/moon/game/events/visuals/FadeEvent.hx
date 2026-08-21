package moon.game.events.visuals;

class FadeEvent extends BaseEvent
{
	override public function execute():Void
	{
		final values = event.values;

		final durationSteps:Float = values.duration ?? 4;

		// yeah the formatter IS tweaking
		game
			.getCamera(values.target)
			.fade(
				FlxColor.fromString(event?.values?.color ?? '#000000'),
				(durationSteps <= 0) ? 0 : game.conductor.stepCrochet / 1000 * durationSteps,
				(values.direction ?? 'Fade Out') == 'Fade In',
				null,
				values?.force ?? true
			);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Fade',
			description: 'Fades a camera in or out to a solid color.',
			category: VISUALS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'target',
				label: 'Target',
				type: DROPDOWN,
				defaultValue: 'camHUD',
				options: ['camGAME', 'camHUD', 'camALT']
			},
			{
				name: 'direction',
				label: 'Direction',
				type: DROPDOWN,
				defaultValue: 'Fade Out',
				options: ['Fade Out', 'Fade In']
			},
			{
				name: 'color',
				label: 'Color',
				type: COLOR,
				defaultValue: '#000000'
			},
			{
				name: 'duration',
				label: 'Duration (steps)',
				type: NUMBER,
				defaultValue: 4,
				min: 0,
				max: 999,
				step: 1
			},
			{
				name: 'force',
				label: 'Force',
				type: CHECKBOX,
				defaultValue: false
			}
		];
	}
}
