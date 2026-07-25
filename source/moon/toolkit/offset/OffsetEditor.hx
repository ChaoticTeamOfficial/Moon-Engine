package moon.toolkit.offset;

import haxe.Json;
import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup;
import openfl.geom.ColorTransform;
import moon.toolkit.ui.*;
import moon.game.obj.*;
import moon.game.*;
import moon.game.obj.notes.*;
import moon.backend.data.Chart.NoteStruct;
import moon.menus.MainMenu;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

/**
 * The offset editor! Lets you view and adjust animation offsets,
 * character properties, and preview poses using a ghost sprite.
 * TODO: fix the ghost offsets and update everything correctly when is a FlxAnimate sprite???
 * TODO 2: lower drawquads somehow lololol
 */
class OffsetEditor extends FlxState
{
	public var characterName:String = 'bf';
	public var char:Character;
	public var ghost:MoonSprite;
	public var ghostEnabled:Bool = false;

	private var camGame:MoonCamera = new MoonCamera();
	private var camUI:MoonCamera = new MoonCamera();
	private var camDragging:Bool = false;
	private var lastMouse:FlxPoint = FlxPoint.get();
	private var selectedAnim:String = '';
	private var ghostAnimName:String = '';
	private var suppressCallbacks:Bool = false;
	private var animList:ListView;
	private var animOffsetX:NumberStepper;
	private var animOffsetY:NumberStepper;
	private var animPrefixField:TextField;
	private var animFpsField:NumberStepper;
	private var animLoopedToggle:CheckBox;
	private var animFinishField:TextField;
	private var animIndicesField:TextField;
	private var ghostToggle:CheckBox;
	private var ghostAnimDrop:DropDown;
	private var ghostFrameField:NumberStepper;
	private var scaleField:NumberStepper;
	private var antialiasingToggle:CheckBox;
	private var flipXToggle:CheckBox;
	private var camOffsetXField:NumberStepper;
	private var camOffsetYField:NumberStepper;
	private var extraOffsetXField:NumberStepper;
	private var extraOffsetYField:NumberStepper;
	private var hbColorRField:NumberStepper;
	private var hbColorGField:NumberStepper;
	private var hbColorBField:NumberStepper;
	private var danceFreqField:NumberStepper;
	private var holdDurField:NumberStepper;
	private var gameoverColorField:TextField;
	private var overrideAnimsField:TextField;

	static inline final PANEL_W:Int = 280;
	static inline final PANEL_PAD:Int = 10;
	static inline final BTN_H:Int = 34;
	static inline final STYLE_INPUT = 'background-color: #101020; color: white; border: 1px solid #333355; border-radius: 4px; font-size: 12px;';
	static inline final STYLE_PANEL = 'background-color: #101020; border: none; padding: 4px; spacing: 8px;';

	public function new(?character:String = 'darnell')
	{
		super();
		this.characterName = character;
	}

	override public function create():Void
	{
		super.create();

		camGame.bgColor = 0xFF1E1D2E;
		camUI.bgColor = 0x00000000;
		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camUI, false);
		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;

		var grid = new MoonSprite().makeGraphic(FlxG.width * 4, FlxG.height * 4, FlxColor.TRANSPARENT);
		final gc:FlxColor = 0xFF7B799E;
		final gs:Int = 64;
		for (gx in 0...Std.int(grid.width / gs) + 1) grid.pixels.fillRect(new openfl.geom.Rectangle(gx * gs, 0, 1, grid.height), gc);
		for (gy in 0...Std.int(grid.height / gs) + 1) grid.pixels.fillRect(new openfl.geom.Rectangle(0, gy * gs, grid.width, 1), gc);
		grid.dirty = true;
		grid.active = false;
		grid.x = -FlxG.width;
		grid.y = -FlxG.height;
		grid.alpha = 0.35;
		add(grid);

		// "crosshair" sorta
		// still gona mess around w it
		var ch = new MoonSprite().makeGraphic(2, 40, 0x44FFFFFF);
		var cv = new MoonSprite().makeGraphic(40, 2, 0x44FFFFFF);
		ch.screenCenter();
		ch.y -= 20;

