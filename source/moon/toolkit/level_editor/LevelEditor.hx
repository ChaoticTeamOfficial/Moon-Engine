package moon.toolkit.level_editor;

import flixel.addons.display.FlxTiledSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.atlas.FlxAtlas;
import openfl.geom.Rectangle;
import moon.toolkit.ui.*;
import moon.game.obj.*;
import moon.game.*;
import moon.game.obj.notes.*;
import moon.dependency.scripting.*;
import moon.game.notetypes.*;
import moon.backend.data.Chart.NoteStruct;
import moon.backend.data.Chart.ChartStruct;
import moon.backend.data.Chart.EventStruct;
import openfl.filters.ColorMatrixFilter;
import openfl.ui.Mouse;
import openfl.ui.MouseCursor;
import moon.game.events.EventRegistry;
import haxe.ui.components.*;
#if sys
import sys.io.File;
#end

enum abstract GridType(String)
{
	var NOTES = 'Notes';
	var VISUALS = 'Visuals';
	var CHARACTERS = 'Characters';
	var GIMMICKS = 'Gimmicks';
	var SOUNDS = 'Sounds';
}

enum abstract PlacementMode(String)
{
	/**A mode where you place notes/events.**/
	var PLACE = 'Placing';

	/**A mode where you select & edit notes/events.**/
	var EDIT = 'Editing';
}

typedef EventInfo =
{
	var name:String;
	var description:String;
	var category:GridType;
}

class LevelEditor extends FlxState
{
	public static var instance:LevelEditor;
	// --- OBJECTS --- //
	public static var chart:Chart;

	public var conductor:Conductor;
	public var playback:Song;
	public var camBACK:MoonCamera = new MoonCamera();
	public var camMID:MoonCamera = new MoonCamera();
	public var camFRONT:MoonCamera = new MoonCamera();

	var library:Library;
	var leftpanel:LeftPanel;
	var scrollbar:ScrollBar;
	var strum:Strums;
	var cursor:FlxSprite;
	var frontOverlay:MoonSprite;

	public var eventAtlas:FlxAtlas;

	// these two are placeholders!!!
	var sectionStepper:NumberStepper;
	var copySectionBtn:Button;
	var swapSectionBtn:Button;
	private var gridGroup:FlxSpriteGroup;
	// private var sectionTexts:FlxSpriteGroup;
	private var noteGroup:FlxSpriteGroup;
	private var miscGroup:FlxSpriteGroup;
	private var eventsGroup:FlxSpriteGroup;

	public var sustainLoopOpp:MoonSound = new MoonSound().loadEmbedded(Paths.sound('toolkit/level-editor/sustainOpponent-hold.wav', 'sounds'), true, false);
	public var sustainLoopP1:MoonSound = new MoonSound().loadEmbedded(Paths.sound('toolkit/level-editor/sustainP1-hold.wav', 'sounds'), true, false);

	// --- NUMBER VARIABLES --- //
	public static final LANE_WIDTH:Int = 32;
	public static final LANE_HEIGHT:Int = 32;
	public static final initialGridY:Float = 48;
	public static var NUM_LANES:Int = 8;

	// --- GRID STUFF --- //
	var snapIndex:Int = 1;
	var curSnap:Int = 4;
	final snaps:Array<Int> = [
		0,
		4,
		8,
		12,
		16,
		20,
		24,
		32,
		48,
		64,
		96,
		192
	];
	final allTypes:Array<GridType> = [
		NOTES,
		VISUALS,
		CHARACTERS,
		GIMMICKS,
		SOUNDS
	];

	public var curType(default, set):GridType;
	public var curPlacementMode(default, set):PlacementMode = PLACE;
	public var libFocus:Bool = false;

	private var draggingNote:Note = null;
	private var selectedNotes:Array<Note> = [];
	private var dragOGlengths:Map<Note, Float> = null;
	private var editSelectedNotes:Array<Note> = [];
	private var editSelectedEvents:Array<EventSpr> = [];
	private var editNote:Note = null;
	private var editNoteStruct:NoteStruct = null;
	private var editEvent:EventSpr = null;
	private var editEventStruct:EventStruct = null;
	private var _lastEditSnapshot:String = null;

	// --- CHART-RELATED VARIABLES --- //
	public var song:String = '';
	public var diff:String = '';
	public var mix:String = '';
	// --- OTHER/MISC --- //
	public var allowEditing:Bool = true;

	var changes:Array<
		{time:Float, bpm:Float, numerator:Float, denominator:Float}>;
	var segments:Array<
		{startTime:Float, startY:Float, stepCrochet:Float}> = [];
	var sectionStarts:Array<
		{num:Int, y:Float}> = [];
	var graphicCache:Map<String, FlxGraphic> = new Map<String, FlxGraphic>();

	public var loadedEvents:Map<GridType, Array<EventInfo>> = [
		NOTES => [],
		VISUALS => [],
		SOUNDS => [],
		CHARACTERS => [],
		GIMMICKS => []
	];
	public var grayscale:GrayscaleShader = new GrayscaleShader();
	public var invertColors:InvertColor = new InvertColor();

	public function new(song:String = 'darnell', diff:String = 'hard', mix:String = 'bf')
	{
		this.song = song;
		this.diff = diff;
		this.mix = mix;
		super();

		DiscordRPC.updatePresence(EDITOR, '', '', true);
	}

	// TODO: take a look on event and note deletion, it seems to get stuck sometimes?
	// I suck at this lolll

