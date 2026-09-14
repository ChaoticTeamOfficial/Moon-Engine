package moon.toolkit.level_editor;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxRect;
import flixel.util.FlxColor;
import flixel.graphics.FlxGraphic;
import openfl.geom.Rectangle;
import moon.game.PlayState;
import moon.backend.Conductor;
import moon.backend.data.Chart;
import moon.toolkit.ui.*;

// TODO: wait i forgot hold on
class EditorGrid extends FlxSpriteGroup
{
	public static final LANE_WIDTH:Int = 32;
	public static final LANE_HEIGHT:Int = 32;
	public static final INITIAL_Y:Float = 48;
	public static final PLAYHEAD_OFFSET:Float = 48;

	public var numLanes:Int = 8;
	public var totalLanes:Int = 9;
	public var gridWidth:Int = 0;
	public var totalHeight:Float = 0;
	public var segments:Array<
		{startTime:Float, startY:Float, stepCrochet:Float}> = [];
	public var conductor:Conductor;
	public var fullLength:Float = 0;
	public var content:FlxSpriteGroup;
	public var noteGroup:FlxSpriteGroup;
	public var eventsGroup:FlxSpriteGroup;
	public var miscGroup:FlxSpriteGroup;
	public var colorRegions:Array<
		{
			startTime:Float,
			endTime:Float,
			laneGroupIndex:Int,
			color:FlxColor
		}> = [];

	var game:PlayState;
	var gridSprites:FlxSpriteGroup;
	var regionSprites:FlxSpriteGroup;
	var graphicCache:Map<String, FlxGraphic> = new Map();
	var playhead:MoonSprite;
	var _scrollY:Float = 0;

	public function new(game:PlayState)
	{
		super();
		this.game = game;
		this.conductor = game.conductor;
		this.fullLength = game.playField.playback.fullLength;

		final chart = game.playField.chart;
		final lanes = chart.content.meta.lanes ?? ["opponent", "p1"];
		numLanes = 4 * lanes.length;
		totalLanes = numLanes + 1;
		gridWidth = LANE_WIDTH * totalLanes;

		x = FlxG.width - gridWidth - 48;
		y = INITIAL_Y;

		content = new FlxSpriteGroup();
		add(content);

		gridSprites = new FlxSpriteGroup();
		content.add(gridSprites);

		regionSprites = new FlxSpriteGroup();
		content.add(regionSprites);

		noteGroup = new FlxSpriteGroup();
		content.add(noteGroup);

		eventsGroup = new FlxSpriteGroup();
		content.add(eventsGroup);

		miscGroup = new FlxSpriteGroup();
		content.add(miscGroup);

		playhead = new MoonSprite(0, PLAYHEAD_OFFSET);
		playhead.makeGraphic(gridWidth, 2, FlxColor.WHITE);
		playhead.active = false;
		add(playhead);

		rebuild();
	}

	public function rebuild():Void
	{
		gridSprites.clear();
		regionSprites.clear();
		segments = [];
		graphicCache.clear();
		totalHeight = 0;
		_scrollY = 0;
		content.y = 0;

		final chart = game.playField.chart;
		fullLength = game.playField.playback.fullLength;

		final changes:Array<
			{time:Float, bpm:Float, numerator:Float, denominator:Float}> = [{
			time: 0,
			bpm: chart.content.meta.bpm,
			numerator: chart.content.meta.timeSignature[0],
			denominator: chart.content.meta.timeSignature[1]
		}];

		for (e in chart.events)
		{
			if (e.tag == 'Change Playback Settings')
			{
				changes.push({
					time: e.time,
					bpm: e.values.bpm,
					numerator: e.values.timeSignature[0],
					denominator: e.values.timeSignature[1]
				});
			}
		}
		changes.sort((a, b) -> Std.int(a.time - b.time));

		final tempConductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);
		var currentY:Float = 0;

