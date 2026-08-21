package moon.game.obj;

import moon.backend.gameplay.Timings;
import moon.backend.gameplay.Timings.Judgement;
import flixel.group.FlxSpriteGroup;

/**
 * Precision-style accuracy bar, heavily inspired by A Dance of Fire and Ice!
 */
@:publicFields
class AccuracyBar extends FlxTypedSpriteGroup<MoonSprite>
{
	static inline final BAR_WIDTH:Int = 14;
	static inline final BAR_HEIGHT:Int = 332;
	static inline final MARKER_WIDTH:Int = 22;
	static inline final MARKER_HEIGHT:Int = 3;
	static inline final AVG_MARKER_WIDTH:Int = 32;
	static inline final AVG_MARKER_HEIGHT:Int = 5;
	static inline final MAX_HIT_MARKERS:Int = 32;
	static inline final HISTORY_SIZE:Int = 24;

	var barBG:MoonSprite;
	var segments:Array<MoonSprite> = [];
	var hitMarkers:Array<MoonSprite> = [];
	var averageMarker:MoonSprite;
	var maxMs:Float = 0;
	var history:Array<Float> = [];
	var averageMs:Float = 0;
	var markerIndex:Int = 0;

	public function new()
	{
		super();

		maxMs = Timings.get(MISS).maxMs;

		for (seg in segments) remove(seg, true);
		segments = [];

		final windows:Array<
			{j:Judgement, from:Float, to:Float}> = [];
		var prev = 0.0;
		for (j in Timings.values)
		{
			final to = Timings.get(j).maxMs;
			windows.push({
				j: j,
				from: prev,
				to: to
			});
			prev = to;
		}

		for (w in windows)
		{
			final halfSpan = ((w.to - w.from) / maxMs) * (BAR_HEIGHT * 0.5);
			if (halfSpan <= 0) continue;

			// Late side
			final late = new MoonSprite().makeGraphic(BAR_WIDTH, Std.int(Math.max(1, halfSpan)), Timings.get(w.j).color);
			late.x = 2;
			late.y = BAR_HEIGHT * 0.5 + (w.from / maxMs) * (BAR_HEIGHT * 0.5);
			segments.push(late);
			add(late);

			// Early side
			final early = new MoonSprite().makeGraphic(BAR_WIDTH, Std.int(Math.max(1, halfSpan)), Timings.get(w.j).color);
			early.x = 2;
			early.y = BAR_HEIGHT * 0.5 - (w.to / maxMs) * (BAR_HEIGHT * 0.5);
			segments.push(early);
			add(early);

			early.active = late.active = false;
		}

		final center = new MoonSprite().makeGraphic(BAR_WIDTH + 2, 2, 0xFFFFFFFF);
		center.x = 1;
		center.y = y + (BAR_HEIGHT * 0.5 - 1);
		center.alpha = 0.85;
		center.active = false;
		segments.push(center);
		add(center);

		barBG = new MoonSprite().makeGraphic(BAR_WIDTH + 4, BAR_HEIGHT + 4, 0xFF000000);
		barBG.alpha = 0.55;
		add(barBG);
		barBG.active = false;

		for (i in 0...MAX_HIT_MARKERS)
		{
			final marker = new MoonSprite().makeGraphic(MARKER_WIDTH, MARKER_HEIGHT, FlxColor.WHITE);
			marker.visible = false;
			marker.alpha = 0;
			hitMarkers.push(marker);
			add(marker);
			marker.active = false;
		}

		averageMarker = new MoonSprite().makeGraphic(AVG_MARKER_WIDTH, AVG_MARKER_HEIGHT, 0xFFFFFFFF);
		averageMarker.alpha = 0.9;
		add(averageMarker);
		averageMarker.setPosition(center.x, center.y);
		averageMarker.active = false;

		layoutMarkers();
	}

	/**
	 * Places a temporary marker for a single note hit.
	 * @param msOffset  note.time - conductor.time  (negative = early, positive = late)
	 */
	public function pushHit(msOffset:Float):Void
	{
		if (!visible) return;

		final clamped = FlxMath.bound(msOffset, -maxMs, maxMs);
		history.push(clamped);
		if (history.length > HISTORY_SIZE) history.shift();

		averageMs = 0;
		for (v in history) averageMs += v;
		averageMs /= history.length;

		final marker = hitMarkers[markerIndex];
		markerIndex = (markerIndex + 1) % MAX_HIT_MARKERS;

		marker.x = x + ((BAR_WIDTH + 4 - MARKER_WIDTH) * 0.5);
		marker.y = y + (msToY(clamped) - MARKER_HEIGHT * 0.5);
		marker.color = colorForMs(Math.abs(clamped));
		marker.visible = true;
		marker.alpha = 1;

		FlxTween.cancelTweensOf(marker);
		FlxTween.tween(marker, {
			alpha: 0
		}, 0.8, {
			ease: FlxEase.quadOut,
			startDelay: 0.4,
			onComplete: _ -> marker.visible = false
		});
	}

	public function pushMiss(msOffset:Float = 0):Void pushHit(msOffset != 0 ? msOffset : maxMs);

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);
		if (!visible) return;

		averageMarker.x = barBG.x + barBG.width / 2 - averageMarker.width / 2;
		averageMarker.y = FlxMath.lerp(averageMarker.y, y + msToY(averageMs) - AVG_MARKER_HEIGHT * 0.5, elapsed * 10);
		// averageMarker.color = colorForMs(Math.abs(averageMs));
	}

	inline function msToY(ms:Float):Float return BAR_HEIGHT * 0.5 + (FlxMath.bound(ms, -maxMs, maxMs) / maxMs) * (BAR_HEIGHT * 0.5);

	function colorForMs(absMs:Float):FlxColor
	{
		for (j in Timings.values) if (absMs <= Timings.get(j).maxMs) return Timings.get(j).color;
		return Timings.get(MISS).color;
	}

	function layoutMarkers():Void
	{
		averageMarker.x = x + ((BAR_WIDTH + 4 - AVG_MARKER_WIDTH) * 0.5);
		averageMarker.y = y + (BAR_HEIGHT * 0.5 - AVG_MARKER_HEIGHT * 0.5);
	}

	public function resetBar():Void
	{
		history = [];
		averageMs = 0;
		layoutMarkers();
		for (m in hitMarkers)
		{
			FlxTween.cancelTweensOf(m);
			m.visible = false;
			m.alpha = 0;
		}
	}
}
