package moon.toolkit.ui;

@:publicFields
/**
 * Central place for all visual constants so every control stays consistent.
 */
class UITheme
{
	// Panel / background colors.
	static final PANEL_BG:FlxColor = 0xFF141417;
	static final SIDEBAR_BG:FlxColor = 0xFF0A0A0C;
	static final HEADER_BG:FlxColor = 0xFF1B1B1F;
	// Control colors
	static final CONTROL_BG:FlxColor = 0xFF141417;
	static final CONTROL_BG_HOVER:FlxColor = 0xFF1B1B1F;
	static final CONTROL_BG_ACTIVE:FlxColor = 0xFF050505;
	static final CONTROL_BORDER:FlxColor = 0xFF000000;
	static final ACCENT:FlxColor = 0xFF3D8EF7;
	static final ACCENT_DIM:FlxColor = 0xFF20507F;
	static final TEXT_COLOR:FlxColor = 0xFFF2F2F2;
	static final TEXT_DIM:FlxColor = 0xFF8A8A8F;
	// Sizing
	static final CORNER_RADIUS:Float = 12;
	static final ROW_HEIGHT:Float = 32;
	static final ROW_SPACING:Float = 2;
	static final ICON_SIZE:Float = 16;
	static final PADDING:Float = 5;
	static final FONT:String = Paths.font("Consolas/CONSOLAB.TTF");
	static final FONT_SIZE:Int = 14;
	static final FONT_ANTIALIASING:Bool = true;
}
