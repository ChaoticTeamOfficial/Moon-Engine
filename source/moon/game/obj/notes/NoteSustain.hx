package moon.game.obj.notes;

import flixel.util.FlxDestroyUtil;

class NoteSustain extends TiledSprite
{
    /**
     * The parent note for this sustain, needed for data, graphics and such.
     */
    public var parent(default, set):Note;
    public var downscroll:Bool = false;
    
    /**
     * Creates a new sustain note.
     * @param parent The parent note for this sustain, needed for data, graphics and such.
     */
    public function new(parent:Note)
    {
        super();
        this.parent = parent;
    }

    override public function update(dt:Float):Void
    {
        this.visible = parent.visible;

        final tailHeight:Float = (_tailFrame != null ? tailHeight() : tileHeight());
        var expectedHeight:Float = parent.duration;
        expectedHeight *= parent.speed;
        expectedHeight += tailHeight + (parent.height * 0.5 - tailHeight);

        if(parent.state == GOT_HIT)
        {
            this.visible = true;
            var timeSinceHit:Float = parent.receptor.conductor.time - parent.time;
            var remainingDuration:Float = Math.max(parent.duration - timeSinceHit, 0);
            expectedHeight = remainingDuration;
            expectedHeight *= parent.speed;
            expectedHeight += tailHeight + (parent.height * 0.5 - tailHeight);
            if(remainingDuration <= 0) this.visible = this.active = false;
        }

        this.height = Math.max(expectedHeight, 0);

        final obj = ((!parent.active) ? parent.receptor : parent);
        this.setPosition(obj.x + (parent.width - this.width) * 0.5, obj.y + parent.height * 0.5);

        if(downscroll)
            this.y -= height;

        this.flipY = downscroll;

        if (animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
            animation.update(dt);

        super.update(dt);
    }

    private function _updtGraphics()
    {
        this.centerAnimations = true;
        this.frames = parent.frames;
        this.animation.copyFrom(parent.animation);

        updateOther();
    }

    public function updateOther()
    {
        final dir:String = MoonUtils.intToDir(parent.direction);
        this.playAnim('$dir-hold', true);
        this.setTail('$dir-holdEnd');

        this.scale.set(parent.scale.x, parent.scale.y);
        this.antialiasing = parent.antialiasing;

        this.updateHitbox();
        this.visible = false;
    }

    @:noCompletion public function set_parent(parentNote:Note):Note
    {
        this.parent = parentNote;
        (parentNote != null) ? _updtGraphics() : null;
        return parentNote;
    }

    override function destroy():Void
    {
        parent = null;
        super.destroy();
    }
}