package moon.menus.obj.playlist;

import flixel.group.FlxSpriteGroup;
import moon.global_obj.PixelIcon;
import moon.backend.gameplay.Timings;
import moon.menus.obj.freeplay.FreeplayRank;
import moon.game.obj.HealthIcon;
import moon.backend.data.SongLibrary.Difficulty;

using StringTools;

class PlaylistItem extends FlxSpriteGroup
{
	// Song Stuff
	public var songName:String;
	public var song:String;
	public var mix:String;
	public var songDatas:Map<String, Chart> = new Map();
	public var difficulties:Array<Difficulty>;

	// Graphic Stuff
	public var box:MoonSprite;
	public var songIcon:PixelIcon;
	public var songText:FlxText;
	public var numberText:FlxText;

	public var selected:Bool = false;

	public static var itemSkew:Float = -5;
	public static var lerpSpeed:Float = 0.1;
	static var unselectedBoxScale:Float = 1;
	static var selectedBoxScale:Float = 1.05;
	static var unselectedBoxColor:FlxColor = FlxColor.BLACK;
	static var selectedBoxColor:FlxColor = FlxColor.WHITE;
	static var unselectedTextColor:FlxColor = FlxColor.WHITE;
	static var selectedTextColor:FlxColor = FlxColor.BLACK;

	public function new(targetSong:String, targetDiff:String, targetMix:String)
	{
		super();

		this.difficulties = SongLibrary.get().availableDifficulties(targetSong, targetMix);
		for (diff in difficulties) songDatas.set(diff.name, new Chart(targetSong, diff.name, targetMix));

		var data:Chart = songDatas[difficulties[0].name];

		this.song = targetSong;
		this.songName = data.content.meta.displayName;
		this.mix = targetMix;

		box = new MoonSprite().makeGraphic(700, 40, FlxColor.WHITE);
		box.skew.x = itemSkew;
		add(box);

		songIcon = new PixelIcon(data.content.meta.opponents[0]);
		songIcon.setPosition(0, (box.height - songIcon.height)/2);
		songIcon.scale.set(1, 1);
		songIcon.updateHitbox();
		add(songIcon);

		songText = new FlxText(0, 0, 0, songName);
		songText.setFormat(Paths.font('phantomuff/full.ttf'), 20);
		songText.setPosition(50, (box.height - songText.height) / 2);
		add(songText);

		numberText = new FlxText(box.width - 25, 5, 0, '1', 20);
		numberText.setFormat(Paths.font('phantomuff/full.ttf'), 20);
		add(numberText);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if(selected) 
		{
			this.scale.x = FlxMath.lerp(box.scale.x, selectedBoxScale, lerpSpeed);
			this.scale.y = FlxMath.lerp(box.scale.y, selectedBoxScale, lerpSpeed);
			songText.color = numberText.color = selectedTextColor;
			box.color = selectedBoxColor;
		}
		else
		{
			this.scale.x = FlxMath.lerp(box.scale.x, unselectedBoxScale, lerpSpeed);
			this.scale.y = FlxMath.lerp(box.scale.y, unselectedBoxScale, lerpSpeed);
			songText.color = numberText.color = unselectedTextColor;
			box.color = unselectedBoxColor;
		}
	}
}