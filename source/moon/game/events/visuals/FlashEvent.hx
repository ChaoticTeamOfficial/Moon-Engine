package moon.game.events.visuals;

class FlashEvent extends BaseEvent
{
	override public function execute():Void
	{
		final values = event.values;

		final durationSteps:Float = values.duration ?? 4;

		// WHAT THE FUCK IS THIS FORMATTING BRAH
		game
			.getCamera(values.target)
			.flash(
				FlxColor.fromString(values?.color ?? '#000000'),
				(durationSteps <= 0) ? 0 : game.conductor.stepCrochet / 1000 * durationSteps,
				null,
				values.force
			);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Flash',
			description: 'Flash a camera with a solid color.',
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
				name: 'color',
				label: 'Color',
				type: COLOR,
				defaultValue: '#FFFFFF'
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