	override public function create()
	{
		// --- SETUP BACKEND STUFF --- //
		instance = this;
		camBACK.bgColor = 0xFF1e1d1f;
		camMID.bgColor = 0x00000000;
		camFRONT.bgColor = 0x00000000;

		PlayState.instance = null;
		PlayField.instance = null;

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
		FlxG.cameras.add(camBACK, true);
		FlxG.cameras.add(camMID, false);
		FlxG.cameras.add(camFRONT, false);

		FlxG.sound.list.add(sustainLoopOpp);
		FlxG.sound.list.add(sustainLoopP1);

		moon.game.PlayState.songData = {
			song: song,
			difficulty: diff,
			mix: mix
		};

		EventRegistry.init();

		// Thanks rapper for letting me know about FlxAtlas!
		// nice lil thing we can use to batch events.
		eventAtlas = new FlxAtlas("eventAtlas");
		for (dir in [
			'CHARACTERS',
			'VISUALS',
			'GIMMICKS',
			'NOTES',
			'SOUNDS'
		]) for (file in Paths.readDir(
			'images/toolkit/level-editor/icons/_$dir',
			['.png']
		)) eventAtlas.addNode(Paths.image('toolkit/level-editor/icons/_$dir/$file').bitmap, '$dir-$file');

		// preload hardcoded events
		for (eventTag in EventRegistry.getHardcodedTags())
		{
			final evData = EventRegistry.getEditorData(eventTag);
			if (evData != null) loadedEvents.get(evData.category).push(evData);
		}

		// and now for softcoded ones (script-based events)!
		final dir = Paths.readDir('data/events', ['.hx']);
		if (dir.length > 0)
		{
			for (file in dir)
			{
				var preloadEvent = new MoonEvent(file, null);
				final evData = preloadEvent.retrieveEditorData();
				// trace(evData, "DEBUG");
				loadedEvents.get(evData.category).push(evData);
			}
		}

		// Sort events alphabetically within each category
		for (type => arr in loadedEvents)
		{
			arr.sort((a, b) ->
			{
				final aLower = a.name.toLowerCase();
				final bLower = b.name.toLowerCase();
				return (aLower < bLower) ? -1 : (aLower > bLower) ? 1 : 0;
			});
		}

		// we'll go over it again now but for notes.
		NoteTypeRegistry.init();

		for (typeName in NoteTypeRegistry.getHardcodedNames())
		{
			final data = NoteTypeRegistry.getEditorData(typeName);
			if (data != null) loadedEvents.get(NOTES).push(data);
		}

		for (file in Paths.readDir('data/notetypes', ['.hx'], true))
		{
			var alreadyLoaded = false;
			for (t in loadedEvents.get(NOTES)) if (t.name == file)
			{
				alreadyLoaded = true;
				break;
			}

			if (!alreadyLoaded) loadedEvents.get(NOTES).push({
				name: file,
				description: 'Script-based note type.',
				category: NOTES
			});
		}

		loadedEvents.get(NOTES).sort((a, b) -> a.name.toLowerCase() < b.name.toLowerCase() ? -1 : 1);

		// trace(loadedEvents, "DEBUG");

		Tilemap.addAtlas('MELE-buttons', 'toolkit/level-editor/icons/gridTypes');
		Tilemap.addAtlas('btnIcons', 'toolkit/ui/googleIcons');

		chart = new Chart(song, diff, mix);
		NUM_LANES = 4 * chart.content.meta.lanes.length;

		conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);
		playback = new Song(song, mix, diff, conductor);

		// --- GENERATE OBJECTSS --- //

