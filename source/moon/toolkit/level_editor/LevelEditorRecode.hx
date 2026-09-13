package moon.toolkit.level_editor;

import flixel.FlxG;
import flixel.FlxSubState;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import moon.game.PlayState;
import moon.toolkit.ui.*;
import openfl.geom.Rectangle;

class LevelEditorRecode extends FlxSubState
{
	public static var instance:LevelEditorRecode;

	var game:PlayState;

	public static final MINI_WIDTH:Int = 580;
	public static final MINI_HEIGHT:Int = 326;
	public static final MINI_X:Float = 64;
	public static final MINI_Y:Float = 64;
	public static final MINI_SCALE:Float = 0.35;
	static final TRANSITION_TIME:Float = 0.65;

	var previewBorder:MoonSprite;
	var dimSprites:Array<MoonSprite> = [];
	var _origCamGame:
		{x:Float, y:Float, width:Int, height:Int, zoom:Float, scrollX:Float, scrollY:Float};
	var _origCamHUD:
		{x:Float, y:Float, width:Int, height:Int, zoom:Float, scrollX:Float, scrollY:Float};
	var _transitioning:Bool = true;
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
		add(s);
		dimSprites.push(s);
		return s;
	}

	function startOpenTransition():Void
	{
		_transitioning = true;

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
				game.camGAME.zoom = game.lastZoom * MINI_SCALE;
			}
		});

		FlxTween.tween(game.camHUD, {
			x: MINI_X - 132,
			y: MINI_Y - 32,
			width: MINI_WIDTH,
			height: MINI_HEIGHT,
			zoom: targetHUDZoom
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onComplete: (_) ->
			{
				game.camHUD.setSize(MINI_WIDTH, MINI_HEIGHT);
				game.camHUD.setPosition(MINI_X, MINI_Y);
				game.camHUD.zoom = MINI_SCALE;
				game.camHUD.scroll.set(0, 0);
			}
		});

		game.camGAME.follow(game.camFollower, LOCKON, 1);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (game == null) return;

		if (!_transitioning && !_closing)
		{
			game.camGAME.setPosition(MINI_X, MINI_Y);
			game.camHUD.setPosition(MINI_X, MINI_Y);

			game.camGAME.zoom = game.lastZoom * MINI_SCALE;
			game.camHUD.zoom = MINI_SCALE;
		}

		if (!_closing && (FlxG.keys.justPressed.ESCAPE || FlxG.keys.justPressed.SEVEN)) closeEditor();
	}

	public function closeEditor():Void
	{
		if (_closing) return;
		_closing = true;
		_transitioning = true;

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
			zoom: _origCamGame.zoom
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut
		});

		FlxTween.tween(game.camHUD, {
			x: _origCamHUD.x,
			y: _origCamHUD.y,
			width: _origCamHUD.width,
			height: _origCamHUD.height,
			zoom: _origCamHUD.zoom
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

				close();
			}
		});
	}

	function restoreCameras():Void
	{
		if (game == null || _origCamGame == null) return;

		game.camGAME.setSize(_origCamGame.width, _origCamGame.height);
		game.camGAME.setPosition(_origCamGame.x, _origCamGame.y);
		game.camGAME.zoom = _origCamGame.zoom;
		game.camGAME.scroll.set(_origCamGame.scrollX, _origCamGame.scrollY);

		game.camHUD.setSize(_origCamHUD.width, _origCamHUD.height);
		game.camHUD.setPosition(_origCamHUD.x, _origCamHUD.y);
		game.camHUD.zoom = _origCamHUD.zoom;
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
