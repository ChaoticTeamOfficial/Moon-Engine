package moon.toolkit.level_editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.geom.Rectangle;
import moon.game.PlayState;
import moon.toolkit.ui.*;

// TODO: Fix the centering and zooms. It's pretty incorrect but HELL i'm lazy...

typedef CameraInfo =
{
	var x:Float;
	var y:Float;
	var width:Int;
	var height:Int;
	var zoom:Float;
	var scrollX:Float;
	var scrollY:Float;
};

class MiniPlayer extends FlxSpriteGroup
{
	public static var instance:MiniPlayer;
	public static final MINI_WIDTH:Int = 640;
	public static final MINI_HEIGHT:Int = 360;
	public static final MINI_SCALE:Float = 0.4;
	static final TRANSITION_TIME:Float = 0.35;
	public static var MINI_X:Float = 64;
	public static var MINI_Y:Float = 64;

	var game:PlayState;
	var previewBorder:MoonSprite;
	var dimSprites:Array<MoonSprite> = [];
	var _origCamGame:CameraInfo;
	var _origCamHUD:CameraInfo;
	var _transitioning:Bool = true;
	var _closing:Bool = false;
	var _tweenGameZoom:Float = 1;
	var _tweenHUDZoom:Float = 1;

	public function new(game:PlayState)
	{
		super();
		instance = this;
		this.game = game;

		_origCamGame = {
			x: game.camGAME.x,
			y: game.camGAME.y,
			width: game.camGAME.width,
			height: game.camGAME.height,
			zoom: game.camGAME.zoom,
			scrollX: game.camGAME.scroll.x,
			scrollY: game.camGAME.scroll.y
		};

		_origCamHUD = {
			x: game.camHUD.x,
			y: game.camHUD.y,
			width: game.camHUD.width,
			height: game.camHUD.height,
			zoom: game.camHUD.zoom,
			scrollX: game.camHUD.scroll.x,
			scrollY: game.camHUD.scroll.y
		};

		final dimColor = 0xFF5C5C5C;
		makeDim(0, 0, FlxG.width, Std.int(MINI_Y - 4), dimColor);
		makeDim(0, MINI_Y + MINI_HEIGHT + 4, FlxG.width, Std.int(FlxG.height - (MINI_Y + MINI_HEIGHT + 4)), dimColor);
		makeDim(0, MINI_Y - 4, Std.int(MINI_X - 4), MINI_HEIGHT + 8, dimColor);
		makeDim(MINI_X + MINI_WIDTH + 4, MINI_Y - 4, Std.int(FlxG.width - (MINI_X + MINI_WIDTH + 4)), MINI_HEIGHT + 8, dimColor);

		previewBorder = new MoonSprite(MINI_X - 4, MINI_Y - 4);
		previewBorder.makeGraphic(MINI_WIDTH + 8, MINI_HEIGHT + 8, FlxColor.TRANSPARENT);
		previewBorder.pixels.fillRect(new Rectangle(0, 0, MINI_WIDTH + 8, 4), FlxColor.BLACK);
		previewBorder.pixels.fillRect(new Rectangle(0, MINI_HEIGHT + 4, MINI_WIDTH + 8, 4), FlxColor.BLACK);
		previewBorder.pixels.fillRect(new Rectangle(0, 0, 4, MINI_HEIGHT + 8), FlxColor.BLACK);
		previewBorder.pixels.fillRect(new Rectangle(MINI_WIDTH + 4, 0, 4, MINI_HEIGHT + 8), FlxColor.BLACK);
		previewBorder.dirty = true;
		previewBorder.scrollFactor.set();
		previewBorder.alpha = 0;
		add(previewBorder);

		startOpenTransition();
	}

	function makeDim(x:Float, y:Float, w:Int, h:Int, color:FlxColor):MoonSprite
	{
		var s = new MoonSprite(x, y).makeGraphic(w, h, color);
		s.alpha = 0;
		s.scrollFactor.set();
		s.active = false;
		add(s);
		dimSprites.push(s);
		return s;
	}

	function startOpenTransition():Void
	{
		_transitioning = true;

		game.zoomScale = MINI_SCALE;

		final targetGameZoom = game.lastZoom * MINI_SCALE;
		final targetHUDZoom = MINI_SCALE;

		for (d in dimSprites) FlxTween.tween(d, {
			alpha: 0.7
		}, TRANSITION_TIME, {
			ease: FlxEase.quadOut
		});

		FlxTween.tween(previewBorder, {
			alpha: 1
		}, TRANSITION_TIME, {
			ease: FlxEase.quadOut
		});

		FlxTween.tween(game.camGAME, {
			x: MINI_X,
			y: MINI_Y,
			width: MINI_WIDTH,
			height: MINI_HEIGHT,
			zoom: targetGameZoom
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: (_) ->
			{
				_transitioning = false;
				game.camGAME.setSize(MINI_WIDTH, MINI_HEIGHT);
				game.camGAME.setPosition(MINI_X, MINI_Y);
			}
		});

		FlxTween.tween(game.camHUD, {
			x: MINI_X - 164,
			y: MINI_Y - 116,
			width: MINI_WIDTH,
			height: MINI_HEIGHT,
			zoom: targetHUDZoom
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: (_) ->
			{
				game.camHUD.setSize(MINI_WIDTH, MINI_HEIGHT);
				game.camHUD.scroll.set(0, 0);
			}
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
	}

	public function closePreview(onDone:Void->Void):Void
	{
		if (_closing) return;
		_closing = true;
		_transitioning = true;

		game.zoomScale = 1;

		for (d in dimSprites) FlxTween.tween(d, {
			alpha: 0
		}, TRANSITION_TIME * 0.8, {
			ease: FlxEase.quadIn
		});

		FlxTween.tween(previewBorder, {
			alpha: 0
		}, TRANSITION_TIME * 0.8, {
			ease: FlxEase.quadIn
		});

		FlxTween.tween(game.camGAME, {
			x: _origCamGame.x,
			y: _origCamGame.y,
			width: _origCamGame.width,
			height: _origCamGame.height,
			zoom: game.lastZoom
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut
		});

		FlxTween.tween(game.camHUD, {
			x: _origCamHUD.x,
			y: _origCamHUD.y,
			width: _origCamHUD.width,
			height: _origCamHUD.height,
			zoom: 1
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: (_) ->
			{
				restoreCameras();

				if (game != null)
				{
					game.persistentUpdate = false;
					game.paused = false;
					game.allowGameBop = true;
					game.canPause = true;
				}

				if (onDone != null) onDone();
			}
		});
	}

	function restoreCameras():Void
	{
		if (game == null || _origCamGame == null) return;

		game.zoomScale = 1;

		game.camGAME.setSize(_origCamGame.width, _origCamGame.height);
		game.camGAME.setPosition(_origCamGame.x, _origCamGame.y);
		game.camGAME.zoom = game.lastZoom;
		game.camGAME.scroll.set(_origCamGame.scrollX, _origCamGame.scrollY);

		game.camHUD.setSize(_origCamHUD.width, _origCamHUD.height);
		game.camHUD.setPosition(_origCamHUD.x, _origCamHUD.y);
		game.camHUD.zoom = 1;
		game.camHUD.scroll.set(_origCamHUD.scrollX, _origCamHUD.scrollY);

		game.camGAME.follow(game.camFollower, LOCKON, 1);
		game.camGAME.focusOn(game.camFollower.getPosition());
	}

	override public function destroy():Void
	{
		instance = null;
		super.destroy();
	}
}