		// Collects BPM and time signature changes
		// TODO: Make... the... added events also push to this?
		// got lost writing that lol
		changes = [{
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

		gridGroup = new FlxSpriteGroup(FlxG.width / 2 + 132, initialGridY);
		// sectionTexts = new FlxSpriteGroup();
		// gridGroup.add(sectionTexts);

		final TOTAL_LANES:Int = NUM_LANES + 1;
		final gridWidth:Int = LANE_WIDTH * TOTAL_LANES;
		var currentY:Float = 0;
		// var sectionNum:Int = 0;
		var tempConductor:Conductor = new Conductor(chart.content.meta.bpm, chart.content.meta.timeSignature[0], chart.content.meta.timeSignature[1]);

		// make grid!
		for (i in 0...changes.length)
		{
			final ch = changes[i];
			tempConductor.time = ch.time;
			tempConductor.changeBpmAt(ch.time, ch.bpm, ch.numerator, ch.denominator);

			final nextTime = (i < changes.length - 1) ? changes[i + 1].time : playback.fullLength;
			if (nextTime - ch.time <= 0) continue;

			final segSteps = (nextTime - ch.time) / tempConductor.stepCrochet;
			final stepsPerSection = ch.numerator * ch.denominator;
			final sectionHeight:Int = Std.int(stepsPerSection * LANE_HEIGHT);
			final beatHeight:Int = Std.int(ch.numerator * LANE_HEIGHT);

			var tileGraphic:FlxGraphic;
			final cacheKey = ch.numerator + "," + ch.denominator;
			if (!graphicCache.exists(cacheKey))
			{
				// why not make a tile myself?! >:3
				// its fun actuallyy
				// I like openfl renctangless,,
				// RECTANGLES WOOOOO
				var tileSprite = new MoonSprite().makeGraphic(gridWidth, sectionHeight, FlxColor.TRANSPARENT);

				for (b in 0...Std.int(
					ch.denominator
				)) tileSprite.pixels.fillRect(new Rectangle(0, b * beatHeight, gridWidth, beatHeight), (b % 2 == 0) ? 0xFF2a2a2c : 0xFF373739);
				tileSprite.pixels.fillRect(new Rectangle(NUM_LANES * LANE_WIDTH, 0, LANE_WIDTH, sectionHeight), FlxColor.BLACK);

				for (s in 0...Std.int(stepsPerSection) + 1) tileSprite.pixels.fillRect(new Rectangle(0, s * LANE_HEIGHT, gridWidth, 1), FlxColor.GRAY);

				tileSprite.pixels.fillRect(new Rectangle(0, 0, gridWidth, 2), FlxColor.WHITE);

				for (l in 0...TOTAL_LANES + 1) tileSprite.pixels.fillRect(new Rectangle(l * LANE_WIDTH, 0, 1, sectionHeight), FlxColor.BLACK);

				tileSprite.pixels.fillRect(new Rectangle(4 * LANE_WIDTH - 1, 0, 3, sectionHeight), FlxColor.BLACK);

				tileSprite.dirty = true;
				tileSprite.active = false;
				graphicCache.set(cacheKey, tileSprite.graphic);
			}

			tileGraphic = graphicCache.get(cacheKey);

			// break the segment into per-section sprites
			final numFullSections:Int = Std.int(Math.floor(segSteps / stepsPerSection));
			var secY:Float = currentY;
			for (sec in 0...numFullSections)
			{
				var secSprite = new MoonSprite(0, secY).loadGraphic(tileGraphic);
				secSprite.antialiasing = false;
				secSprite.active = false;
				gridGroup.add(secSprite);
				secY += sectionHeight;
			}
			final remainderSteps = segSteps - (numFullSections * stepsPerSection);
			if (remainderSteps > 0)
			{
				final remainderHeight = remainderSteps * LANE_HEIGHT;
				var lastSprite = new MoonSprite(0, secY).loadGraphic(tileGraphic);
				lastSprite.antialiasing = false;
				lastSprite.active = false;
				lastSprite.clipRect = new FlxRect(0, 0, gridWidth, remainderHeight);
				lastSprite.height = remainderHeight;
				lastSprite.updateHitbox();
				gridGroup.add(lastSprite);
				secY += remainderHeight;
			}

			// Add section texts
			// Because I enjoy having them
			// It's also a nice help :P

			// well UHH!! New design removes em!
			// soo bye bye section indicators...
			/*final numSectionsSeg = Math.ceil(segSteps / stepsPerSection);
				for (sec in 0...numSectionsSeg)
				{
					var txt:FlxText = new FlxText(0, 0, 100, '${sectionNum + sec + 1}', 16);
					txt.setFormat(Paths.font('KodeMono-Bold.ttf'), 28, RIGHT);
					txt.updateHitbox();
					var secY:Float = currentY + (sec * sectionHeight);
					txt.setPosition(-16, secY - (txt.height / 2));
					txt.x -= txt.width;
					sectionTexts.add(txt);

					sectionStarts.push({num: sectionNum + sec + 1, y: secY});
			}*/

			segments.push({
				startTime: ch.time,
				startY: currentY,
				stepCrochet: tempConductor.stepCrochet
			});
			// sectionNum += numSectionsSeg;
			currentY = secY;
		}
		add(gridGroup);

		noteGroup = new FlxSpriteGroup();
		gridGroup.add(noteGroup);

		for (nData in chart.content.notes) createNote(nData);

		eventsGroup = new FlxSpriteGroup();
		gridGroup.add(eventsGroup);

		for (event in chart.events) createEvent(event);

		miscGroup = new FlxSpriteGroup();
		gridGroup.add(miscGroup);

		scrollbar = new ScrollBar(currentY, conductor, segments, playback);
		add(scrollbar);
		scrollbar.y = initialGridY + 8;
		scrollbar.x = gridGroup.x + gridWidth + 16;

		cursor = new MoonSprite();
		cursor.makeGraphic(LANE_WIDTH, LANE_HEIGHT, FlxColor.WHITE);
		cursor.antialiasing = false;
		cursor.alpha = 0.55;
		cursor.visible = false;
		add(cursor);

		// lol
		final ogC = 0xFF1e1d1f;
		var colors = [ogC];
		for (i in 0...10) colors.push(FlxColor.TRANSPARENT);
		colors.push(ogC);
		add(FlxGradient.createGradientFlxSprite(FlxG.width, FlxG.height, colors));

		strum = new Strums(gridGroup.x, initialGridY);
		add(strum);

		for (i in 0...allTypes.length)
		{
			final gType = allTypes[i];
			final s:String = '$gType'.toLowerCase();

			var button = new MoonSprite(0, -16);
			button.frames = Tilemap.getAtlasFrames('MELE-buttons');
			button.animation.addByPrefix('idle', 'type-$s-normal-', 1, false);
			button.animation.addByPrefix('click', 'type-$s-click-', 1, false);
			add(button);
			button.centerAnimations = true;
			button.scale.set(0.65, 0.65);
			button.updateHitbox();
			button.antialiasing = true;
			button.x = gridGroup.x - button.width;
			button.y += (button.height + 52 * i);
			button.animation.play('idle');
			button.active = false;
			typeButtons.set(gType, button);
		}

		library = new Library();
		add(library);

		leftpanel = new LeftPanel(this);
		leftpanel.camera = camFRONT;
		add(leftpanel);

		/*for(i in 0...60)
			{
				var atlasTest = new MoonSprite(16 * i, 16 * i);
				atlasTest.frames = eventAtlas.getAtlasFrames();
				atlasTest.animation.frameName = "Change Layer Parallax";
				add(atlasTest);
				atlasTest.antialiasing = false;
		}*/

		// final stuff = {title: 'Welcome to the Editor!', description: 'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.', button1: 'Show me around.', button2: 'Okay.'};
		// openSubState(new EditorPopup(NOTICE, stuff));

		// me when I debug
		FlxG.watch.addMouse();

		FlxG.autoPause = false;
		playback.state = PAUSE;
		curType = NOTES;

		// TODO: these are placeholders for now! eventually add the proper stuff.
		final gridRight = gridGroup.x + (LANE_WIDTH * (NUM_LANES + 1)) + 40 + scrollbar.width + 24;
		sectionStepper = new NumberStepper();
		sectionStepper.left = gridRight;
		sectionStepper.top = 54;
		sectionStepper.width = 80;
		sectionStepper.value = 1;
		sectionStepper.step = 1;
		add(sectionStepper);

		copySectionBtn = new Button();
		copySectionBtn.left = gridRight;
		copySectionBtn.top = 54 + 38;
		copySectionBtn.width = 80;
		copySectionBtn.text = "Copy Section";
		copySectionBtn.onClick = (_) ->
		{
			final curSec = getCurSection();
			final sourceSec = curSec + Std.int(sectionStepper.value);
			if (sourceSec < 0) return;

			for (n in getSectionNotes(sourceSec))
			{
				final pasted:NoteStruct = {
					time: n.time - getSectionStartTime(sourceSec) + getSectionStartTime(curSec),
					data: n.data,
					lane: n.lane,
					type: n.type,
					duration: n.duration,
					values: n.values
				};

				if (!Lambda.exists(chart.content.notes, e -> Math.abs(e.time - pasted.time) < 0.01 && e.data == pasted.data && e.lane == pasted.lane))
				{
					chart.content.notes.push(pasted);
					createNote(pasted);
					History.pushNotePlace(pasted);
				}
			}
			chart.content.notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
			sfx('copySection');
		};
		add(copySectionBtn);

		swapSectionBtn = new Button();
		swapSectionBtn.left = gridRight;
		swapSectionBtn.top = 54 + 38 + 38;
		swapSectionBtn.width = 80;
		swapSectionBtn.text = "Swap Section";
		swapSectionBtn.onClick = (_) ->
		{
			swapCurrentSection();
			sfx('laneSwap${FlxG.random.bool(0.5) ? "-secret" : ""}', false, true);
		};
		add(swapSectionBtn);

		frontOverlay = new MoonSprite().makeGraphic(FlxG.width + 16, FlxG.height + 16, FlxColor.BLACK);
		frontOverlay.camera = camMID;
		add(frontOverlay);

		History.reset();
		Global.allowInputs = true;
	}

	var changeIndex:Int = 1;
	var typeButtons:Map<GridType, MoonSprite> = [];
	var rpcUpdateTmr:Float = 0;

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

		frontOverlay.alpha = FlxMath.lerp(frontOverlay.alpha, allowEditing ? 0 : 0.6, elapsed * 4);
		libFocus = FlxG.mouse.overlaps(library.bg2);

		rpcUpdateTmr += elapsed;
		if (rpcUpdateTmr >= 0.6)
		{
			rpcUpdateTmr = 0;
			DiscordRPC.updatePresence(EDITOR, 'Editing ${chart.content.meta.displayName} - ${diff.toUpperCase()}', 'At the $curType Tab.', false);
		}

		library.active = !leftpanel.panelOpen;

		// ----- Input Stuff ----- //
		final haxeUIFocused = haxe.ui.focus.FocusManager.instance.focus != null;

		updateCursor();

		if (curPlacementMode == EDIT) updateEditingValues();

		if (!haxeUIFocused && allowEditing)
		{
			if (FlxG.keys.pressed.CONTROL)
			{
				if (MoonInput.justPressed(UI_LEFT) || MoonInput.justPressed(UI_RIGHT))
				{
					snapIndex = (MoonInput.justPressed(UI_LEFT) ? snapIndex - 1 + snaps.length : snapIndex + 1) % snaps.length;
					curSnap = snaps[snapIndex];
				}

				if (FlxG.keys.justPressed.Z)
				{
					if (History.undo())
					{
						sfx('undo', false, true);
						updateNotesFilter();
					}
				}
				else if (FlxG.keys.justPressed.Y)
				{
					if (History.redo())
					{
						sfx('redo', false, true);
						updateNotesFilter();
					}
				}
			}
			else
			{
				final addition = (FlxG.keys.pressed.SHIFT) ? 4 : 1;
				final advanceSecs = conductor.stepCrochet * 2 * addition;

				if (MoonInput.justPressed(UI_LEFT)) playback.time -= advanceSecs;
				else if (MoonInput.justPressed(UI_RIGHT)) playback.time += advanceSecs;
			}

			if (FlxG.keys.justPressed.SPACE)
			{
				playback.state = (playback.state != PLAY) ? PLAY : PAUSE;
				if (playback.state == PAUSE)
				{
					sustainLoopOpp.pause();
					sustainLoopP1.pause();
				}
			}

			if (FlxG.mouse.wheel != 0 && !libFocus)
			{
				playback.time -= FlxG.mouse.wheel * conductor.stepCrochet * (FlxG.keys.pressed.SHIFT ? 4 : 1);
				sfx('scroll', false, true);
			}

			for (type => button in typeButtons) if (FlxG.mouse.overlaps(button, button.camera) && FlxG.mouse.justPressed) curType = type;

			if (FlxG.keys.justPressed.ESCAPE)
			{
				Global.clearScriptList();
				EditorTransition.transitionToGameplay(this);
			}

			if (FlxG.keys.justPressed.ONE) curType = NOTES;
			else if (FlxG.keys.justPressed.TWO) curType = VISUALS;
			else if (FlxG.keys.justPressed.THREE) curType = CHARACTERS;
			else if (FlxG.keys.justPressed.FOUR) curType = GIMMICKS;
			else if (FlxG.keys.justPressed.FIVE) curType = SOUNDS;

			if (FlxG.keys.justPressed.SIX) curPlacementMode = (curPlacementMode == PLACE) ? EDIT : PLACE;
		}

		// this should HOPEFULLY reduce update calls and draw calls :3
		// update: YEAHH IT DID nice.
		for (yeah in noteGroup.members)
		{
			if (Std.isOfType(yeah, Note))
			{
				final n = cast(yeah, Note);
				n.updateHandle();
				n.updateTypeMarker();
				n.visible = n.active = n.isOnScreen();
			}
			else
			{
				final spr = cast(yeah, MoonSprite);

				if (spr != null && spr.alive) spr.visible = spr.active = spr.isOnScreen();
			}
		}

		for (event in eventsGroup) if (Std.isOfType(event, EventSpr)) event.visible = event.isOnScreen() && cast(event, EventSpr).category == curType;
		else
			event.visible = event.isOnScreen() && cast(event, EventHold).category == curType;

		for (member in gridGroup.members)
		{
			if (Std.isOfType(member, FlxSprite) && !Std.isOfType(member, FlxSpriteGroup))
			{
				final spr:FlxSprite = cast member;
				if (spr != cursor && spr != strum && !noteGroup.members.contains(spr)) spr.visible = spr.isOnScreen();
			}
		}

		playback.update(elapsed);

		// update grid pos stuff
		conductor.time = playback.time;
		recalcChangeIndex();

		gridGroup.y = FlxMath.lerp(gridGroup.y, initialGridY - timeToY(conductor.time), elapsed * 28);

		// Upon "note hit"
		for (note in noteGroup)
		{
			if (Std.isOfType(note, Note))
			{
				// TODO: toggle for both theese
				final n = cast(note, Note);

				if (n.strID != 'h' && conductor.time >= n.time && playback.state == PLAY)
				{
					n.strID = 'h';
					strum.onHit(n);
					Paths.playSFX('toolkit/level-editor/hitsound-${n.lane.toLowerCase()}.wav', true);
				}

				if (n.strID == 'h' && conductor.time < n.time) n.strID = 'a';
			}
		}

		updateHoldSounds();
		if (playback.state == PLAY)
		{
			for (note in noteGroup)
			{
				if (Std.isOfType(note, Note))
				{
					final n:Note = cast note;
					if (n.duration > 0.0 && n.strID == 'h') if (conductor.time >= n.time && conductor.time < n.time + n.duration) strum.onHit(n);
				}
			}
		}

		if (draggingNote != null)
		{
			if (FlxG.mouse.pressed)
			{
				final newRefDur = Math.max(0.0, (snapTime(yToTime(FlxG.mouse.viewY - gridGroup.y - 18))) - draggingNote.time);
				final oldRefDur = draggingNote.duration; // remember before we change anything

				// relative delta so other selected notes keep their length difference
				final delta = newRefDur - dragOGlengths.get(draggingNote);
				for (t in dragOGlengths.keys())
				{
					final targetNew = Math.max(0.0, dragOGlengths.get(t) + delta);
					resizeNoteSustain(t, targetNew);
				}

				// plays the SFX thingy ONLY when the note ACTUALLY resized
				if (Math.abs(newRefDur - oldRefDur) > 0.001)
				{
					final isIncrease = newRefDur > oldRefDur;
					sfx(isIncrease ? 'sustainIncrease' : 'sustainDecrease', false, true);
				}
			}
			else
			{
				// Mouse was released — commit duration changes to history
				for (t in dragOGlengths.keys()) History.pushNoteDuration({
					time: t.time,
					data: t.direction,
					lane: t.lane,
					type: t.type,
					duration: t.duration,
					values: null
				}, dragOGlengths.get(t), t.duration);

				draggingNote = null;
				if (dragOGlengths != null) dragOGlengths.clear();
			}
		}
		else if (!haxeUIFocused)
		{
			if (selectedNotes.length > 0)
			{
				final delta = getSnapStepTime();
				if (FlxG.keys.justPressed.E)
				{
					for (t in selectedNotes)
					{
						final oldDur = t.duration;
						resizeNoteSustain(t, t.duration + delta);
						History.pushNoteDuration({
							time: t.time,
							data: t.direction,
							lane: t.lane,
							type: t.type,
							duration: t.duration,
							values: null
						}, oldDur, t.duration);
					}
					sfx('sustainIncrease', false, true);
				}
				else if (FlxG.keys.justPressed.Q)
				{
					for (t in selectedNotes)
					{
						final oldDur = t.duration;
						resizeNoteSustain(t, Math.max(0.0, t.duration - delta));
						History.pushNoteDuration({
							time: t.time,
							data: t.direction,
							lane: t.lane,
							type: t.type,
							duration: t.duration,
							values: null
						}, oldDur, t.duration);
					}
					sfx('sustainDecrease', false, true);
				}
			}
		}
	}

