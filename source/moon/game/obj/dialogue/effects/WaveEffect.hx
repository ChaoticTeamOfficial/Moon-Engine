package moon.game.obj.dialogue.effects;

/**
 * Sinusoidal vertical offset, synced globally for consistency across characters.
 */
class WaveEffect extends TextEffect {
    override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void
   	{
        final intensity = getValue("intensity", 1.0, 0);
        final frequency = getValue("frequency", 10.0);
        final delay = getValue("delay", 0.6, 2);

        sprite.y += Math.sin((globalTime * frequency) + (sprite.ID * delay)) * intensity;
    }
}