package moon.dependency;

import moon.global_obj.Alphabet;
import flixel.input.keyboard.FlxKey;
import flixel.FlxG;
import flixel.FlxGame;

class MoonGame extends FlxGame
{
    override public function new(?gameWidth:Int, ?gameHeight:Int, 
        ?initialState:Null<flixel.util.typeLimit.NextState.InitialState>, ?updateFramerate:Int, ?drawFramerate:Int, 
        ?skipSplash:Bool, ?startFullscreen:Bool)
    {
    	FlxG.signals.preStateCreate.add(_ -> {
    		if(!Paths.skipNextCleanup){
    			Paths.clearMemory();
    			Paths.clearUnusedAssets();
    		}
			
    		Paths.skipNextCleanup = false;
    	});

    	Tilemap.addAtlas('mainUI', 'toolkit/ui/uiStuff');
    	FlxSprite.defaultAntialiasing = true;

        super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
        
		MoonSettings.init();
        Alphabet.init();
        SongData.init();

        MoonSettings.updateGlobalSettings();
        MoonSettings.updateWindow();

        FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) ->
		{
            final kc = e.keyCode;

			// prevents keyboard presses when going on fullscreen
            // got from FE, by crowplexus and nebulazorua
			if (kc == FlxKey.ENTER && e.altKey)
				e.stopImmediatePropagation();

            // update volume settings when the volume is changed.
            if((kc == FlxKey.PLUS || kc == FlxKey.NUMPADPLUS) || (kc == FlxKey.MINUS || kc == FlxKey.NUMPADMINUS))
			{
				MoonSettings.setSetting("Master Volume", FlxG.sound.volume * 100);
				MoonSettings.updateGlobalSettings();
			
			}
		}, false, 100);
		
        /*#if system
		if(!sys.FileSystem.exists('mods'))
			sys.FileSystem.createDirectory('mods');
        #end*/
    }
}