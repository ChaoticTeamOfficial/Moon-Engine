package moon.menus.obj.freeplay;

import flixel.group.FlxSpriteGroup;

/**
 * Difficulty rating display for the freeplay!
 */
class DifficultyStars extends FlxSpriteGroup
{
    /**
     * The current difficulty (0-20). 
     */
    public var difficulty(default, set):Int = 0;

    /**
     * Spacing between each of the sprites
     */
    public var spacing:Float = 55;

    /**
     * Delay in seconds between updating each sprite.
     */
    public var updateDelay:Float = 0.06;

    private var pendingTimers:Array<FlxTimer> = [];
    private var diffSprites:Array<MoonSprite> = [];
    private var flameSprites:Array<MoonSprite> = [];

    /**
     * @param x          Screen X position
     * @param y          Screen Y position
     * @param spacing    Distance between each sprite 
     * @param updateDelay seconds between each sprite update
     */
    public function new(x:Float = 0, y:Float = 0, ?spacing:Float = 55, ?updateDelay:Float = 0.06)
    {
        super(x, y);

        this.spacing = spacing;
        this.updateDelay = updateDelay;

        // flames first...
        for (i in 0...10)
        {
            var flame = new MoonSprite();
            flame.frames = Paths.getSparrowAtlas('menus/freeplay/flame');
            flame.animation.addByPrefix('idle', 'fire loop full', FlxG.random.int(15, 24), false);
            flame.animation.onFinish.add((_) -> flame.animation.play("idle", true, false, 2));
            flame.visible = false;
            flame.centerAnimations = true;
            flame.scale.set(0.7, 0.7);
            flame.updateHitbox();
            flameSprites.push(flame);
            add(flame);

        }

        // then the stars
        for (i in 0...10)
        {
            var star = new MoonSprite();
            star.frames = Paths.getSparrowAtlas('menus/freeplay/stars');
            star.animation.addByPrefix('dot', 'dot', 24, true);
            star.animation.addByPrefix('star', 'star', 24, true);
            star.animation.addByPrefix('extraStar', 'star-extra', 24, true);
            star.centerAnimations = true;
            star.scale.set(0.7, 0.7);
            star.updateHitbox();
            diffSprites.push(star);
            add(star);
        }

        repositionSprites();
        updateAllInstant();
    }

    private function repositionSprites()
    {
        for (i in 0...10)
        {
            diffSprites[i].setPosition(x + i * spacing, y);
            flameSprites[i].setPosition(diffSprites[i].x - 38, diffSprites[i].y - 108);
        }
    }

    private function set_difficulty(value:Int):Int
    {
        value = Std.int(Math.max(0, Math.min(20, value)));
        if (value == difficulty) return difficulty;

        difficulty = value;

        for (t in pendingTimers)
            MoonUtils.cancelActiveTmr(t);

        pendingTimers = [];

        for(i in 0...10)
        {
	        diffSprites[i].playAnim('dot', true);
	        flameSprites[i].visible = false;
	    }

        animateNextSprite(0);

        return difficulty;
    }

    /**
     * Recursively updates one sprite then schedules the next with delay
     */
    private function animateNextSprite(index:Int)
    {
        if (index >= 10) return;

        var val = index + 1;

        final animToPlay:String = (difficulty < val) ? "dot" : (difficulty >= val + 10) ? "extraStar" : "star";

        diffSprites[index].playAnim(animToPlay, true);
        flameSprites[index].visible = (animToPlay == "extraStar");
        flameSprites[index].playAnim("idle", true);

        // Schedule next
        if (index < 9)
        {
            var timer = new FlxTimer().start(updateDelay, _ -> animateNextSprite(index + 1));
            pendingTimers.push(timer);
        }
    }

    /**
     * Updates instantly, also used on create.
     */
    private function updateAllInstant()
    {
        for (i in 0...10)
        {
            final val = i + 1;
            final animToPlay:String = (difficulty < val) ? "dot" : (difficulty >= val + 10) ? "extraStar" : "star";

            diffSprites[i].playAnim(animToPlay, true);

            flameSprites[i].visible = (animToPlay == "extraStar");

            // For instant updates, also start flame anim if visible
            if ((animToPlay == "extraStar"))
                flameSprites[i].playAnim("idle", true);
        }
    }

    override function update(elapsed)
   	{
   		super.update(elapsed);
   	}

    public function updateInstantly()
    {
        for (t in pendingTimers) if (t != null && !t.finished) t.cancel();
        pendingTimers = [];
        updateAllInstant();
    }

    override function destroy()
    {
        for (t in pendingTimers) if (t != null && !t.finished) t.cancel();
        super.destroy();
    }
}