package moon.global_obj;

import openfl.display.Sprite;
import openfl.display.Shape;
import openfl.text.TextField;
import openfl.text.TextFormat;
import openfl.events.Event;
import openfl.Lib;
import haxe.Timer;

class VolumeOverlay extends Sprite
{
	public static var instance:VolumeOverlay;

	public static function show():Void if (instance != null) instance._show();

	public var barBackground:Shape = new Shape();
	public var barFill:Shape = new Shape();
	public var labelField:TextField = new TextField();
	public var barW:Float = 260;
	public var barH:Float = 10;
	public var corner:Float = 5;
	public var labelGap:Float = 6;
	public var showDuration:Float = 2.5;
	public var fadeSpeed:Float = 12.0;
	public var bgColor:Int = 0xFF000000;
	public var bgAlpha:Float = 0.55;
	public var fillColor:Int = 0xFFFFFFFF;
	public var fillAlpha:Float = 0.90;

	private var _targetAlpha:Float = 0.0;
	private var _hideTimer:Float = 0.0;
	private var _lastKnownVol:Float = -1.0;
	private var _lastStamp:Float = 0.0;

	public function new()
	{
		super();
		instance = this;
		mouseEnabled = false;
		mouseChildren = false;

		addChild(barBackground);
		addChild(barFill);
		addChild(labelField);

		labelField.selectable = false;
		labelField.mouseEnabled = false;

		alpha = 0.0;
		_lastStamp = Timer.stamp();

		_redraw(MoonSettings.callSetting('Master Volume') / 100);
		_reposition();

		addEventListener(Event.ADDED_TO_STAGE, _ ->
		{
			_reposition();
			stage.addEventListener(Event.RESIZE, _ -> _reposition());
		});

		addEventListener(Event.ENTER_FRAME, _onEnterFrame);
	}

	public function _show():Void
	{
		_redraw(MoonSettings.callSetting('Master Volume') / 100);
		_targetAlpha = 1.0;
		_hideTimer = showDuration;
	}

	private function _redraw(vol:Float):Void
	{
		_lastKnownVol = vol;

		barBackground.graphics.clear();
		barBackground.graphics.beginFill(bgColor & 0xFFFFFF, bgAlpha);
		barBackground.graphics.drawRoundRect(0, 0, barW, barH, corner, corner);
		barBackground.graphics.endFill();

		barFill.graphics.clear();
		barFill.graphics.beginFill(fillColor & 0xFFFFFF, fillAlpha);
		barFill.graphics.drawRoundRect(0, 0, Math.max(corner * 2, barW * vol), barH, corner, corner);
		barFill.graphics.endFill();

		final pct:Int = Math.round(vol * 100);
		final fmt = new TextFormat(Paths.font('phantomuff/full.ttf'), 14, 0xFFFFFF);
		labelField.defaultTextFormat = fmt;
		labelField.text = 'MASTER VOLUME   $pct%';
		labelField.autoSize = LEFT;

		labelField.x = (barW - labelField.textWidth) * 0.5;
		labelField.y = -(labelField.textHeight + labelGap);
	}

	private function _reposition():Void
	{
		x = (((stage != null) ? stage.stageWidth : Lib.application.window.width) - barW) * 0.5;
		y = 56;
	}

	private function _onEnterFrame(_:Event):Void
	{
		final now:Float = Timer.stamp();
		final dt:Float = Math.min(now - _lastStamp, 0.1);
		_lastStamp = now;

		if (_hideTimer > 0)
		{
			_hideTimer -= dt;
			if (_hideTimer <= 0) _targetAlpha = 0.0;
		}

		final diff:Float = _targetAlpha - this.alpha;
		if (Math.abs(diff) > 0.004) this.alpha += diff * fadeSpeed * dt;
		else
			this.alpha = _targetAlpha;

		barFill.visible = MoonSettings.callSetting('Master Volume') / 100 > 0;

		if (Math.abs((MoonSettings.callSetting('Master Volume') / 100) - _lastKnownVol) > 0.004) _show();
	}
}
