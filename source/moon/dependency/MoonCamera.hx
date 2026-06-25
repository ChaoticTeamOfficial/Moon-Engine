package moon.dependency;

import flixel.FlxCamera;
import flixel.FlxG;
import flixel.math.FlxMath;

class MoonCamera extends FlxCamera
{
	/**
	 * Adds a handheld effect to the camera with any intensity value of your desire.
	 */
	public var handheldVFX:
		{?distance:Float, ?xIntensity:Float, ?yIntensity:Float, ?speed:Float};

	private var shakeTime:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		if (handheldVFX != null)
		{
			shakeTime += elapsed * (handheldVFX.speed ?? 3);

			final val = handheldVFX?.distance ?? 3;
			final xIn = handheldVFX?.xIntensity ?? 1.2;
			final yIn = handheldVFX?.yIntensity ?? 0.8;
			scroll.x += FlxMath.fastSin(shakeTime * xIn) * val;
			scroll.y += FlxMath.fastSin(shakeTime * yIn) * val;
		}
	}
}