		cv.screenCenter();
		cv.x -= 20;
		ch.active = cv.active = false;
		add(ch);
		add(cv);

		ghost = new MoonSprite();
		ghost.visible = false;
		ghost.alpha = 0.35;
		add(ghost);

		char = new Character(0, 0, characterName, null);
		char.screenCenter();
		add(char);

		_buildLeftPanel();
		_buildRightPanel();
		_populateAnimList();
		_syncDataPanel();

		var hint = new FlxText(0, FlxG.height - 24, FlxG.width, '[G] Ghost  [CTRL+S] Save  [ESC] Back  [RMB] Pan');
		hint.camera = camUI;
		hint.color = 0xAABBBBBB;
		hint.active = false;
		hint.antialiasing = false;
		hint.setFormat(Paths.font('vcr.ttf'), 24, CENTER);
		add(hint);
		hint.screenCenter(X);

		camUI.flash(0xFF1E1D2E, 0.35);
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		final uiFocused = haxe.ui.focus.FocusManager.instance.focus != null;

		if (FlxG.mouse.pressedRight)
		{
			if (!camDragging)
			{
				camDragging = true;
				lastMouse.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
			}
			else
			{
				camGame.scroll.x -= FlxG.mouse.viewX - lastMouse.x;
				camGame.scroll.y -= FlxG.mouse.viewY - lastMouse.y;
				lastMouse.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
			}
		}
		else
			camDragging = false;

		if (!uiFocused)
		{
			if (FlxG.keys.justPressed.SPACE && selectedAnim != '') char.playAnim(selectedAnim, true);

			if (FlxG.keys.justPressed.G) _toggleGhost(!ghostEnabled);

			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) _save();

			if (FlxG.keys.justPressed.ESCAPE) _exit();

