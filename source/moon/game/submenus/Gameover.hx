package moon.game.submenus;

class Gameover extends FlxSubState
{
	public function new()
	{
		super();
		PlayState.instance.persistentDraw = false;
		this.camera = PlayState.instance.camHUD;
	}
}