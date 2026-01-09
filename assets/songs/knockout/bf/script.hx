import flixel.FlxG;

function onUpdate(elapsed)
{
	if(FlxG.keys.justPressed.SHIFT)
		game.stage.players.members[0].playAnim('attack', true);
		
	if(FlxG.keys.justPressed.SPACE)
		game.stage.players.members[0].playAnim('dodge', true);
}