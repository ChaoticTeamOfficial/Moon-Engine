package moon;

import moon.menus.*;
import moon.game.*;
import moon.toolkit.level_editor.LevelEditor;
import moon.toolkit.offset.OffsetEditor;
import flixel.FlxState;

@:publicFields
class Constants
{
	static final GAME_WIDTH:Int = 1280;
	static final GAME_HEIGHT:Int = 720;
	static final GAME_FRAMERATE:Int = 60;
	static final SKIP_SPLASH:Bool = true;
	static final TRACE_DEBUG_INFO:Bool = true;

	static final SETTINGS_SAVE_BIND:String = 'MoonEngine-Settings';
	static final SONGDATA_SAVE_BIND:String = 'MoonEngine-SongData';

    static final INITIAL_STATE:Class<FlxState> = MainMenu;

    ////// ------- MENUS RELATED CONSTANTS

    // - Title

    /**
     * Time it takes to play a video on TitleState.
     */
    static final TITLE_VIDEO_DELAY:Float = 27.5;

    ////// ------- GAMEPLAY RELATED CONSTANTS

    /**
     * The default intensity multiplier for camera bops.
     */
    static final DEFAULT_BOP_INTENSITY:Float = 1.015;

    /**
     * The default rate for camera bops (in beats per bop).
     */
    static final DEFAULT_BOP_RATE:Int = 4;
}