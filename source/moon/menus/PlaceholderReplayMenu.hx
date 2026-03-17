package moon.menus;

import moon.game.*;
import moon.game.obj.*;

using StringTools;
class PlaceholderReplayMenu extends FlxSubState
{
	var replays:Array<FlxText> = [];
	final dir = Paths.readDir('data/replays', ['.mrp']);
	public function new()
	{
		super();

		bgColor = FlxColor.BLACK;
		
		for(i in 0...dir.length)
		{
			var text = new FlxText(0, 32 + 26 * i);
			text.size = 24;
			text.text = dir[i];
			add(text);
			replays.push(text);
		}
		changeSelection(0);
	}

	var curSelected:Int = 0;
	function changeSelection(change:Int = 0):Void
    {
        curSelected = FlxMath.wrap(curSelected + change, 0, replays.length - 1);
        Paths.playSFX('ui/scrollMenu.ogg');
        
        for(i in 0...replays.length)
            replays[i].color = i == curSelected ? FlxColor.CYAN : FlxColor.WHITE;
    }

    override public function update(elapsed:Float)
    {
        if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
        if (MoonInput.justPressed(UI_UP)) changeSelection(-1);

        if (MoonInput.justPressed(ACCEPT))
        {
        	final curThingie = replays[curSelected].text;
        	PlayState.songData = {
	            song: curThingie.split('_')[0],
	            difficulty: curThingie.split('_')[1],
	            mix: curThingie.split('_')[2]
	        };

	        final rep = PlayState.loadReplay('data/replays/$curThingie.mrp');
	        if (rep != null)
	            FlxG.switchState(() -> new PlayState(rep));

	        if(FlxG.sound.music != null)
	        	FlxG.sound.music.stop();
        }

        if(MoonInput.justPressed(BACK)) close();
    }
}