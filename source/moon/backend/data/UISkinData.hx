package moon.backend.data;

import moon.game.obj.HealthBar.IconLayout;
import flixel.text.FlxText.FlxTextBorderStyle;
import moon.toolkit.ui.UITheme;

/**
 * Everything a UI skin can customize about the in-game healthbar.
 */
typedef UISkinHealthBar =
{
	var ?barBG:String;
	var ?fillDirection:String;
	var ?vertical:Bool;
	var ?scale:Float;
	var ?paddingX:Float;
	var ?paddingY:Float;
	var ?iconScale:Float;
	var ?iconDistance:Float;
	var ?iconSpreadX:Float;
	var ?iconSpreadY:Float;
	var ?iconLayout:IconLayout;
	var ?iconsFollowHealth:Bool;
	var ?statsDistance:Float;
	var ?extra:Dynamic;
}

typedef UITheme = {
	var ?font:String;
	var ?antialiasing:Bool;
	var ?fontSizeMultiplier:Float;
	var ?textOutline:String;
	var ?textOutlineSize:Int;
};

typedef UISkinFile =
{
	var ?name:String;
	var ?theme:UITheme;
	var ?layouts:Dynamic;
	var ?healthBar:UISkinHealthBar;
	var ?extra:Dynamic;
}

@:publicFields
@:forward
abstract UISkinData(UISkinFile) from UISkinFile to UISkinFile
{
	static var cache:Map<String, UISkinFile> = [];

	/**
	 * Returns cached UI skin data.
	 */
	static function get(skin:String):UISkinData
	{
		if (skin == null || skin == '') skin = 'moon-engine';

		if (cache.exists(skin)) return cache.get(skin);

		final path = 'images/uiSkins/$skin/skin';
		var data:UISkinData = null;

		if (Paths.exists('$path.json'))
		{
			final raw:Dynamic = Paths.JSON(path);
			if (raw != null) data = raw;
		}

		if (data == null)
		{
			data = {
				name: skin,
				theme: null,
				layouts: null
			};
		}
		else if (data.name == null) data.name = skin;

		cache.set(skin, data);
		return data;
	}

	/** 
	 * Resolve the UI skin a noteskin wants.
	 */
	static function fromNoteskin(noteskin:NoteskinData):UISkinData return get(noteskin?.uiSkin ?? 'moon-engine');

	static function clearCache():Void cache.clear();

	// static function assetRoot(skin:String):String return 'images/uiSkins/$skin';

	/**
	 * Applies `theme` onto `UITheme` when present.
	 */
	function applyTheme():Void
	{
		if (this.theme == null) return;
		// TODO?
	}
	
	static function makeText(data:UISkinData, text:String, size:Int, ?borderColor:FlxColor):FlxText
	{
		final borderType = [
			"NONE" => FlxTextBorderStyle.NONE,
			"SHADOW" => FlxTextBorderStyle.SHADOW,
			"OUTLINE" => FlxTextBorderStyle.OUTLINE
		];
		
		var textT = new FlxText();
		textT.font = Paths.font(data?.theme?.font ?? 'vcr.ttf');
		textT.size = Std.int(size * (data?.theme?.fontSizeMultiplier ?? 1));
		textT.text = text;
		textT.antialiasing = data?.theme?.antialiasing ?? true;
		textT.setBorderStyle(borderType.get(data?.theme?.textOutline.toUpperCase() ?? "NONE"), borderColor, data?.theme?.textOutlineSize ?? 4);
		return textT;
	}

	static function parseColor(value:Dynamic):FlxColor
	{
		if (value == null) return FlxColor.WHITE;
		if (Std.isOfType(value, Int)) return cast value;
		return FlxColor.fromString(Std.string(value));
	}
}
