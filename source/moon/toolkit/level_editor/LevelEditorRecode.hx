package moon.toolkit.level_editor;

import moon.game.PlayState;
import moon.toolkit.ui.*;
import openfl.geom.Rectangle;

class LevelEditorRecode extends FlxSubState
{
	public static var instance:LevelEditorRecode;

	var game:PlayState;
	var miniPlayer:MiniPlayer;
	var grid:EditorGrid;
	var _closing:Bool = false;

	public function new()
	{
		super();
		instance = this;
		bgColor = 0x00000000;
	}

	override public function create():Void
	{
		super.create();
		game = PlayState.instance;

		if (game == null)
		{
			close();
			return;
		}

		game.persistentUpdate = true;
		game.persistentDraw = true;

		game.allowGameBop = false;

		this.camera = game.camALT;
		game.camALT.bgColor = 0x00000000;

		miniPlayer = new MiniPlayer(game);
		miniPlayer.camera = game.camALT;
		add(miniPlayer);

		grid = new EditorGrid(game);
		grid.camera = game.camALT;
		grid.x -= 96;
		add(grid);

		grid.addColorRegion(0, 10000, 0, FlxColor.CYAN);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (game == null) return;

		if (!_closing && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.SEVEN)) closeEditor();
	}

	public function closeEditor():Void
	{
		if (_closing) return;
		_closing = true;

		if (miniPlayer != null)
		{
			miniPlayer.closePreview(() ->
			{
				if (game != null)
				{
					game.persistentUpdate = false;
					game.allowGameBop = true;
					game.canPause = true;
				}
				close();
			});
		}
		else
		{
			if (game != null)
			{
				game.persistentUpdate = false;
				game.allowGameBop = true;
				game.canPause = true;
			}
			close();
		}
	}

	override public function destroy():Void
	{
		instance = null;
		super.destroy();
	}
}
