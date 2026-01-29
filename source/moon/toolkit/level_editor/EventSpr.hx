package moon.toolkit.level_editor;

class EventSpr extends MoonSprite
{
	public var category:LevelEditor.GridType;
	public var event:String;
	public function new(event:String, category:LevelEditor.GridType = NOTES)
	{
		super();
		this.event = event;
		this.category = category;

		frames = LevelEditor.instance.eventAtlas.getAtlasFrames();

		final catStr:String = '$category';
		final desiredName = '${catStr.toUpperCase()}-$event';
		final animFrame = frames.getByName(desiredName);

		if(animFrame != null)
        	animation.frameName = desiredName;
        else
        {
        	//trace('Event frame not found: $desiredName', "WARNING");
        	animation.frameName = '${catStr.toUpperCase()}-None';
        }
        
        antialiasing = false;
	}
}