	private function updateHoldSounds():Void
	{
		if (playback.state != PLAY)
		{
			if (sustainLoopP1 != null && sustainLoopP1.playing) sustainLoopOpp.stop();
			if (sustainLoopP1 != null && sustainLoopP1.playing) sustainLoopOpp.stop();
			return;
		}

		// which sides currently have an active hold
		var activeOpp = false;
		var activeP1 = false;

		for (note in noteGroup)
		{
			if (Std.isOfType(note, Note))
			{
				final n:Note = cast note;
				if (n.duration > 0.0)
				{
					final endTime = n.time + n.duration;
					if (conductor.time >= n.time && conductor.time < endTime)
					{
						if (n.lane == 'opponent') activeOpp = true;
						else if (n.lane == "p1") activeP1 = true;
					}
				}
			}
		}

		// plays hold sfx for the opp side.
		final wasOpp = sustainLoopOpp != null && sustainLoopOpp.playing;
		if (activeOpp && !wasOpp)
		{
			sustainLoopOpp.volume = MoonSettings.callSetting('SFX Volume') / 100;
			sustainLoopOpp.play();
		}
		else if (!activeOpp && wasOpp)
		{
			sustainLoopOpp.stop();
			Paths.playSFX('toolkit/level-editor/sustainOpponent-release.wav', true);
		}

		// plays hold sfx for the player
		final wasP1 = sustainLoopP1 != null && sustainLoopP1.playing;
		if (activeP1 && !wasP1)
		{
			sustainLoopP1.volume = MoonSettings.callSetting('SFX Volume') / 100;
			sustainLoopP1.play();
		}
		else if (!activeP1 && wasP1)
		{
			sustainLoopP1.stop();
			Paths.playSFX('toolkit/level-editor/sustainP1-release.wav', true);
		}
	}

