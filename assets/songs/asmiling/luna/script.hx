import moon.dependency.MoonSprite;

function onPostCreate()
{
	
}

function onGameOver(instance)
{
	instance.charSpr.visible = false;
	Paths.playSFX('explosion.ogg');
	
	var explotano = new MoonSprite().loadGraphic(Paths.image('explosion'), true, 48,48);
	explotano.animation.add('aaa', [0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18], 10, false);
	explotano.animation.play('aaa');
	explotano.scale.set(16, 16);
	instance.add(explotano);
	explotano.camera = game.camHUD;
	explotano.screenCenter();
	explotano.x += 164;
}