package moon;

import moon.menus.*;
import moon.game.*;
import moon.toolkit.level_editor.LevelEditor;
import moon.toolkit.offset.OffsetEditor;
import flixel.FlxState;

@:publicFields

/**
 * A class that contains constant variables. Basically, variables that don't and can't change their values. 
 */
class Constants
{
	static final GAME_WIDTH:Int = 1280;
	static final GAME_HEIGHT:Int = 720;
	static final GAME_FRAMERATE:Int = 60;
	static final SKIP_SPLASH:Bool = true;
	static final TRACE_DEBUG_INFO:Bool = true;

	static final SETTINGS_SAVE_BIND:String = 'MoonEngine-Settings';
	static final SONGDATA_SAVE_BIND:String = 'MoonEngine-SongData';
    static final ACHIEVEMENTS_SAVE_BIND:String = 'MoonEngine-Achievements';

    static inline final FALLBACK_LANG:String = 'en-US';

    static final INITIAL_STATE:Class<FlxState> = Title;

    /// ------- MENUS RELATED CONSTANTS

    // - Title

    /**
     * Whether is the game running on a friday night or not.
     */
    static final isFridayNight = (Date.now().getDay() == 5 && Date.now().getHours() >= 18) || (Date.now().getDay() == 6 && Date.now().getHours() < 5);

    /**
     * Time it takes to play a video on TitleState.
     */
    static final TITLE_VIDEO_DELAY:Float = 27.5;

    /// ------- GAMEPLAY RELATED CONSTANTS

    /**
     * The default intensity multiplier for camera bops.
     */
    static final DEFAULT_BOP_INTENSITY:Float = 1.015;

    /**
     * The default rate for camera bops (in beats per bop).
     */
    static final DEFAULT_BOP_RATE:Int = 4;
}