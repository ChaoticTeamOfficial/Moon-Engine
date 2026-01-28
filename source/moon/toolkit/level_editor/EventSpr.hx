package moon.toolkit.level_editor;

class EventSpr extends MoonSprite
{
	public var category:LevelEditor.GridType;
	public var event:String;
	public function new(?x:Float = 0, ?y:Float = 0, event:String, category:LevelEditor.GridType = NOTES)
	{
		super(x, y);
		this.event = event;
		this.category = category;

		frames = LevelEditor.instance.eventAtlas.getAtlasFrames();
        atlasTest.animation.frameName = event;
	}
}