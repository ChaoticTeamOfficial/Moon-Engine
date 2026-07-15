import flixel.FlxG;
import flixel.text.FlxText;
import moon.dependency.MoonSprite;

var veryCoolImg:MoonSprite;
var coolArray:Array<String> = ['I got a nice value', 'yoo me too!', 'neat.'];

function onCreate()
{
	trace('I got created!');

	var squishey = new MoonSprite().loadGraphic(Paths.image('oi'));
	add(squishey);
	squishey.scale.x = 4;

	veryCoolImg = new MoonSprite().loadGraphic(Paths.image('jerma'));
	add(veryCoolImg);
	veryCoolImg.screenCenter();

	var welcome = new FlxText();
	welcome.setFormat(Paths.font('ARI-W9500-DISPLAY.TTF'), 48);
	welcome.text = 'I love haxeing my moon engine';
	add(welcome);
	welcome.screenCenter();
	welcome.y += 64;

	trace('Cool array: ' + coolArray);
}

var huge = false;

function onPostUpdate(elapsed:Float)
{
	if (!huge)
	{
		trace('[MY VERY COOL SCRIPT] Update seems to work! ' + elapsed);
		huge = true;
	}

	if (FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(() -> new moon.menus.MainMenu());

	if (veryCoolImg != null && veryCoolImg.alive) veryCoolImg.angle += elapsed * 12;
}

function onResize(width, height)
{
	trace('Ok so game resized to ' + width + 'x' + height);
}

function onFocusLost()
{
	if (veryCoolImg != null && veryCoolImg.alive)
	{
		trace('Focus lost... time to kill jerma... bye jerma...');
		veryCoolImg.kill();
	}
	else
		trace('as I said, jerma is gone.');
}

function onFocus()
{
	trace('jerma is forever lost, sorry.');
}

function destroy()
{
	trace('Dies');
}
