import Shortcuts;

// TODO: Add everything else...
function onPostCreate()
{
	background.adjustGroupColor(background.players, {
		brightness: -26,
		hue: -16,
		contrast: 0,
		saturation: -5
	});

	background.adjustGroupColor(background.opponents, {
		brightness: -26,
		hue: -16,
		contrast: 0,
		saturation: -5
	});

	background.adjustGroupColor(background.spectators, {
		brightness: -26,
		hue: -16,
		contrast: 0,
		saturation: -5
	});

	background.adjustGroupColor(background.getObject('train'), {
		brightness: -26,
		hue: -16,
		contrast: 0,
		saturation: -5
	});

	Shortcuts.getPlayer().useRenderTexture = true;
	Shortcuts.getOpponent().useRenderTexture = true;
	Shortcuts.getSpectator().useRenderTexture = true;
}