			if (selectedAnim != '')
			{
				final step:Float = FlxG.keys.pressed.SHIFT ? 10.0 : 1.0;
				var dx:Float = 0;
				var dy:Float = 0;
				if (FlxG.keys.justPressed.LEFT) dx = step;
				if (FlxG.keys.justPressed.RIGHT) dx = -step;
				if (FlxG.keys.justPressed.UP) dy = step;
				if (FlxG.keys.justPressed.DOWN) dy = -step;
				if (dx != 0 || dy != 0) _nudgeOffset(dx, dy);
			}
		}

		if (ghost.visible) ghost.setPosition(char.x, char.y);
		if (FlxG.keys.justPressed.BACKSPACE) FlxG.switchState(() -> new MainMenu());
	}

	private function _buildLeftPanel():Void
	{
		final px:Float = 0;
		final py:Float = 0;

		var bg = new MoonSprite().makeGraphic(PANEL_W, FlxG.height, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, PANEL_W, FlxG.height, 0, 0, 0xD2101020);
		bg.active = false;
		bg.camera = camGame;
		bg.scrollFactor.set(0, 0);
		add(bg);

		_uiText(px + PANEL_PAD, py + 10, PANEL_W, 'OFFSET EDITOR', 28, camUI);
		_uiText(px + PANEL_PAD, py + 36, PANEL_W, characterName, 16, camUI, 0xFFAAAAAA);
		_uiHRule(px + PANEL_PAD, py + 54, camUI);

		var scroll = new ScrollView();
		scroll.left = px;
		scroll.top = py + 60;
		scroll.width = PANEL_W;
		scroll.height = FlxG.height - 60 - BTN_H * 2 - PANEL_PAD * 3;
		scroll.styleString = 'background-color: #101020; border: none; padding: 0;';

		var vbox = new VBox();
		vbox.width = PANEL_W - PANEL_PAD * 2;
		vbox.left = PANEL_PAD;
		vbox.styleString = STYLE_PANEL;

		vbox.addComponent(_sectionLabel('ANIMATIONS'));

		animList = new ListView();
		animList.width = vbox.width;
		animList.height = 160;
		animList.styleString = '$STYLE_INPUT border-radius: 4px;';
		animList.onChange = _ ->
		{
			if (!suppressCallbacks) _onAnimSelected();
		};
		vbox.addComponent(animList);

		vbox.addComponent(_sectionLabel('OFFSET X / Y'));

		var offsetRow = new HBox();
		offsetRow.width = vbox.width;
		offsetRow.styleString = 'spacing: 6px;';
		animOffsetX = _smallNumber(-9999, 9999, 1, 0);
		animOffsetY = _smallNumber(-9999, 9999, 1, 0);
		animOffsetX.onChange = _ ->
		{
			if (!suppressCallbacks) _applyAnimOffset();
		};
		animOffsetY.onChange = _ ->
		{
			if (!suppressCallbacks) _applyAnimOffset();
		};
		offsetRow.addComponent(animOffsetX);
		offsetRow.addComponent(animOffsetY);
		vbox.addComponent(offsetRow);

		var playBtn = new Button();
		playBtn.text = 'Play Animation';
		playBtn.width = vbox.width;
		playBtn.height = BTN_H;
		playBtn.styleString = 'background-color: #1A1A3A; color: white; border-radius: 6px; font-size: 13px;';
		playBtn.onClick = _ ->
		{
			if (selectedAnim != '') char.playAnim(selectedAnim, true);
		};
		vbox.addComponent(playBtn);

		vbox.addComponent(_sectionLabel('ANIMATION PROPERTIES'));

		vbox.addComponent(_hint('Prefix'));
		animPrefixField = new TextField();
		animPrefixField.width = vbox.width;
		animPrefixField.styleString = STYLE_INPUT;
		animPrefixField.onChange = _ ->
		{
			_syncAnimDataFromUI();
		};
		vbox.addComponent(animPrefixField);

		vbox.addComponent(_hint('Indices  (comma-separated, blank = all)'));
		animIndicesField = new TextField();
		animIndicesField.width = vbox.width;
		animIndicesField.styleString = STYLE_INPUT;
		animIndicesField.onChange = _ ->
		{
			_syncAnimDataFromUI();
		};
		vbox.addComponent(animIndicesField);

		var fpsRow = new HBox();
		fpsRow.width = vbox.width;
		fpsRow.styleString = 'spacing: 6px;';
		fpsRow.addComponent(_label('FPS:'));
		animFpsField = _smallNumber(1, 120, 1, 24);
		animFpsField.onChange = _ ->
		{
			_syncAnimDataFromUI();
		};
		fpsRow.addComponent(animFpsField);
		vbox.addComponent(fpsRow);

		animLoopedToggle = new CheckBox();
		animLoopedToggle.text = 'Looped';
		animLoopedToggle.selected = false;
		animLoopedToggle.styleString = 'color: white; font-size: 12px;';
		animLoopedToggle.onChange = _ ->
		{
			_syncAnimDataFromUI();
		};
		vbox.addComponent(animLoopedToggle);

		vbox.addComponent(_hint('Finish Anim (plays after current)'));
		animFinishField = new TextField();
		animFinishField.width = vbox.width;
		animFinishField.styleString = STYLE_INPUT;
		animFinishField.onChange = _ ->
		{
			_syncAnimDataFromUI();
		};
		vbox.addComponent(animFinishField);

		vbox.addComponent(_sectionLabel('GHOST POSE'));

		ghostToggle = new CheckBox();
		ghostToggle.text = 'Show Ghost';
		ghostToggle.selected = false;
		ghostToggle.styleString = 'color: white; font-size: 12px;';
		ghostToggle.onChange = _ ->
		{
			if (!suppressCallbacks) _toggleGhost(ghostToggle.selected);
		};
		vbox.addComponent(ghostToggle);

		vbox.addComponent(_hint('Reference animation'));
		ghostAnimDrop = new DropDown();
		ghostAnimDrop.width = vbox.width;
		ghostAnimDrop.styleString = STYLE_INPUT;
		ghostAnimDrop.onChange = _ ->
		{
			if (!suppressCallbacks && ghostAnimDrop.selectedItem != null) setGhostAnim(ghostAnimDrop.selectedItem.text, Std.int(ghostFrameField?.value ?? 0));
		};
		vbox.addComponent(ghostAnimDrop);

		var frameRow = new HBox();
		frameRow.width = vbox.width;
		frameRow.styleString = 'spacing: 6px;';
		frameRow.addComponent(_label('Frame:'));
		ghostFrameField = _smallNumber(0, 9999, 1, 0);
		ghostFrameField.onChange = _ ->
		{
			if (!suppressCallbacks && ghostAnimName != '') setGhostAnim(ghostAnimName, Std.int(ghostFrameField.value));
		};
		frameRow.addComponent(ghostFrameField);
		vbox.addComponent(frameRow);

		scroll.addComponent(vbox);
		add(scroll);

		final btnY1 = FlxG.height - BTN_H * 2 - PANEL_PAD * 2;
		final btnY2 = FlxG.height - BTN_H - PANEL_PAD;

		var saveBtn = new Button();
		saveBtn.text = 'Save Data';
		saveBtn.left = px + PANEL_PAD;
		saveBtn.top = btnY1;
		saveBtn.width = PANEL_W - PANEL_PAD * 2;
		saveBtn.height = BTN_H;
		saveBtn.styleString = 'background-color: #1A3A1A; color: #88FF88; border-radius: 6px; font-size: 13px;';
		saveBtn.onClick = _ -> _save();
		add(saveBtn);

		var backBtn = new Button();
		backBtn.text = '<- Exit';
		backBtn.left = px + PANEL_PAD;
		backBtn.top = btnY2;
		backBtn.width = PANEL_W - PANEL_PAD * 2;
		backBtn.height = BTN_H;
		backBtn.styleString = 'background-color: #3A1A1A; color: #FF8888; border-radius: 6px; font-size: 13px;';
		backBtn.onClick = _ -> _exit();
		add(backBtn);
	}

	private function _buildRightPanel():Void
	{
		final px:Float = FlxG.width - PANEL_W;

		var bg = new MoonSprite().makeGraphic(PANEL_W, FlxG.height, FlxColor.TRANSPARENT);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, PANEL_W, FlxG.height, 0, 0, 0xD2101020);
		bg.active = false;
		bg.camera = camGame;
		bg.x = px;
		bg.scrollFactor.set(0, 0);
		add(bg);

		_uiText(px + PANEL_PAD, 10, PANEL_W - PANEL_PAD, 'CHARACTER DATA', 28, camUI);
		_uiHRule(px + PANEL_PAD, 40, camUI);

		var scroll = new ScrollView();
		scroll.left = px;
		scroll.top = 46;
		scroll.width = PANEL_W;
		scroll.height = FlxG.height - 46;
		scroll.styleString = 'background-color: #101020; border: none; padding: 0;';

		var vbox = new VBox();
		vbox.width = PANEL_W - PANEL_PAD * 2;
		vbox.left = PANEL_PAD;
		vbox.styleString = STYLE_PANEL;

		vbox.addComponent(_sectionLabel('Scale'));
		scaleField = _inlineNumber(vbox, 0.1, 10.0, 0.05, char.data?.scale ?? 1.0);
		scaleField.onChange = _ ->
		{
			if (suppressCallbacks) return;
			final s = scaleField.value;
			char.scale.set(s, s);
			char.updateHitbox();
		};

		vbox.addComponent(_sectionLabel('Flags'));
		antialiasingToggle = _inlineCheckbox(vbox, 'Antialiasing', char.data?.antialiasing ?? true);
		antialiasingToggle.onChange = _ ->
		{
			if (!suppressCallbacks) char.antialiasing = antialiasingToggle.selected;
		};
		flipXToggle = _inlineCheckbox(vbox, 'Flip X', char.data?.flipX ?? false);
		flipXToggle.onChange = _ ->
		{
			if (!suppressCallbacks) char.flipX = flipXToggle.selected;
		};

		vbox.addComponent(_sectionLabel('Camera Offsets  X / Y'));
		var camRow = new HBox();
		camRow.width = vbox.width;
		camRow.styleString = 'spacing: 6px;';
		camOffsetXField = _smallNumber(-9999, 9999, 1, char?.data?.camOffsets[0] ?? 0);
		camOffsetYField = _smallNumber(-9999, 9999, 1, char?.data?.camOffsets[1] ?? 0);
		camOffsetXField.onChange = _ ->
		{
			if (!suppressCallbacks) _applyCamOffsets();
		};
		camOffsetYField.onChange = _ ->
		{
			if (!suppressCallbacks) _applyCamOffsets();
		};
		camRow.addComponent(camOffsetXField);
		camRow.addComponent(camOffsetYField);
		vbox.addComponent(camRow);

		vbox.addComponent(_sectionLabel('Extra Offsets  X / Y'));
		var exRow = new HBox();
		exRow.width = vbox.width;
		exRow.styleString = 'spacing: 6px;';
		extraOffsetXField = _smallNumber(-9999, 9999, 1, char?.data?.extraOffsets[0] ?? 0);
		extraOffsetYField = _smallNumber(-9999, 9999, 1, char?.data?.extraOffsets[1] ?? 0);
		extraOffsetXField.onChange = _ ->
		{
			if (!suppressCallbacks) _applyExtraOffsets();
		};
		extraOffsetYField.onChange = _ ->
		{
			if (!suppressCallbacks) _applyExtraOffsets();
		};
		exRow.addComponent(extraOffsetXField);
		exRow.addComponent(extraOffsetYField);
		vbox.addComponent(exRow);

		vbox.addComponent(_sectionLabel('Healthbar Color  R / G / B'));
		var hbRow = new HBox();
		hbRow.width = vbox.width;
		hbRow.styleString = 'spacing: 4px;';
		hbColorRField = _smallNumber(0, 255, 1, char?.data?.icon.color[0] ?? 80);
		hbColorGField = _smallNumber(0, 255, 1, char?.data?.icon.color[1] ?? 80);
		hbColorBField = _smallNumber(0, 255, 1, char?.data?.icon.color[2] ?? 80);
		hbRow.addComponent(hbColorRField);
		hbRow.addComponent(hbColorGField);
		hbRow.addComponent(hbColorBField);
		vbox.addComponent(hbRow);

		vbox.addComponent(_sectionLabel('Dance Frequency (beats)'));
		danceFreqField = _inlineNumber(vbox, 1, 16, 1, char.data?.danceFrequency ?? 2);
		danceFreqField.onChange = _ ->
		{
			if (!suppressCallbacks) char.danceFrequency = Std.int(danceFreqField.value);
		};

		vbox.addComponent(_sectionLabel('Hold Duration (steps)'));
		holdDurField = _inlineNumber(vbox, 1, 64, 1, char.data?.holdDuration ?? 8);
		holdDurField.onChange = _ ->
		{
			if (!suppressCallbacks) char.holdDuration = Std.int(holdDurField.value);
		};

		vbox.addComponent(_sectionLabel('Gameover Color (0xAARRGGBB)'));
		gameoverColorField = new TextField();
		gameoverColorField.text = char.data?.gameoverColorScheme ?? '0xFF4924FF';
		gameoverColorField.width = vbox.width;
		gameoverColorField.styleString = STYLE_INPUT;
		vbox.addComponent(gameoverColorField);

		vbox.addComponent(_sectionLabel('Override Anim Groups'));
		vbox.addComponent(_hint('e.g.  singAnims, idle'));
		overrideAnimsField = new TextField();
		overrideAnimsField.text = (char.data?.overrideAnims ?? []).join(', ');
		overrideAnimsField.width = vbox.width;
		overrideAnimsField.styleString = STYLE_INPUT;
		vbox.addComponent(overrideAnimsField);

		var resetBtn = new Button();
		resetBtn.text = 'Reset Camera';
		resetBtn.width = vbox.width;
		resetBtn.height = BTN_H;
		resetBtn.styleString = 'background-color: #1A1A3A; color: #8888FF; border-radius: 6px; font-size: 13px;';
		resetBtn.onClick = _ ->
		{
			camGame.scroll.set(0, 0);
		};
		vbox.addComponent(resetBtn);

		scroll.addComponent(vbox);
		add(scroll);
	}

	private function _populateAnimList():Void
	{
		suppressCallbacks = true;

		animList.dataSource.clear();
		ghostAnimDrop.dataSource.clear();

		for (anim in char.data.animations)
		{
			animList.dataSource.add({
				text: anim.name
			});
			ghostAnimDrop.dataSource.add({
				text: anim.name
			});
		}

		if (char.data.animations.length > 0)
		{
			animList.selectedIndex = 0;
			suppressCallbacks = false;
			_onAnimSelected();
		}
		else
			suppressCallbacks = false;
	}

	private function _onAnimSelected():Void
	{
		if (animList.selectedItem == null) return;
		selectedAnim = animList.selectedItem.text;

		char.playAnim(selectedAnim, true);

		suppressCallbacks = true;

		// ---- offset fields
		final off = char.animOffsets.get(selectedAnim);
		animOffsetX.value = (off != null) ? off[0] : 0.0;
		animOffsetY.value = (off != null) ? off[1] : 0.0;

		// --- anim properties
		final data = _getAnimData(selectedAnim);
		if (data != null)
		{
			animPrefixField.text = data.prefix ?? '';
			animFpsField.value = data.fps ?? 24;
			animLoopedToggle.selected = data.looped ?? false;
			animFinishField.text = data.finishAnim ?? '';
			animIndicesField.text = (data.indices != null && data.indices.length > 0) ? [for (i in data.indices) Std.string(Std.int(i))].join(", ") : '';
		}

		suppressCallbacks = false;
	}

	private function _syncAnimDataFromUI():Void
	{
		if (suppressCallbacks || selectedAnim == '') return;

		final data = _getAnimData(selectedAnim);
		if (data == null) return;

		data.prefix = animPrefixField.text;
		data.fps = Std.int(animFpsField.value);
		data.looped = animLoopedToggle.selected;

		final fin = animFinishField.text.trim();
		data.finishAnim = (fin != '') ? fin : null;

		final indRaw = animIndicesField.text.trim();
		// TODO
		/*if (indRaw != '')
			{
				data.indices = [for (s in indRaw.split(',')) {
					final n = Std.parseInt(s.trim());
					if (n != null) n;
				}].filter(n -> n != null);
			}
			else data.indices = null; */
	}

	private function _getAnimData(animName:String):Null<Paths.AnimationData>
	{
		for (a in char.data.animations) if (a.name == animName) return a;
		return null;
	}

	private function _applyAnimOffset():Void
	{
		if (selectedAnim == '') return;

		final x:Float = animOffsetX.value;
		final y:Float = animOffsetY.value;

		char.addOffset(selectedAnim, x, y);
		char.playAnim(selectedAnim, true);

		// Keep data.animations in sync too!!!!!
		final data = _getAnimData(selectedAnim);
		if (data != null)
		{
			data.x = x;
			data.y = y;
		}

		if (ghostEnabled && ghostAnimName == selectedAnim) setGhostAnim(ghostAnimName, Std.int(ghostFrameField?.value ?? 0));
	}

	private function _nudgeOffset(dx:Float, dy:Float):Void
	{
		suppressCallbacks = true;
		animOffsetX.value += dx;
		animOffsetY.value += dy;
		suppressCallbacks = false;
		_applyAnimOffset();
	}

	private function _applyCamOffsets():Void char.camOffsets = [camOffsetXField.value, camOffsetYField.value];

	private function _applyExtraOffsets():Void
	{
		if (char.data.extraOffsets == null) char.data.extraOffsets = [0.0, 0.0];
		char.data.extraOffsets[0] = extraOffsetXField.value;
		char.data.extraOffsets[1] = extraOffsetYField.value;
	}

	private function _syncGhostGraphic():Void
	{
		ghost.loadGraphicFromSprite(char);
		ghost.animation.copyFrom(char.animation);
		ghost.animOffsets = char.animOffsets.copy();
		ghost.scale.copyFrom(char.scale);
		ghost.flipX = char.flipX;
		ghost.antialiasing = char.antialiasing;
		ghost.updateHitbox();
	}

	private function _toggleGhost(enabled:Bool):Void
	{
		ghostEnabled = enabled;
		ghost.visible = ghostEnabled;

		suppressCallbacks = true;
		if (ghostToggle != null) ghostToggle.selected = ghostEnabled;
		suppressCallbacks = false;

		if (ghostEnabled && ghostAnimName != '') setGhostAnim(ghostAnimName, Std.int(ghostFrameField?.value ?? 0));
	}

	/**
	 * Plays `animName` on the ghost at `frame`, applying the correct offset
	 * from `char.animOffsets` so it aligns with the character's coordinate system.
	 */
	public function setGhostAnim(animName:String, frame:Int = 0):Void
	{
		ghostAnimName = animName;

		_syncGhostGraphic();

		// playAnim internally calls doAnimThingy which applies animOffsets
		// AAAA
		// oh im stupid
		ghost.playAnim(animName, true);

		// pause and seek to the requested frame
		if (ghost.animation.curAnim != null)
		{
			final maxFrame = ghost.animation.curAnim.frames.length - 1;
			ghost.animation.curAnim.curFrame = Std.int(FlxMath.bound(frame, 0, maxFrame));
			ghost.animation.pause();
		}

		// updates the frame stepper max to reflect the real anim length
		// uhhhhhhhhhhhh
		if (ghostFrameField != null && ghost.animation.curAnim != null)
		{
			suppressCallbacks = true;
			ghostFrameField.max = Math.max(0, ghost.animation.curAnim.frames.length - 1);
			suppressCallbacks = false;
		}

		ghost.x = char.x;
		ghost.y = char.y;
	}

	private function _save():Void
	{
		#if sys
		final d = char.data;

		d.scale = scaleField?.value ?? d.scale;
		d.antialiasing = antialiasingToggle?.selected ?? d.antialiasing;
		d.flipX = flipXToggle?.selected ?? d.flipX;
		d.camOffsets = [camOffsetXField?.value ?? 0, camOffsetYField?.value ?? 0];
		d.extraOffsets = [extraOffsetXField?.value ?? 0, extraOffsetYField?.value ?? 0];
		d.icon.color = [
			Std.int(hbColorRField?.value ?? 80),
			Std.int(hbColorGField?.value ?? 80),
			Std.int(hbColorBField?.value ?? 80)
		];
		d.danceFrequency = Std.int(danceFreqField?.value ?? 2);
		d.holdDuration = Std.int(holdDurField?.value ?? 8);
		d.gameoverColorScheme = gameoverColorField?.text ?? d.gameoverColorScheme;

		final rawOverride = overrideAnimsField?.text ?? '';
		d.overrideAnims = (rawOverride.trim() == '') ? [] : [for (s in rawOverride.split(',')) s.trim()].filter(s -> s != '');

		for (anim in d.animations)
		{
			final off = char.animOffsets.get(anim.name);
			if (off != null)
			{
				anim.x = off[0];
				anim.y = off[1];
			}
		}

		// _syncAnimDataFromUI already keeps data.animations up to date live,
		// but call once more for the currently selected anim to be safe.
		// you can tell I don't trust my own code
		_syncAnimDataFromUI();

		final savePath = Paths.getPath('characters/$characterName/data.json');
		try
		{
			File.saveContent(savePath, Json.stringify(d, null, '\t'));
			camUI.flash(0xFF1A3A1A, 0.3);
			trace('[OFFSET-EDITOR] Saved: $savePath', "INFO");
		}
		catch (e:Dynamic)
		{
			camUI.flash(0xFF3A1A1A, 0.3);
			trace('[OFFSET-EDITOR] Save failed: $e', "ERROR");
		}
		#else
		trace('[OFFSET-EDITOR] Saving is only supported on desktop.', "WARNING");
		#end
	}

	private function _exit():Void
	{
		FlxG.mouse.visible = false;
		FlxG.switchState(() -> new moon.menus.MainMenu());
	}

	private function _syncDataPanel():Void
	{
		suppressCallbacks = true;
		final d = char.data;

		if (scaleField != null) scaleField.value = d?.scale ?? 1.0;
		if (antialiasingToggle != null) antialiasingToggle.selected = d?.antialiasing ?? true;
		if (flipXToggle != null) flipXToggle.selected = d?.flipX ?? false;
		if (camOffsetXField != null) camOffsetXField.value = d?.camOffsets[0] ?? 0;
		if (camOffsetYField != null) camOffsetYField.value = d?.camOffsets[1] ?? 0;
		if (extraOffsetXField != null) extraOffsetXField.value = d?.extraOffsets[0] ?? 0;
		if (extraOffsetYField != null) extraOffsetYField.value = d?.extraOffsets[1] ?? 0;
		if (hbColorRField != null) hbColorRField.value = d?.icon.color[0] ?? 80;
		if (hbColorGField != null) hbColorGField.value = d?.icon.color[1] ?? 80;
		if (hbColorBField != null) hbColorBField.value = d?.icon.color[2] ?? 80;
		if (danceFreqField != null) danceFreqField.value = d?.danceFrequency ?? 2;
		if (holdDurField != null) holdDurField.value = d?.holdDuration ?? 8;
		if (gameoverColorField != null) gameoverColorField.text = d?.gameoverColorScheme ?? '0xFF4924FF';
		if (overrideAnimsField != null) overrideAnimsField.text = (d?.overrideAnims ?? []).join(', ');

		suppressCallbacks = false;
	}

	private function _uiText(x:Float, y:Float, w:Float, text:String, size:Int, cam:FlxCamera, ?color:Int = 0xFFFFFFFF):FlxText
	{
		var t = new FlxText(x, y, w, text, size);
		t.setFormat(Paths.font('phantomuff/difficulty.ttf'), size, color);
		t.antialiasing = true;
		t.active = false;
		t.camera = cam;
		add(t);
		return t;
	}

	private function _uiHRule(x:Float, y:Float, cam:FlxCamera):Void
	{
		var hr = new MoonSprite().makeGraphic(PANEL_W - PANEL_PAD * 2, 1, 0xFF333355);
		hr.setPosition(x, y);
		hr.active = false;
		hr.camera = cam;
		add(hr);
	}

	private function _sectionLabel(text:String):Label
	{
		var lbl = new Label();
		lbl.text = text;
		lbl.styleString = 'color: white; font-size: 11px; font-weight: bold;';
		return lbl;
	}

	private function _hint(text:String):Label
	{
		var lbl = new Label();
		lbl.text = text;
		lbl.styleString = 'color: #666688; font-size: 10px;';
		return lbl;
	}

	private function _label(text:String):Label
	{
		var lbl = new Label();
		lbl.text = text;
		lbl.styleString = 'color: white; font-size: 12px; vertical-align: center;';
		return lbl;
	}

	private function _inlineNumber(parent:VBox, min:Float, max:Float, step:Float, def:Float):NumberStepper
	{
		var ns = new NumberStepper();
		ns.width = (parent != null) ? parent.width : 200;
		ns.min = min;
		ns.max = max;
		ns.step = step;
		ns.value = def;
		ns.styleString = STYLE_INPUT;
		if (parent != null) parent.addComponent(ns);
		return ns;
	}

	private function _inlineCheckbox(parent:VBox, label:String, def:Bool):CheckBox
	{
		var cb = new CheckBox();
		cb.text = label;
		cb.selected = def;
		cb.styleString = 'color: white; font-size: 12px;';
		parent.addComponent(cb);
		return cb;
	}

	private function _smallNumber(min:Float, max:Float, step:Float, def:Float):NumberStepper
	{
		var ns = new NumberStepper();
		ns.min = min;
		ns.max = max;
		ns.step = step;
		ns.value = def;
		ns.styleString = STYLE_INPUT;
		return ns;
	}
}
