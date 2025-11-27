package moon.toolkit.offset;

import flixel.tweens.FlxTween;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import flixel.group.FlxSpriteContainer;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.display.FlxTiledSprite;
import openfl.geom.ColorTransform;

import moon.toolkit.ui.*;
import moon.toolkit.level_editor.EditorActions;
import moon.game.obj.*;
import moon.game.*;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;

class OffsetEditor extends FlxState
{
	public var character:String = '';
	public var char:Character;
	public function new(?character:String = 'bf')
	{
		super();
		this.character = character;
	}

	var camHUD:FlxCamera = new FlxCamera();
	override function create()
	{
		FlxG.camera.bgColor = FlxColor.fromRGB(30, 29, 31);
		camHUD.bgColor = 0x00000000;
		FlxG.cameras.add(camHUD, false);

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		// --- Create 'non hud' thingiess --- //

		char = new Character(0,0,character,null);
		add(char);
		trace('$character animations: ${char.animation.getNameList()}', "DEBUG");

		// --- Create hud stuff --- //

		var popup = new Popup(532, 264);
        popup.camera = camHUD;
        popup.alpha = 0.7;
        add(popup);
        popup.setPosition(16, 16);
        popup.scale.set(0, 0);
        FlxTween.tween(popup, {"scale.x": 1, "scale.y": 1}, 0.5, {ease: FlxEase.expoOut});
	}

    private var camDragging:Bool = false;
    private var lastMousePos:FlxPoint = FlxPoint.get();
	override function update(elapsed:Float)
	{
		super.update(elapsed);

        if (FlxG.mouse.pressedRight)
        {
            if (!camDragging){
                camDragging = true;
                lastMousePos.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
            } else{
                FlxG.camera.scroll.x -= FlxG.mouse.viewX - lastMousePos.x;
                FlxG.camera.scroll.y -= FlxG.mouse.viewY - lastMousePos.y;
                lastMousePos.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
            }
        }
        else camDragging = false;

        if (FlxG.mouse.wheel != 0) {
            final zoomSpeed = 0.1;
            FlxG.camera.zoom = FlxMath.bound(FlxG.camera.zoom + (FlxG.mouse.wheel > 0 ? zoomSpeed : -zoomSpeed), 0.2, 6);
        }
	}
}