	// this snaps the square cursor thing

	private function updateCursor():Void
	{
		if (libFocus || !allowEditing) return;
		final TOTAL_LANES:Int = NUM_LANES + 1;
		final relX = FlxG.mouse.viewX - gridGroup.x;
		final relY = FlxG.mouse.viewY - gridGroup.y - 18;

		// dev notes c:
		// HAND shows the thingy when you're dragging smth
		// IBEAM is when typing
		// and BUTTON is clickable!

		if ((relX < 0 || relX >= LANE_WIDTH * TOTAL_LANES || relY < 0) && draggingNote == null)
		{
			cursor.visible = false;
			// Mouse.cursor = MouseCursor.ARROW;
			return;
		}

		cursor.visible = true;

		// snap to the lane
		final laneNum:Int = Math.floor(relX / LANE_WIDTH);
		cursor.x = gridGroup.x + laneNum * LANE_WIDTH;

		// and snap to the time
		final unsnappedTime:Float = yToTime(relY);
		final snappedTime = snapTime(unsnappedTime);
		cursor.y = gridGroup.y + timeToY(snappedTime);

		// check if we are hovering the square
		for (yeah in noteGroup.members)
		{
			if (Std.isOfType(yeah, Note))
			{
				final n:Note = cast yeah;
				if (n.sustainHandle != null && n.sustainHandle.visible && FlxG.mouse.overlaps(n.sustainHandle))
				{
					// if(draggingNote == null) Mouse.cursor = MouseCursor.BUTTON;
					if (FlxG.mouse.justPressed && curPlacementMode == PLACE && curType == NOTES)
					{
						final shouldDrag = (selectedNotes.length == 0 || selectedNotes.indexOf(n) != -1);
						if (shouldDrag)
						{
							draggingNote = n;
							// Mouse.cursor = MouseCursor.HAND;

							if (dragOGlengths == null) dragOGlengths = new Map();
							dragOGlengths.clear();
							final targets = selectedNotes.length > 0 ? selectedNotes : [n];
							for (t in targets) dragOGlengths.set(t, t.duration);
						}
					}
					break;
				}
			}
		}

		/// --- ON CLICK STUFFIES! --- ///
		// TODO: uhm, fix this?
		// "overlaps(noteGroup)" kinda sucks.

		// NOTE: THANKS TO GOATMYRIA (Luna) WE HAVE A DIFFERENT MODE FOR SELECTION
		// WOHOOOOO NO MORE THINKING ABOUT OVERLAPPING SHIT!!!

		// Anyways, place stuff!
		if (FlxG.mouse.justPressed && curPlacementMode == PLACE && draggingNote == null)
		{
			// TODO: when not on placement mode, only on editing mode?
			// uhhh
			if (FlxG.keys.pressed.SHIFT && curType == NOTES)
			{
				final noteAt = getNoteAtCursor(snappedTime, laneNum);
				if (noteAt != null)
				{
					if (selectedNotes.indexOf(noteAt) == -1)
					{
						selectedNotes.push(noteAt);
						noteAt.brightness = 0.4;
						refreshHandleVis();
						sfx('noteSelect', false, true);
					}
				}
				return;
			}

			deselectAll();

			if (laneNum < NUM_LANES)
			{
				switch (curType)
				{
					case NOTES:
						final noteData = laneNum % 4;
						final noteLane = (laneNum < 4) ? "opponent" : "p1";

						var noteExists = false;
						for (existingNote in chart.content.notes)
						{
							if (existingNote.time == snappedTime && existingNote.data == noteData && existingNote.lane == noteLane)
							{
								noteExists = true;
								break;
							}
						}

						if (!noteExists)
						{
							final selectedType = (library.selectedInfo != null) ? library.selectedInfo.name : 'default';
							final n = {
								time: snappedTime,
								data: noteData,
								lane: noteLane,
								type: selectedType,
								duration: 0.0,
								values: (library.form != null) ? NoteTypeRegistry.processNoteValues(selectedType, library.form.getValues()) : null
							};
							createNote(n);
							chart.content.notes.push(n);
							History.pushNotePlace(n);
							sfx('place-${FlxG.random.int(1, 6)}');
						}

					// huh... I think the switch isn't very needed here lmao
					case VISUALS, CHARACTERS, GIMMICKS, SOUNDS:
						// shit
						final ev:EventStruct = {
							tag: library.selectedInfo.name,
							values: EventRegistry.processEventValues(library.selectedInfo.name, library.form.getValues()),
							time: snappedTime,
							lane: laneNum
						};

						chart.events.push(ev);
						chart.events.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
						createEvent(ev);
						History.pushEventPlace(ev);
						sfx('placeEvent-${FlxG.random.int(1, 2)}');

						if (ev.tag == 'Change Playback Settings')
						{
							changes.push({
								time: ev.time,
								bpm: ev.values.bpm,
								numerator: ev.values.timeSignature[0],
								denominator: ev.values.timeSignature[1]
							});
						}
						changes.sort((a, b) -> Std.int(a.time - b.time));
						recalcChangeIndex();
						// trace('[EDITOR] Placed "$tag" at ${conductor.time}ms (lane $lane)', "DEBUG");
				}
			}
			else
			{
				if (!FlxG.mouse.overlaps(miscGroup))
				{
					var bm = new Bookmark(laneNum * LANE_WIDTH, timeToY(snappedTime), LANE_HEIGHT);
					miscGroup.add(bm);
					scrollbar.addBookmark(snappedTime, bm.col);
					bm.active = false;

					if (chart.content.bookmarks == null) chart.content.bookmarks = [];
					chart.content.bookmarks.push({
						text: bm.text,
						time: snappedTime
					});
				}
			}
		}
		else if (FlxG.mouse.justPressed && curPlacementMode == EDIT && draggingNote == null)
		{
			final shiftHeld = FlxG.keys.pressed.SHIFT;

			if (curType == NOTES)
			{
				final hit = getNoteAtCursor(snappedTime, laneNum);

				if (hit != null)
				{
					if (shiftHeld)
					{
						if (editSelectedNotes.indexOf(hit) == -1)
						{
							editSelectedNotes.push(hit);
							hit.brightness = 0.4;
						}
						else
						{
							editSelectedNotes.remove(hit);
							hit.brightness = 0;
						}
					}
					else
					{
						deselectEditTargets();
						editSelectedNotes.push(hit);
						hit.brightness = 0.4;
					}
				}
				else if (!shiftHeld) deselectEditTargets();

				refreshEditTarget();
			}
			else
			{
				var hitSpr:EventSpr = null;
				for (member in eventsGroup.members)
				{
					if (Std.isOfType(member, EventSpr) && cast(member, EventSpr).category == curType)
					{
						final spr:EventSpr = cast member;
						if (FlxG.mouse.overlaps(spr))
						{
							hitSpr = spr;
							break;
						}
					}
				}

				if (hitSpr != null)
				{
					if (shiftHeld)
					{
						if (editSelectedEvents.indexOf(hitSpr) == -1)
						{
							editSelectedEvents.push(hitSpr);
							hitSpr.brightness = 0.4;
						}
						else
						{
							editSelectedEvents.remove(hitSpr);
							hitSpr.brightness = 0;
						}
					}
					else
					{
						deselectEditTargets();
						editSelectedEvents.push(hitSpr);
						hitSpr.brightness = 0.4;
					}
				}
				else if (!shiftHeld) deselectEditTargets();

				refreshEditTarget();
			}
		}

		// Delete stuff!!!
		// or remove, eh, whatever!
		if (FlxG.mouse.pressedRight && draggingNote == null)
		{
			deselectAll();

			if (curType == NOTES)
			{
				final hit = getNoteAtCursor(snappedTime, laneNum);
				if (hit != null)
				{
					final struct = {
						time: hit.time,
						data: hit.direction,
						lane: hit.lane,
						type: hit.type,
						duration: hit.duration,
						values: null
					};

					History.pushNoteDelete(struct);

					chart.content.notes = chart.content.notes.filter(
						n -> !(Math.abs(n.time - hit.time) < 0.01 && n.data == hit.direction && n.lane == hit.lane)
					);

					removeNoteSpr(struct);
					sfx('delete', false, true);
					if (editSelectedNotes.remove(hit)) refreshEditTarget();
				}
			}
			else
			{
				var toRemoveSpr:EventSpr = null;

				for (member in eventsGroup.members)
				{
					if (Std.isOfType(member, EventSpr) && cast(member, EventSpr).category == curType)
					{
						final spr = cast(member, EventSpr);
						if (FlxG.mouse.overlaps(spr))
						{
							toRemoveSpr = spr;
							break;
						}
					}
				}

				if (toRemoveSpr != null)
				{
					final evTime = yToTime(toRemoveSpr.y - gridGroup.y);

					var deletedEvStruct:EventStruct = null;

					for (e in chart.events) if (e.tag == toRemoveSpr.event && Math.abs(e.time - evTime) < 50)
					{
						deletedEvStruct = e;
						break;
					}

					if (deletedEvStruct != null)
					{
						History.pushEventDelete(deletedEvStruct);
						removeEventSpr(deletedEvStruct);

						if (deletedEvStruct.tag == 'Change Playback Settings')
						{
							changes.remove({
								time: deletedEvStruct.time,
								bpm: deletedEvStruct.values.bpm,
								numerator: deletedEvStruct.values.timeSignature[0],
								denominator: deletedEvStruct.values.timeSignature[1]
							});
						}
						changes.sort((a, b) -> Std.int(a.time - b.time));
						recalcChangeIndex();
					}

					chart.events = chart.events.filter(e -> !(e.tag == toRemoveSpr.event && Math.abs(e.time - evTime) < 50));
					sfx('delete', false, true);
					if (editSelectedEvents.remove(toRemoveSpr)) refreshEditTarget();
				}
			}
		}
	}

