package moon.game.obj.dialogue.effects;

/**
 * Randomly offsets position each frame.
 */
class ShakeEffect extends TextEffect {
    override public function applyDynamic(sprite:FlxText, elapsed:Float, globalTime:Float, localTime:Float):Void {
        final intensity = getValue("intensity", 1.0, 0);

        sprite.x += FlxG.random.float(-intensity, intensity);
        sprite.y += FlxG.random.float(-intensity, intensity);
    }
}