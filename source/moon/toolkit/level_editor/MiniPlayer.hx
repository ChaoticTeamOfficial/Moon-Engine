package moon.toolkit.level_editor;

import flixel.FlxG;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import openfl.filters.BitmapFilter;
import openfl.filters.ShaderFilter;
import openfl.geom.Rectangle;
import moon.game.PlayState;
import moon.hardcoded_shaders.MiniViewportShader;
import moon.toolkit.ui.*;

// TODO: take a look into lagspikes related to shaders.

/**
 * Level-editor gameplay preview.
 */
class MiniPlayer extends FlxSpriteGroup
{
	public static var instance:MiniPlayer;
	public static final MINI_WIDTH:Int = 640;
	public static final MINI_HEIGHT:Int = 360;
	public static final MINI_SCALE:Float = 0.5;
	static final TRANSITION_TIME:Float = 0.35;
	public static var MINI_X:Float = 64;
	public static var MINI_Y:Float = 64;

	var game:PlayState;
	var previewBorder:MoonSprite;
	var dimSprites:Array<MoonSprite> = [];
	var _transitioning:Bool = true;
	var _closing:Bool = false;
	var _shaderGame:MiniViewportShader;
	var _shaderHUD:MiniViewportShader;
	var _filterGame:ShaderFilter;
	var _filterHUD:ShaderFilter;

	public var viewScale:Float = 1;
	public var viewOffX:Float = 0;
	public var viewOffY:Float = 0;

	public function new(game:PlayState)
	{
		super();
		instance = this;
		this.game = game;

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

		setupShaders();
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

	function setupShaders():Void
	{
		_shaderGame = new MiniViewportShader();
		_shaderHUD = new MiniViewportShader();
		_filterGame = new ShaderFilter(_shaderGame);
		_filterHUD = new ShaderFilter(_shaderHUD);

		ensureViewportFilter(game.camGAME, _filterGame);
		ensureViewportFilter(game.camHUD, _filterHUD);

		viewScale = 1;
		viewOffX = 0;
		viewOffY = 0;
		pushUniforms();
	}

	function ensureViewportFilter(cam:FlxCamera, filter:ShaderFilter):Void
	{
		if (cam == null || filter == null) return;

		final src:Array<BitmapFilter> = cam.filters != null ? cast cam.filters : [];
		final list:Array<BitmapFilter> = [];

		for (f in src) if (f != filter) list.push(f);

		list.push(filter);
		cam.filtersEnabled = true;
		cam.filters = list;
	}

	function ensureFilters():Void
	{
		if (_filterGame != null) ensureViewportFilter(game.camGAME, _filterGame);
		if (_filterHUD != null) ensureViewportFilter(game.camHUD, _filterHUD);
	}

	function stripViewportFilter(cam:FlxCamera, filter:ShaderFilter):Void
	{
		if (cam == null || filter == null) return;

		final src:Array<BitmapFilter> = cam.filters != null ? cast cam.filters : [];
		final list:Array<BitmapFilter> = [];
		for (f in src)
		{
			if (f != filter) list.push(f);
		}
		cam.filters = list.length > 0 ? list : null;
	}

	function pushUniforms():Void
	{
		if (_shaderGame != null)
		{
			_shaderGame.scale = viewScale;
			_shaderGame.offsetX = viewOffX;
			_shaderGame.offsetY = viewOffY;
		}
		if (_shaderHUD != null)
		{
			_shaderHUD.scale = viewScale;
			_shaderHUD.offsetX = viewOffX;
			_shaderHUD.offsetY = viewOffY;
		}
	}

	function startOpenTransition():Void
	{
		_transitioning = true;

		final targetOffX = MINI_X / FlxG.width;
		final targetOffY = MINI_Y / FlxG.height;

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

		FlxTween.tween(this, {
			viewScale: MINI_SCALE,
			viewOffX: targetOffX,
			viewOffY: targetOffY
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onUpdate: (_) -> pushUniforms(),
			onComplete: (_) ->
			{
				viewScale = MINI_SCALE;
				viewOffX = targetOffX;
				viewOffY = targetOffY;
				pushUniforms();
				_transitioning = false;
			}
		});
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (!_closing)
		{
			ensureFilters();
			pushUniforms();
		}
	}

	public function closePreview(onDone:Void->Void):Void
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

		FlxTween.tween(this, {
			viewScale: 1,
			viewOffX: 0,
			viewOffY: 0
		}, TRANSITION_TIME, {
			ease: FlxEase.expoInOut,
			onUpdate: (_) -> pushUniforms(),
			onComplete: (_) ->
			{
				viewScale = 1;
				viewOffX = 0;
				viewOffY = 0;
				pushUniforms();
				removeShaders();

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

	function removeShaders():Void
	{
		if (game == null) return;

		stripViewportFilter(game.camGAME, _filterGame);
		stripViewportFilter(game.camHUD, _filterHUD);

		_shaderGame = null;
		_shaderHUD = null;
		_filterGame = null;
		_filterHUD = null;
	}

	override public function destroy():Void
	{
		if (_filterGame != null || _filterHUD != null) removeShaders();

		instance = null;
		super.destroy();
	}
}