		for (i in 0...changes.length)
		{
			final ch = changes[i];
			tempConductor.time = ch.time;
			tempConductor.changeBpmAt(ch.time, ch.bpm, ch.numerator, ch.denominator);

			final nextTime = (i < changes.length - 1) ? changes[i + 1].time : fullLength;
			if (nextTime - ch.time <= 0) continue;

			final segSteps = (nextTime - ch.time) / tempConductor.stepCrochet;
			final stepsPerSection = ch.numerator * ch.denominator;
			final sectionHeight:Int = Std.int(stepsPerSection * LANE_HEIGHT);
			final beatHeight:Int = Std.int(ch.numerator * LANE_HEIGHT);

			final cacheKey = ch.numerator + "," + ch.denominator;
			if (!graphicCache.exists(cacheKey))
			{
				var tileSprite = new MoonSprite().makeGraphic(gridWidth, sectionHeight, FlxColor.TRANSPARENT);

				for (b in 0...Std.int(
					ch.denominator
				)) tileSprite.pixels.fillRect(new Rectangle(0, b * beatHeight, gridWidth, beatHeight), (b % 2 == 0) ? 0xFF2a2a2c : 0xFF373739);

				tileSprite.pixels.fillRect(new Rectangle(numLanes * LANE_WIDTH, 0, LANE_WIDTH, sectionHeight), FlxColor.BLACK);

				for (s in 0...Std.int(stepsPerSection) + 1) tileSprite.pixels.fillRect(new Rectangle(0, s * LANE_HEIGHT, gridWidth, 1), FlxColor.GRAY);

				tileSprite.pixels.fillRect(new Rectangle(0, 0, gridWidth, 2), FlxColor.WHITE);

				for (l in 0...totalLanes + 1) tileSprite.pixels.fillRect(new Rectangle(l * LANE_WIDTH, 0, 1, sectionHeight), FlxColor.BLACK);

				for (g in 1...Std.int(numLanes / 4))
				{
					final lx = g * 4 * LANE_WIDTH;
					tileSprite.pixels.fillRect(new Rectangle(lx - 1, 0, 3, sectionHeight), FlxColor.BLACK);
				}

				tileSprite.dirty = true;
				tileSprite.active = false;
				graphicCache.set(cacheKey, tileSprite.graphic);
			}

			final tileGraphic = graphicCache.get(cacheKey);

			final numFullSections = Std.int(Math.floor(segSteps / stepsPerSection));
			var secY:Float = currentY;
			for (sec in 0...numFullSections)
			{
				var secSprite = new MoonSprite(0, secY).loadGraphic(tileGraphic);
				secSprite.antialiasing = false;
				secSprite.active = false;
				gridSprites.add(secSprite);
				secY += sectionHeight;
			}

			final remainderSteps = segSteps - (numFullSections * stepsPerSection);
			if (remainderSteps > 0.001)
			{
				final remainderHeight = remainderSteps * LANE_HEIGHT;
				var lastSprite = new MoonSprite(0, secY).loadGraphic(tileGraphic);
				lastSprite.antialiasing = false;
				lastSprite.active = false;
				lastSprite.clipRect = new FlxRect(0, 0, gridWidth, remainderHeight);
				lastSprite.height = remainderHeight;
				lastSprite.updateHitbox();
				gridSprites.add(lastSprite);
				secY += remainderHeight;
			}

			segments.push({
				startTime: ch.time,
				startY: currentY,
				stepCrochet: tempConductor.stepCrochet
			});
			currentY = secY;
		}

		totalHeight = currentY;
		refreshColorRegions();
	}

	public function addColorRegion(startTime:Float, endTime:Float, laneGroupIndex:Int, color:FlxColor):Void
	{
		colorRegions.push({
			startTime: startTime,
			endTime: endTime,
			laneGroupIndex: laneGroupIndex,
			color: color
		});
		refreshColorRegions();
	}

	public function clearColorRegions():Void
	{
		colorRegions = [];
		regionSprites.clear();
	}

	function refreshColorRegions():Void
	{
		regionSprites.clear();
		if (colorRegions.length == 0 || segments.length == 0) return;

		for (region in colorRegions)
		{
			final y0 = timeToY(region.startTime);
			final y1 = timeToY(region.endTime);
			final h = Math.max(1, y1 - y0);

			final groups = (region.laneGroupIndex < 0) ? [for (g in 0...Std.int(numLanes / 4)) g] : [region.laneGroupIndex];

			for (g in groups)
			{
				if (g < 0 || g >= Std.int(numLanes / 4)) continue;
				final rx = g * 4 * LANE_WIDTH;
				var overlay = new MoonSprite(rx, y0).makeGraphic(4 * LANE_WIDTH, Std.int(h), region.color);
				overlay.alpha = 0.2;
				overlay.blend = ADD;
				overlay.active = false;
				overlay.antialiasing = false;
				regionSprites.add(overlay);
			}
		}
	}

	public function timeToY(time:Float):Float
	{
		if (time <= 0 || segments.length == 0) return 0;
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextStart = (i < segments.length - 1) ? segments[i + 1].startTime : fullLength;
			if (time < nextStart) return seg.startY + ((time - seg.startTime) / seg.stepCrochet * LANE_HEIGHT);
		}
		final last = segments[segments.length - 1];
		return last.startY + ((time - last.startTime) / last.stepCrochet * LANE_HEIGHT);
	}

	public function yToTime(y:Float):Float
	{
		if (y <= 0 || segments.length == 0) return 0;
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextY = (i < segments.length - 1) ? segments[i + 1].startY : Math.POSITIVE_INFINITY;
			if (y < nextY) return seg.startTime + ((y - seg.startY) / LANE_HEIGHT * seg.stepCrochet);
		}
		final last = segments[segments.length - 1];
		return last.startTime + ((y - last.startY) / LANE_HEIGHT * last.stepCrochet);
	}

	public function snapTime(rawTime:Float, snap:Int = 16):Float
	{
		if (snap <= 0 || segments.length == 0) return rawTime;
		final seg = getSegmentAt(rawTime);
		final beatCrochet = seg.stepCrochet * 4;
		return seg.startTime + (Math.round(((rawTime - seg.startTime) / beatCrochet) * snap) / snap) * beatCrochet;
	}

	public function getSegmentAt(time:Float):
		{startTime:Float, startY:Float, stepCrochet:Float}
	{
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextStart = (i < segments.length - 1) ? segments[i + 1].startTime : fullLength;
			if (time < nextStart) return seg;
		}
		return segments[segments.length - 1];
	}

	public function screenToContentY(screenY:Float):Float return screenY - this.y - content.y;

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		if (conductor == null) return;

		final targetScroll = -timeToY(conductor.time) + PLAYHEAD_OFFSET;
		_scrollY = FlxMath.lerp(_scrollY, targetScroll, Math.min(1, elapsed * 28));
		content.y = _scrollY;
		playhead.y = PLAYHEAD_OFFSET;
	}

	override public function destroy():Void
	{
		graphicCache.clear();
		super.destroy();
	}
}
