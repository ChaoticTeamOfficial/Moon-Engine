package moon.menus.obj.achievements;

import moon.dependency.user.MoonAchievements;

class AchievementIcon extends MoonSprite
{
	public var name:String;
	public var description:String;
	public var hideName:Bool;
	public var hideDesc:Bool;
	public var isUnlocked:Bool = false;
	public var category:String = '';

	public function new(data:AchievementData)
	{
		super();
		var image = Paths.exists('achievements/${data.id}-icon.png') ? '${data.id}-icon' : 'placeholder-icon';

		loadGraphic(Paths.getGraphic(image, 'achievements'), true);
		this.setGraphicSize(72);
		this.updateHitbox();
		name = data.name ?? 'Unknown';
		description = data.description ?? 'No description.';
		hideName = data.hideName ?? false;
		hideDesc = data.hideDesc ?? false;
		isUnlocked = MoonAchievements.isUnlocked(data.id);

		// turn these off if it's unlocked
		if (isUnlocked)
		{
			hideName = false;
			hideDesc = false;
		}
	}
}
