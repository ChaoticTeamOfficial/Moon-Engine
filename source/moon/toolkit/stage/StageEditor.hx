package moon.toolkit.stage;

import moon.toolkit.level_editor.*;
import moon.game.obj.*;

class StageEditor extends FlxTransitionableState
{
	var camHUD:MoonCamera = new MoonCamera();

	override public function create()
	{
		super.create();
		FlxG.camera.bgColor = FlxColor.fromRGB(30, 29, 31);
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		Tilemap.addAtlas('btnIcons', 'toolkit/ui/googleIcons');
		var stage = new Stage('stage', null);
		add(stage);

		var lPanel = new LeftPanel(null, [
			'menu',
			'separator',
			'layers',
			'designServices',
			'separator',
			'openFolder'
		]);
		add(lPanel);
		lPanel.camera = camHUD;

		MoonUtils.playGlobalMusic('toolbox/artisticexpression', true);

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
	}

	private var camDragging:Bool = false;
	private var lastMousePos:FlxPoint = FlxPoint.get();

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.mouse.pressedRight)
		{
			if (!camDragging)
			{
				camDragging = true;
				lastMousePos.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
			}
			else
			{
				FlxG.camera.scroll.x -= FlxG.mouse.viewX - lastMousePos.x;
				FlxG.camera.scroll.y -= FlxG.mouse.viewY - lastMousePos.y;
				lastMousePos.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
			}
		}
		else
			camDragging = false;

		if (FlxG.mouse.wheel != 0)
		{
			final zoomSpeed = 0.1;
			FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom + (FlxG.mouse.wheel > 0 ? zoomSpeed : -zoomSpeed), 0.1, 6);
		}
	}
}
