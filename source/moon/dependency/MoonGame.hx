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

		#if !android
        Mods.scanMods();
		#end
    	// AFTER game initializes...
        super(gameWidth, gameHeight, initialState, updateFramerate, drawFramerate, skipSplash, startFullscreen);
        
		MoonSettings.init();
        Alphabet.init();
        SongData.init();

        FlxG.plugins.addPlugin(new flixel.addons.plugin.ScreenShotPlugin());
        flixel.addons.plugin.ScreenShotPlugin.screenshotKeys = [F3];
        //screenshotplugin.ScreenShotPlugin.screenshotKey = F3;

        FlxG.stage.addEventListener(openfl.events.KeyboardEvent.KEY_DOWN, (e) ->
		{
            final kc = e.keyCode;

			// prevents keyboard presses when going on fullscreen
            // got from FE, by crowplexus and nebulazorua
			if (kc == FlxKey.ENTER && e.altKey)
				e.stopImmediatePropagation();

            // update volume settings when the volume is changed.
            // TODO: fix the fact that when holding a key it fucks up.
            if ((kc == FlxKey.PLUS || kc == FlxKey.NUMPADPLUS) || (kc == FlxKey.MINUS || kc == FlxKey.NUMPADMINUS))
			{
			    final change:Float = (kc == FlxKey.PLUS || kc == FlxKey.NUMPADPLUS) ? 0.05 : -0.05;
			    final newVol:Float = FlxMath.bound(FlxG.sound.volume + change, 0, 1);

			    MoonSettings.setSetting("Master Volume", newVol * 100);
			}
		}, false, 100);
		
        /*#if system
		if(!sys.FileSystem.exists('mods'))
			sys.FileSystem.createDirectory('mods');
        #end*/
    }
}