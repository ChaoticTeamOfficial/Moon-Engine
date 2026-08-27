function onPostCreate()
{
	if(char.type == 'opponent')
		char.setPosition(game.stage.spectators.x, game.stage.spectators.y);
}