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
     * Height to use when in chart editor mode (set externally by LevelEditor)
     */
    public var editorHeight:Float = 0;
    
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

        if(parent.state == TOO_LATE)
        {
            parent.duration = 0;
            this.height = 0;
            this.active = this.visible = false;
            return;
        }

        var expectedHeight:Float = 0;
        if (parent.state == CHART_EDITOR)
            expectedHeight = editorHeight;
        else
        {
            final tailHeight:Float = (_tailFrame != null ? tailHeight() : tileHeight());

            if (parent.state == GOT_HIT)
            {
                this.visible = true;
                // yes we actually take care of the
                expectedHeight = Math.max(parent.duration - (parent.receptor.conductor.time - parent.time), 0) * parent.speed;
            }
            else
            {
                expectedHeight = parent.duration;
                expectedHeight *= parent.speed;
                expectedHeight += (parent.height * 0.5 - tailHeight);
            }
        }

        this.height = Math.max(expectedHeight, 0);

        final obj = ((!parent.active && parent.receptor != null) ? parent.receptor : parent);

        if (obj != null)
        {
            this.setPosition(obj.x + (parent.width - this.width) * 0.5, obj.y + parent.height * 0.5);
            this.visible = obj.visible;
        }
        else
            this.visible = false;

        if (downscroll)
            this.y -= height;

        this.flipY = downscroll;

        if (animation.curAnim != null && animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
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