	public function createNote(n:NoteStruct)
	{
		var note = new Note(n.data, n.time, n.type, "mooncharter", n.duration, conductor);
		note.state = CHART_EDITOR;
		note.values = n.values;
		note.active = false;
		note.setGraphicSize(LANE_WIDTH, LANE_HEIGHT);
		note.updateHitbox();
		note.lane = n.lane;

		final laneIndex = (n.lane == "p1") ? 4 : 0;
		note.x = (laneIndex + n.data) * LANE_WIDTH;
		note.y = timeToY(n.time);
		note.x += (LANE_WIDTH - note.width) / 2;

		noteGroup.add(note);
		note.makeHandle();
		noteGroup.add(note.sustainHandle);

		if (note.type != null)
		{
			note.makeTypeMarker();
			noteGroup.add(note.typeMarker);
		}

		updateSustainVis(note, n.duration);

		note.scale.set(0.5, 0.5);
		FlxTween.tween(note, {
			"scale.x": 1,
			"scale.y": 1
		}, 0.28, {
			ease: FlxEase.backOut
		});

		EditorSync.onNoteAdded(n);
	}

	public function createEvent(ev:EventStruct)
	{
		var category:GridType = VISUALS;
		for (cat => sht in loadedEvents) for (evt in sht) if (evt.name == ev.tag) category = cat;

		var spr = new EventSpr(ev.tag, category);
		spr.setGraphicSize(LANE_WIDTH, LANE_HEIGHT);
		spr.updateHitbox();
		spr.x = ev.lane * LANE_WIDTH;
		spr.y = timeToY(ev.time);

		spr.x += (LANE_WIDTH - spr.width) / 2;
		spr.active = false;
		if (ev.values != null && ev.values.duration != null) spr.duration = stepsToHeight(ev.values.duration);

		if (spr.duration > 0) eventsGroup.add(new EventHold(spr));
		eventsGroup.add(spr);
		EditorSync.onEventAdded(ev);
	}

	public function removeNoteSpr(n:moon.backend.data.Chart.NoteStruct):Void
	{
		var toDestroy:Note = null;
		for (member in noteGroup.members)
		{
			if (Std.isOfType(member, Note))
			{
				final existing:Note = cast member;
				if (Math.abs(existing.time - n.time) < 0.01 && existing.direction == n.data && existing.lane == n.lane)
				{
					toDestroy = existing;
					break;
				}
			}
		}

		if (toDestroy == null) return;

		if (toDestroy.child != null)
		{
			noteGroup.remove(toDestroy.child, true);
			toDestroy.child.destroy();
			toDestroy.child = null;
		}

		if (toDestroy.sustainHandle != null) noteGroup.remove(toDestroy.sustainHandle, true);

		if (toDestroy.typeMarker != null) noteGroup.remove(toDestroy.typeMarker);

		FlxTween.globalManager.cancelTweensOf(toDestroy);
		noteGroup.remove(toDestroy, true);
		toDestroy.destroy();
	}

	public function removeEventSpr(e:EventStruct):Void
	{
		var toRemoveSpr:EventSpr = null;
		for (member in eventsGroup.members)
		{
			if (Std.isOfType(member, EventSpr))
			{
				final spr:EventSpr = cast member;
				if (spr.event == e.tag && Math.abs(yToTime(spr.y - gridGroup.y) - e.time) < 50)
				{
					toRemoveSpr = spr;
					break;
				}
			}
		}

		if (toRemoveSpr == null) return;

		var toRemoveHold:EventHold = null;
		for (member in eventsGroup.members) if (Std.isOfType(member, EventHold) && cast(member, EventHold).parent == toRemoveSpr) toRemoveHold = cast member;

		if (toRemoveHold != null)
		{
			eventsGroup.remove(toRemoveHold, true);
			toRemoveHold.destroy();
		}

		eventsGroup.remove(toRemoveSpr, true);
		toRemoveSpr.destroy();
	}

