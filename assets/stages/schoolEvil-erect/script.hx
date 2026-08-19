import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;
import moon.game.obj.Character;
import moon.hardcoded_shaders.WiggleEffect;

var wiggleBack:WiggleEffect = null;
var wiggleSchool:WiggleEffect = null;
var wiggleGround:WiggleEffect = null;
var wiggleSpike:WiggleEffect = null;

function onPostCreate()
{
	wiggleBack = new WiggleEffect(2 * 0.8, 4 * 0.4, 0.011, 0);
    wiggleSchool = new WiggleEffect(2, 4, 0.017, 0);
    wiggleSpike = new WiggleEffect(2, 4, 0.01, 0);
    wiggleGround = new WiggleEffect(2, 4, 0.007, 0);
	
	getObject('weebBackSpikes').shader = wiggleBack;
	getObject('weebSchool').shader = wiggleSchool;
	getObject('backSpike').shader = wiggleSpike;
	getObject('weebStreet').shader = wiggleGround;
}

function onPostUpdate(elapsed)
{
	for(shader in [wiggleBack, wiggleSchool, wiggleSpike, wiggleGround])
		shader.update(elapsed);
}