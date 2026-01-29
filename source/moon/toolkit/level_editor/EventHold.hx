package moon.toolkit.level_editor;

class EventHold extends TiledSprite
{
	public var parent(default, set):EventSpr;
	public var category:LevelEditor.GridType;
	public function new(parent:EventSpr)
	{
		super();
		this.visible = false;
		this.parent = parent;
		alpha = 0.6;
	}

	override public function update(dt:Float):Void
    {
        this.visible = parent.visible;

        this.height = Math.max(parent.duration, 0);
        if(parent != null)
        	this.setPosition(parent.x + (parent.width - this.width) * 0.5, parent.y);

        if (animation.curAnim != null && animation.curAnim.frameRate > 0 && animation.curAnim.frames.length > 1)
            animation.update(dt);

        super.update(dt);
    }

	@:noCompletion function set_parent(parent:EventSpr):EventSpr
	{
		this.parent = parent;

		this.centerAnimations = true;
        this.frames = Paths.getSparrowAtlas('toolkit/level-editor/icons/eventsLength');

        final str = '${parent.category}'.toUpperCase();
        animation.addByPrefix('loops', '$str-middle');
        animation.addByPrefix('tail', '$str-tail');

        this.playAnim('loops', true);
        this.setTail('tail');

        this.scale.set(parent.scale.x, parent.scale.y);
        this.antialiasing = parent.antialiasing;
        category = parent.category;

		return this.parent;
	}
}