	public function updateNoteDurSpr(n:NoteStruct, newDur:Float):Void
	{
		for (member in noteGroup.members)
		{
			if (Std.isOfType(member, Note))
			{
				final existing:Note = cast member;
				if (Math.abs(existing.time - n.time) < 0.01 && existing.direction == n.data && existing.lane == n.lane)
				{
					updateSustainVis(existing, newDur);
					updateNoteDurationData(existing, newDur);
					return;
				}
			}
		}
	}

	private function recalcChangeIndex(reset:Bool = false):Void
	{
		changeIndex = 1;
		if (reset) conductor.reset();
		conductor.changeBpmAt(0, changes[0].bpm, changes[0].numerator, changes[0].denominator);
		while (changeIndex < changes.length && conductor.time >= changes[changeIndex].time)
		{
			final ch = changes[changeIndex];
			conductor.changeBpmAt(ch.time, ch.bpm, ch.numerator, ch.denominator);
			changeIndex++;
		}
	}

	function timeToY(time:Float):Float
	{
		if (time <= 0) return 0;
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextStart:Float = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
			if (time < nextStart) return seg.startY + ((time - seg.startTime) / seg.stepCrochet * LANE_HEIGHT);
		}
		final last = segments[segments.length - 1];
		return last.startY + ((time - last.startTime) / last.stepCrochet * LANE_HEIGHT);
	}

	function yToTime(y:Float):Float
	{
		if (y <= 0) return 0;
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextY:Float = (i < segments.length - 1) ? segments[i + 1].startY : Math.POSITIVE_INFINITY;
			if (y < nextY) return seg.startTime + ((y - seg.startY) / LANE_HEIGHT * seg.stepCrochet);
		}
		final last = segments[segments.length - 1];
		return last.startTime + ((y - last.startY) / LANE_HEIGHT * last.stepCrochet);
	}

	function getTimeSeg(time:Float):
		{startTime:Float, startY:Float, stepCrochet:Float}
	{
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextStart:Float = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
			if (time < nextStart) return seg;
		}
		return segments[segments.length - 1];
	}

	private function snapTime(rawTime:Float):Float
	{
		if (curSnap == 0) return rawTime;
		final seg = getTimeSeg(rawTime);
		final lc = seg.stepCrochet * 4;
		return seg.startTime + (Math.round(((rawTime - seg.startTime) / lc) * curSnap) / curSnap) * lc;
	}

	function getCurSection():Int
	{
		var sec = 0;

		for (seg in segments) sec += Std.int((conductor.time - seg.startTime) / seg.stepCrochet / Std.int(conductor.numerator * conductor.denominator));

		return sec;
	}

	function getSectionNotes(sectionIndex:Int):Array<NoteStruct>
	{
		final stepsPerSection = Std.int(conductor.numerator * conductor.denominator);
		return chart.content.notes.filter(n ->
		{
			var noteSection = 0;
			for (i in 0...segments.length)
			{
				final seg = segments[i];
				final nextStart = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
				if (n.time >= seg.startTime && n.time < nextStart)
				{
					noteSection += Std.int((n.time - seg.startTime) / seg.stepCrochet / stepsPerSection);
					break;
				}
				noteSection += Std.int((nextStart - seg.startTime) / seg.stepCrochet / stepsPerSection);
			}
			return noteSection == sectionIndex;
		});
	}

	function getSectionStartTime(sectionIndex:Int):Float
	{
		final stepsPerSection = Std.int(conductor.numerator * conductor.denominator);
		var counted = 0;
		for (i in 0...segments.length)
		{
			final seg = segments[i];
			final nextStart = (i < segments.length - 1) ? segments[i + 1].startTime : playback.fullLength;
			final secsInSeg = Std.int((nextStart - seg.startTime) / seg.stepCrochet / stepsPerSection);
			if (counted + secsInSeg > sectionIndex) return seg.startTime + (sectionIndex - counted) * stepsPerSection * seg.stepCrochet;
			counted += secsInSeg;
		}
		return playback.fullLength;
	}

	function swapCurrentSection():Void
	{
		for (n in getSectionNotes(getCurSection()))
		{
			// it's so easy!!
			removeNoteSpr(n);
			n.lane = (n.lane == "p1") ? "opponent" : "p1";
			createNote(n);
		}
		chart.content.notes.sort((a, b) -> a.time < b.time ? -1 : a.time > b.time ? 1 : 0);
	}

	function durationToHeight(startTime:Float, duration:Float):Float return timeToY(startTime + duration) - timeToY(startTime);

	function stepsToHeight(steps:Float):Float return steps * LANE_HEIGHT;

	private function getHoveredNote():Note
	{
		if (libFocus) return null;
		final relX = FlxG.mouse.viewX - gridGroup.x;
		final relY = FlxG.mouse.viewY - gridGroup.y - 18;
		if (relX < 0 || relX >= LANE_WIDTH * (NUM_LANES + 1) || relY < 0) return null;

		final laneNum:Int = Math.floor(relX / LANE_WIDTH);
		if (laneNum >= NUM_LANES) return null;

		final mouseTime:Float = yToTime(relY);
		var closest:Note = null;
		var minDist:Float = Math.POSITIVE_INFINITY;

		for (m in noteGroup.members)
		{
			if (Std.isOfType(m, Note))
			{
				final n:Note = cast m;
				final noteLane = (laneNum < 4) ? "opponent" : "p1";
				if (n.lane == noteLane && n.direction == (laneNum % 4))
				{
					final dist = Math.abs(n.time - mouseTime);
					if (dist < minDist && dist < (conductor.stepCrochet * 2))
					{
						minDist = dist;
						closest = n;
					}
				}
			}
		}
		return closest;
	}

	private function getNoteAtCursor(snappedTime:Float, laneNum:Int):Note
	{
		if (laneNum >= NUM_LANES) return null;
		final targetLane = (laneNum < 4) ? "opponent" : "p1";
		final targetData = laneNum % 4;

		for (m in noteGroup.members)
		{
			if (Std.isOfType(m, Note))
			{
				final n:Note = cast m;
				if (n.lane == targetLane && n.direction == targetData && Math.abs(n.time - snappedTime) < 0.01) return n;
			}
		}
		return null;
	}

	private function deselectAll():Void
	{
		for (n in selectedNotes) if (n != null) n.brightness = 0;
		selectedNotes = [];
		refreshHandleVis();
	}

	public function deselectEditTargets():Void
	{
		for (n in editSelectedNotes) if (n != null) n.brightness = 0;
		editSelectedNotes = [];
		for (e in editSelectedEvents) if (e != null) e.brightness = 0;
		editSelectedEvents = [];

		editNote = null;
		editNoteStruct = null;
		editEvent = null;
		editEventStruct = null;
		_lastEditSnapshot = null;
	}

	function refreshEditTarget():Void
	{
		final total = editSelectedNotes.length + editSelectedEvents.length;

		if (total != 1)
		{
			editNote = null;
			editNoteStruct = null;
			editEvent = null;
			editEventStruct = null;
			_lastEditSnapshot = null;

			if (library.editing || library.selectedInfo != null)
			{
				library.editing = false;
				library.editingValues = null;
				library.selectedInfo = null;
				library.refreshLibrary();
			}
			return;
		}

		if (editSelectedNotes.length == 1)
		{
			final n = editSelectedNotes[0];
			editNote = n;
			editEvent = null;
			editEventStruct = null;
			_lastEditSnapshot = null;

			editNoteStruct = null;
			for (existing in chart.content.notes) if (Math.abs(existing.time - n.time) < 0.01 && existing.data == n.direction && existing.lane == n.lane)
			{
				editNoteStruct = existing;
				break;
			}

			library.editingValues = n.values ?? {};
			library.selectedInfo = _findEventInfo(NOTES, n.type ?? 'default');
			library.editing = true;
			library.refreshLibrary();
		}
		else
		{
			final spr = editSelectedEvents[0];
			editEvent = spr;
			editNote = null;
			editNoteStruct = null;
			_lastEditSnapshot = null;

			final evTime = yToTime(spr.y - gridGroup.y);
			editEventStruct = null;
			for (e in chart.events) if (e.tag == spr.event && Math.abs(e.time - evTime) < 50)
			{
				editEventStruct = e;
				break;
			}

			library.editingValues = (editEventStruct != null) ? editEventStruct.values : {};
			library.selectedInfo = _findEventInfo(spr.category, spr.event);
			library.editing = true;
			library.refreshLibrary();
		}
	}

	function _findEventInfo(category:GridType, name:String):Null<EventInfo>
	{
		for (info in loadedEvents.get(category)) if (info.name == name) return info;

		// "default" (and any other untracked) note types aren't in the catalog,
		// so without a stub here the Library has nothing to switch to and just
		// falls back to the palette grid instead of opening the edit view.
		if (category == NOTES) return {
			name: name,
			description: 'This note type has no editable fields.',
			category: NOTES
		};

		return null;
	}

	function updateEditingValues():Void
	{
		if (library.form == null || library.selectedInfo == null) return;
		if (editNoteStruct == null && editEventStruct == null) return;

		final raw = library.form.getValues();
		final snapshot = haxe.Json.stringify(raw);
		if (snapshot == _lastEditSnapshot) return;
		_lastEditSnapshot = snapshot;

		if (editNoteStruct != null)
		{
			final processed = NoteTypeRegistry.processNoteValues(library.selectedInfo.name, raw);
			editNoteStruct.values = processed;
			if (editNote != null) editNote.values = processed;
		}
		else if (editEventStruct != null)
		{
			final processed = EventRegistry.processEventValues(library.selectedInfo.name, raw);
			editEventStruct.values = processed;

			if (editEvent != null && processed != null && Reflect.hasField(processed, 'duration'))
			{
				final newDurHeight = stepsToHeight(Reflect.field(processed, 'duration'));
				if (Math.abs(editEvent.duration - newDurHeight) > 0.01)
				{
					var oldHold:EventHold = null;
					for (member in eventsGroup.members) if (
						Std.isOfType(member, EventHold)
						&& cast(member, EventHold).parent == editEvent
					) oldHold = cast member;
					if (oldHold != null)
					{
						eventsGroup.remove(oldHold, true);
						oldHold.destroy();
					}

					editEvent.duration = newDurHeight;
					if (editEvent.duration > 0) eventsGroup.add(new EventHold(editEvent));
				}
			}
		}
	}

	private function refreshHandleVis():Void
	{
		final hasSel = selectedNotes.length > 0;
		for (yeah in noteGroup.members)
		{
			if (Std.isOfType(yeah, Note))
			{
				final n:Note = cast yeah;
				if (n.sustainHandle != null) n.sustainHandle.visible = !hasSel || selectedNotes.indexOf(n) != -1;
			}
		}
	}

	private function getSnapStepTime():Float
	{
		if (curSnap == 0) return conductor.stepCrochet;
		final lc = conductor.stepCrochet * 4;
		return lc / curSnap;
	}

	private function updateNoteDurationData(n:Note, newDur:Float):Void
	{
		for (existing in chart.content.notes)
		{
			if (Math.abs(existing.time - n.time) < 0.01 && existing.data == n.direction && existing.lane == n.lane)
			{
				existing.duration = newDur;
				return;
			}
		}
	}

	private function updateSustainVis(n:Note, newDur:Float):Void
	{
		n.duration = newDur;

		if (newDur > 0)
		{
			if (n.child == null)
			{
				final sus = new NoteSustain(n);
				noteGroup.add(sus);
				n.child = sus;
			}
			FlxTween.globalManager.cancelTweensOf(n.child);
			FlxTween.tween(n.child, {
				editorHeight: durationToHeight(n.time, newDur)
			}, 0.3, {
				ease: FlxEase.expoOut
			});
		}
		else if (n.child != null)
		{
			noteGroup.remove(n.child, true);
			n.child.destroy();
			n.child = null;
		}
	}

	private function resizeNoteSustain(n:Note, newDur:Float):Void
	{
		if (Math.abs(newDur - n.duration) < 0.001) return;
		updateNoteDurationData(n, newDur);
		updateSustainVis(n, newDur);
	}

	public function sfx(p:String, general:Bool = false, once = false)
	{
		if (playback.state != PLAY) Paths.playSFX((!general) ? 'toolkit/level-editor/$p.wav' : 'toolkit/general/$p.wav', once);
	}

	function updateNotesFilter()
	{
		for (member in noteGroup.members)
		{
			if (member != null)
			{
				member.shader = (curType != NOTES) ? grayscale : null;
				member.alpha = (curType != NOTES) ? 0.20 : ((Std.isOfType(member, Note) || Std.isOfType(member, NoteSustain)) ? 1 : 0.6);
			}
		}
	}

	function set_curPlacementMode(mode:PlacementMode):PlacementMode
	{
		if (mode != curPlacementMode)
		{
			deselectEditTargets();
			if (library != null)
			{
				library.editing = false;
				library.editingValues = null;
				library.selectedInfo = null;
				library.refreshLibrary();
			}
		}
		curPlacementMode = mode;
		return mode;
	}

	function set_curType(curType:GridType):GridType
	{
		this.curType = curType;
		final typeStr:String = '$curType';

		updateNotesFilter();

		for (type => button in typeButtons) button.playAnim(type == curType ? 'click' : 'idle', true);

		deselectEditTargets();
		library.editing = false;
		library.editingValues = null;
		library.selectedInfo = null;
		library.refreshLibrary();
		sfx('${typeStr.toLowerCase()}Tab');

		return curType;
	}

	// -- External shit

	public function saveLevel()
	{
		// TODO: support for the difficulty system
		File.saveContent(Paths.getPath('songs/$song/$mix/chart-$diff.json'), haxe.Json.stringify(chart.content, null, "\t"));
		File.saveContent(Paths.getPath('songs/$song/$mix/events.json'), haxe.Json.stringify(chart.events, null, "\t"));

		// trace('shit got saved ayooooo');

		sfx('save${FlxG.random.bool(0.5) ? "-secret" : ""}', false, true);
	}
}
