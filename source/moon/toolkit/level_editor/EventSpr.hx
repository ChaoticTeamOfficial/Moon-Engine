package moon.toolkit.level_editor;

import moon.toolkit.level_editor.LevelEditor.EventInfo;

class EventSpr extends MoonSprite
{
	public var category:LevelEditor.GridType;
	public var event:String;
	public var duration:Float = 0;
	public var info:Null<EventInfo> = null;

	public function new(event:String, category:LevelEditor.GridType = NOTES)
	{
		super();
		this.event = event;
		this.category = category;

		frames = LevelEditor.instance.eventAtlas.getAtlasFrames();

		final catStr:String = '$category';
		final desiredName = '${catStr.toUpperCase()}-$event';
		final animFrame = frames.getByName(desiredName);

		if (animFrame != null) animation.frameName = desiredName;
		else
		{
			// decided to remove, it shows too much on the console lol
			// trace('Event frame not found: $desiredName', "WARNING");
			animation.frameName = '${catStr.toUpperCase()}-None';
		}

		antialiasing = active = false;
	}
}
