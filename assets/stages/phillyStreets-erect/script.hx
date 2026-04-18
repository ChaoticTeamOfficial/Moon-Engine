import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import moon.dependency.MoonSprite;
import moon.hardcoded_shaders.DropShadowShader;
import moon.game.PlayState;

// --- MAIN STAGE CONFIG ---

// I don't want to do a switch cause I'm a bitch
// so! put the song ID on the left, then, the array's
// first value is the intensity on the song start, and the last is
// on the song end, it'll smoothly go from the first value to the second one throughout the song.
final RAIN_INTENSITY_MAP = {
    'darnell': [0.01, 0.06],
    'lit-up': [0.06, 0.085],
    '2-hot': [0.088, 0.13]
};

// traffic light timing
var lastLightChangeBeat = 0;
var lightChangeInterval = 8;

// car state
var car1Interruptable = true;
var car2Interruptable = true;
var carWaiting = false;
var lightsStop = false;
var carsOffset:Dynamic = {x: 0, y: 0};

// objects
var rainShader:RainShader;
var rainFilter:ShaderFilter;
var car1:MoonSprite;
var car2:MoonSprite;

// -- SETUP STUFF

function onPostCreate()
{
    carsOffset = ScriptUtils.point(-400, -179);

    // rain shi
    rainShader = new RainShader();
    rainShader.scale = FlxG.height / 600;
    rainFilter = new ShaderFilter(rainShader);
    game.camGAME.filters = [rainFilter];

    // cars
    car1 = createCar();
    car2 = createCar();

    // cool rim lighting
    final rim = {brightness: -21, hue: -10, contrast: -28, saturation: -45};
    background.adjustGroupColor(background.opponents, rim);
    background.adjustGroupColor(background.spectators, rim);
    background.adjustGroupColor(background.players, rim);
}

function createCar():MoonSprite
{
    var car = new MoonSprite(1200, 818);
    car.frames = Paths.getSparrowAtlas('phillyStreets-erect/phillyCars', 'stages');
    car.scrollFactor.x = 0.9;

    for (i in 1...5)
        car.animation.addByPrefix('car' + i, 'car' + i + '0', 24, false);

    insert(members.indexOf(getObject('phillyTraffic')), car);
    return car;
}

function onPostUpdate(elapsed:Float)
{
	// I genuinely got surprised when this worked
	// for some damn reason I was truly expecting Reflect to not work?
    final intensityRange = Reflect.field(RAIN_INTENSITY_MAP, PlayState.songData.song) ?? [0.0, 0.01];

    rainShader.intensity = game.playField.inCountdown || game.playField.inCutscene
        ? intensityRange[0]
        : FlxMath.remapToRange(game.conductor.time, 0, game.playField.playback.inst[0]?.length ?? 0, intensityRange[0], intensityRange[1]);

    rainShader.updateViewInfo(FlxG.width, FlxG.height, game.camGAME);
    rainShader.update(elapsed);
}

function onBeat(beat:Int)
{
    // traffic light change
    if (beat == lastLightChangeBeat + lightChangeInterval)
        changeTrafficLights(beat);

    // car 1 (forward)
    if (FlxG.random.bool(10) 
        && beat != lastLightChangeBeat + lightChangeInterval 
        && car1Interruptable 
        && !carWaiting)
    {
        if (lightsStop)
            driveCarToLights(car1);
        else
            driveCarForward(car1);
    }

    // car 2 (backward)
    if (FlxG.random.bool(10) 
        && beat != lastLightChangeBeat + lightChangeInterval 
        && car2Interruptable 
        && !lightsStop)
        driveCarBackward(car2);
}

// --- TRAFFIC LIGHTS ---

function changeTrafficLights(beat:Int)
{
    lastLightChangeBeat = beat;
    lightsStop = !lightsStop;

    getObject('phillyTraffic').playAnim(lightsStop ? 'toRed' : 'toGreen');
    lightChangeInterval = lightsStop ? 20 : 30;

    if (!lightsStop && carWaiting)
        finishCarAtLights(car1);
}

// --- CAR DRIVING HELPERS ---

function driveCarForward(car:MoonSprite)
{
    driveCarGeneric(car, false, false);
}

function driveCarToLights(car:MoonSprite)
{
    driveCarGeneric(car, true, false);
}

function driveCarBackward(car:MoonSprite)
{
    driveCarGeneric(car, false, true);
}

function driveCarGeneric(car:MoonSprite, stopAtLights:Bool, backward:Bool)
{
    if (backward) car.flipX = true;

    final variant = FlxG.random.int(1, 4);
    car.playAnim('car' + variant, true);

    var extraOffset = [0, 0];
    var duration = 2.0;

    switch (variant)
    {
        case 1: duration = FlxG.random.float(1, 1.7);
        case 2: extraOffset = [20, 18]; duration = FlxG.random.float(0.6, 1.2); // why this bitch fast
        case 3: extraOffset = [30, 50]; duration = FlxG.random.float(1.5, 2.5);
        case 4: extraOffset = [10, 60]; duration = FlxG.random.float(1.5, 2.5);
    }

    final startRot = stopAtLights ? -7 : (backward ? 18 : -8);
    final endRot = stopAtLights ? -5 : (backward ? -8 : 18);

	//whoops
    final path = backward
        ? [ ScriptUtils.point(3102 + carsOffset.x, 1127 + carsOffset.y),
            ScriptUtils.point(2400 + carsOffset.x, 980 + carsOffset.y),
            ScriptUtils.point(1570 + carsOffset.x, 1049 + carsOffset.y) ]
        : stopAtLights
            ? [ ScriptUtils.point(1500 + carsOffset.x, 1049 + carsOffset.y),
                ScriptUtils.point(1770 + carsOffset.x, 994 + carsOffset.y),
                ScriptUtils.point(1950 + carsOffset.x, 980 + carsOffset.y) ]
            : [ ScriptUtils.point(1570 + carsOffset.x, 1049 + carsOffset.y),
                ScriptUtils.point(2400 + carsOffset.x, 980 + carsOffset.y),
                ScriptUtils.point(3102 + carsOffset.x, 1187 + carsOffset.y) ];

    carInterruptable(car, false);

    FlxTween.angle(car, startRot, endRot, duration, {ease: FlxEase.cubeOut});
    FlxTween.quadPath(car, path, duration, true, {
        ease: FlxEase.cubeOut,
        onComplete: _ ->
        {
            if (stopAtLights)
            {
                carWaiting = true;
                if (!lightsStop) finishCarAtLights(car);
            }
            else carInterruptable(car, true);
        }
    });
}

function finishCarAtLights(car:MoonSprite)
{
    carWaiting = false;
    carInterruptable(car, false);

    final duration = FlxG.random.float(1.8, 3.0);
    final path = [
        ScriptUtils.point(1950 + carsOffset.x, 980 + carsOffset.y),
        ScriptUtils.point(2400 + carsOffset.x, 980 + carsOffset.y),
        ScriptUtils.point(3102 + carsOffset.x, 1187 + carsOffset.y)
    ];

    FlxTween.angle(car, -5, 18, duration, {ease: FlxEase.sineIn});
    FlxTween.quadPath(car, path, duration, true, {
        ease: FlxEase.sineIn,
        onComplete: _ -> carInterruptable(car, true)
    });
}

inline function carInterruptable(car:MoonSprite, value:Bool)
{
    if (car == car1) car1Interruptable = value;
    else if (car == car2) car2Interruptable = value;
}