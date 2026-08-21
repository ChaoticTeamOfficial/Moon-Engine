package moon.game.events.characters;

class TintCharacterEvent extends BaseEvent
{
	override public function execute():Void
	{
		final target = game.getChar(event?.values?.character ?? 'opponent');

		if (event.values.disable) @:privateAccess target.colorTransform.__identity();
		else
			target.colorTransform.color = FlxColor.fromString(event.values.tintCol);
	}

	override public function getEditorData():EventInfo
	{
		return {
			name: 'Tint Character',
			description: 'Tints a character to a specified color.',
			category: CHARACTERS
		};
	}

	override public function getEditorFields():Array<EventFieldDef>
	{
		return [
			{
				name: 'character',
				label: 'Target',
				type: DROPDOWN,
				defaultValue: 'player',
				options: ['player', 'opponent', 'spectator', 'none']
			},
			{
				name: 'disable',
				label: 'Disable?',
				type: CHECKBOX,
				defaultValue: false
			},
			{
				name: 'tintCol',
				label: 'Tint Color',
				type: COLOR,
				defaultValue: 0xFFFFFFFF
			}
		];
	}
}
