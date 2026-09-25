package moon.toolkit.offset;

import moon.game.obj.Character.CharacterType;
import moon.game.obj.*;

using StringTools;

/**
 * Hey! This editor is currently far from finished (I hope)
 * Since like... we don't even have a design for it yet!
 * Sooo yeahhhh.
 */
class OffsetEditor extends FlxState
{
	static inline final PANEL_W:Float = 300;
	static inline final PANEL_PAD:Float = 12;
	static inline final OFFSET_MIN:Int = -9999;
	static inline final OFFSET_MAX:Int = 9999;
	static inline final STAGE_NAME:String = 'mainStage';
	static inline final ZOOM_MIN:Float = 0.05;
	static inline final ZOOM_MAX:Float = 12.0;
	static final ROLE_LABELS:Array<String> = ['Opponent', 'Player', 'Spectator'];
	static final ROLE_TYPES:Array<CharacterType> = [OPPONENT, PLAYER, SPECTATOR];

	var camGAME:MoonCamera;
	var camHUD:MoonCamera;
	var camALT:MoonCamera;
	var conductor:Conductor;
	var stage:Stage;
	var charList:Array<String> = [];
	var stageList:Array<String> = [];
	var preview:Character;
	var ghost:Character;
	var ghostGroup:FlxSpriteGroup;
	var ghostChar:String = '';
	var previousChar:String = '';
	var ghostFollowMode:Bool = false;
	var previewMode:Bool = false;
	var rolePositions:Array<Array<Float>> = [[64, 396], [916, 396], [296, 374]];
	var roleCamOffsets:Array<Array<Float>> = [[0, 0], [0, 0], [0, 0]];
	var roleMarkers:Array<MoonSprite> = [];
	var roleLabels:Array<FlxText> = [];
	var currentRoleIndex:Int = 0;
	var camFocusMarker:MoonSprite;
	var panelBg:MoonSprite;
	var camFocusLabel:FlxText;
	var panel:UIScrollPage;
	var charDropdown:UIDropdown;
	var roleDropdown:UIDropdown;
	var animDropdown:UIDropdown;
	var stageDropdown:UIDropdown;
	var offsetXStepper:UIStepper;
	var offsetYStepper:UIStepper;
	var camXStepper:UIStepper;
	var camYStepper:UIStepper;
	var extraXStepper:UIStepper;
	var extraYStepper:UIStepper;
	var scaleStepper:UIStepper;
	var playAnimBtn:UIActionButton;
	var saveBtn:UIActionButton;
	var ghostFollowBtn:UIActionButton;
	var previewBtn:UIActionButton;
	var infoText:FlxText;
	var currentChar:String = '';
	var currentAnim:String = 'idle-0';
	var animNames:Array<String> = [];
	var suppressCallbacks:Bool = false;
	var camDragging:Bool = false;
	var lastMousePos:FlxPoint = FlxPoint.get();

	override public function create():Void
	{
		super.create();

		if (FlxG.sound.music != null) FlxG.sound.music.stop();

		camGAME = new MoonCamera();
		camGAME.bgColor = FlxColor.fromRGB(30, 29, 31);

		camHUD = new MoonCamera();
		camHUD.bgColor = 0x00000000;

		camALT = new MoonCamera();
		camALT.bgColor = 0x00000000;

		FlxG.cameras.add(camGAME, true);
		FlxG.cameras.add(camHUD, false);
		FlxG.cameras.add(camALT, false);

		conductor = new Conductor(100);

		stage = new Stage(STAGE_NAME, conductor);
		add(stage);

		stage.updatePositioning();
		setupRolePositions();
		applyStageCamera();

		buildRoleMarkers();

		camFocusMarker = new MoonSprite();
		camFocusMarker.makeGraphic(28, 28, FlxColor.TRANSPARENT);
		final reticle = {
			color: 0xFFFFCC44,
			thickness: 2
		};

		FlxSpriteUtil.drawLine(camFocusMarker, 2, 2, 25, 2, reticle);
		FlxSpriteUtil.drawLine(camFocusMarker, 25, 2, 25, 25, reticle);
		FlxSpriteUtil.drawLine(camFocusMarker, 25, 25, 2, 25, reticle);
		FlxSpriteUtil.drawLine(camFocusMarker, 2, 25, 2, 2, reticle);
		FlxSpriteUtil.drawLine(camFocusMarker, 4, 14, 24, 14, {
			color: 0xFFFFCC44,
			thickness: 1
		});

		FlxSpriteUtil.drawLine(camFocusMarker, 14, 4, 14, 24, {
			color: 0xFFFFCC44,
			thickness: 1
		});
		camFocusMarker.offset.set(14, 14);
		add(camFocusMarker);

		camFocusLabel = new FlxText(0, 0, 120, "CAM FOCUS");
		camFocusLabel.setFormat(UITheme.FONT, 11, 0xFFFFCC44, CENTER);
		camFocusLabel.active = false;
		add(camFocusLabel);

		charList = listAllCharacters();
		stageList = listAllStages();

		UIOverlay.init();

		buildPanel();
		loadCharacter(charList[0]);
		UIOverlay.layer.camera = camHUD;
		add(UIOverlay.layer);

		MoonUtils.playGlobalMusic('toolkit/meetingNewFoes', true);

		FlxG.mouse.visible = FlxG.mouse.useSystemCursor = true;
		FlxG.autoPause = false;
	}

	function setupRolePositions():Void
	{
		if (stage != null)
		{
			if (stage.opponents != null) rolePositions[0] = [stage.opponents.x, stage.opponents.y];
			if (stage.players != null) rolePositions[1] = [stage.players.x, stage.players.y];
			if (stage.spectators != null) rolePositions[2] = [stage.spectators.x, stage.spectators.y];
		}

		roleCamOffsets = [[0, 0], [0, 0], [0, 0]];
		if (stage == null || stage.json == null || stage.json.characters == null) return;

		for (ch in stage.json.characters)
		{
			if (ch == null) continue;
			final cam = (ch.camOffsets != null) ? [ch.camOffsets[0] ?? 0.0, ch.camOffsets[1] ?? 0.0] : [0.0, 0.0];
			final t = Std.string(ch.type).toLowerCase();

			// shit lmao
			if (t == 'opponent') roleCamOffsets[0] = cam;
			else if (t == 'player') roleCamOffsets[1] = cam;
			else if (t == 'spectator') roleCamOffsets[2] = cam;

			if (ch.position != null)
			{
				final pos = [ch.position[0] ?? 0.0, ch.position[1] ?? 0.0];
				if (t == 'opponent' && (stage.opponents == null || stage.opponents.length == 0)) rolePositions[0] = pos;
				else if (t == 'player' && (stage.players == null || stage.players.length == 0)) rolePositions[1] = pos;
				else if (t == 'spectator' && (stage.spectators == null || stage.spectators.length == 0)) rolePositions[2] = pos;
			}
		}
	}

	function applyStageCamera():Void
	{
		if (stage == null || stage.cameraSettings == null) return;
		final z = stage.cameraSettings.zoom ?? 1.0;

		camGAME.zoom = z;
		camGAME.scroll.set((stage.cameraSettings.startX ?? 0.0) - FlxG.width * 0.5 / z, (stage.cameraSettings.startY ?? 0.0) - FlxG.height * 0.5 / z);
	}

	function buildRoleMarkers():Void
	{
		final colors = [0xFFFF6666, 0xFF66AAFF, 0xFFFF66F2];
		for (i in 0...3)
		{
			final pos = rolePositions[i];
			final m = new MoonSprite(pos[0] - 12, pos[1] - 12);
			m.makeGraphic(24, 24, FlxColor.TRANSPARENT);
			FlxSpriteUtil.drawLine(m, 0, 12, 24, 12, {
				color: 0xFFFFFFFF,
				thickness: 2
			});

			FlxSpriteUtil.drawLine(m, 12, 0, 12, 24, {
				color: 0xFFFFFFFF,
				thickness: 2
			});

			m.blend = INVERT;

			add(m);
			roleMarkers.push(m);

			final lab = new FlxText(pos[0] - 40, pos[1] - 28, 80, ROLE_LABELS[i]);
			lab.setFormat(UITheme.FONT, 12, colors[i], CENTER);

			lab.active = m.active = false;
			add(lab);
			roleLabels.push(lab);
		}
		updateRoleHighlight();
	}

	function updateRoleHighlight():Void
	{
		for (i in 0...roleMarkers.length) roleMarkers[i].alpha = roleLabels[i].alpha = (i == currentRoleIndex) ? 1 : 0.35;
	}

	function buildPanel():Void
	{
		final panelX = FlxG.width - PANEL_W - PANEL_PAD;
		final panelY = PANEL_PAD;
		final panelH = FlxG.height - PANEL_PAD * 2 - 160;

		panelBg = new MoonSprite(panelX - 8, 0);
		panelBg.makeGraphic(Std.int(PANEL_W + 16 + PANEL_PAD), FlxG.height, 0xEE0A0A0C);
		panelBg.camera = camHUD;
		panelBg.scrollFactor.set();
		panelBg.active = false;
		add(panelBg);

		final title = new FlxText(panelX, panelY, PANEL_W, "OFFSET EDITOR (placeholder)");
		title.setFormat(UITheme.FONT, 13, UITheme.TEXT_COLOR);
		title.camera = camHUD;
		title.scrollFactor.set();
		title.active = false;
		add(title);

		panel = new UIScrollPage(panelX, panelY + 28, PANEL_W, panelH - 40, "Offsets");
		panel.camera = camHUD;
		panel.visible = panel.active = true;
		add(panel);

		final initialStageIdx = Std.int(Math.max(0, stageList.indexOf(STAGE_NAME)));
		stageDropdown = new UIDropdown(0, 0, PANEL_W, "Stage", stageList, null, initialStageIdx, 12);
		stageDropdown.camera = camHUD;
		stageDropdown.onChange = onStagePicked;
		panel.addComponent(stageDropdown);

		charDropdown = new UIDropdown(0, 0, PANEL_W, "Character", charList, null, 0, 12);
		charDropdown.camera = camHUD;
		charDropdown.onChange = onCharacterPicked;
		panel.addComponent(charDropdown);

		roleDropdown = new UIDropdown(0, 0, PANEL_W, "Stage Role", ROLE_LABELS, null, 0, 6);
		roleDropdown.camera = camHUD;
		roleDropdown.onChange = onRolePicked;
		panel.addComponent(roleDropdown);

		animDropdown = new UIDropdown(0, 0, PANEL_W, "Animation", ["idle-0"], null, 0, 12);
		animDropdown.camera = camHUD;
		animDropdown.onChange = onAnimationPicked;
		panel.addComponent(animDropdown);

		offsetXStepper = new UIStepper(0, 0, PANEL_W, "Offset X", OFFSET_MIN, OFFSET_MAX, 0, 1);
		offsetXStepper.camera = camHUD;
		offsetXStepper.onChange = (_) -> applyAnimOffset();
		panel.addComponent(offsetXStepper);

		offsetYStepper = new UIStepper(0, 0, PANEL_W, "Offset Y", OFFSET_MIN, OFFSET_MAX, 0, 1);
		offsetYStepper.camera = camHUD;
		offsetYStepper.onChange = (_) -> applyAnimOffset();
		panel.addComponent(offsetYStepper);

		camXStepper = new UIStepper(0, 0, PANEL_W, "Cam Off X", OFFSET_MIN, OFFSET_MAX, 0, 1);
		camXStepper.camera = camHUD;
		camXStepper.onChange = (_) -> applyCamOffsets();
		panel.addComponent(camXStepper);

		camYStepper = new UIStepper(0, 0, PANEL_W, "Cam Off Y", OFFSET_MIN, OFFSET_MAX, 0, 1);
		camYStepper.camera = camHUD;
		camYStepper.onChange = (_) -> applyCamOffsets();
		panel.addComponent(camYStepper);

		extraXStepper = new UIStepper(0, 0, PANEL_W, "Extra Off X", OFFSET_MIN, OFFSET_MAX, 0, 1);
		extraXStepper.camera = camHUD;
		extraXStepper.onChange = (_) -> applyExtraOffsets();
		panel.addComponent(extraXStepper);

		extraYStepper = new UIStepper(0, 0, PANEL_W, "Extra Off Y", OFFSET_MIN, OFFSET_MAX, 0, 1);
		extraYStepper.camera = camHUD;
		extraYStepper.onChange = (_) -> applyExtraOffsets();
		panel.addComponent(extraYStepper);

		scaleStepper = new UIStepper(0, 0, PANEL_W, "Scale", 1, 500, 100, 1);
		scaleStepper.camera = camHUD;
		scaleStepper.onChange = (_) -> applyScale();
		panel.addComponent(scaleStepper);

		panel.layoutVertical();
		panel.show(FadeOnly, 0.2);

		for (m in panel.content.members) if (m != null) m.camera = camHUD;

		final btnY = panel.y + panelH - 8;
		final btnGap = UITheme.ROW_HEIGHT + 4;

		playAnimBtn = new UIActionButton(panelX, btnY, PANEL_W, "Replay Animation", () -> replaySelectedAnim());
		playAnimBtn.camera = camHUD;
		add(playAnimBtn);

		saveBtn = new UIActionButton(panelX, btnY + btnGap, PANEL_W, "Save (Ctrl+S)", () -> saveChar());
		saveBtn.camera = camHUD;
		add(saveBtn);

		ghostFollowBtn = new UIActionButton(panelX, btnY + btnGap * 2, PANEL_W, "Update Ghost (G / Shift+G)", () -> updateGhost());
		ghostFollowBtn.camera = camHUD;
		add(ghostFollowBtn);

		previewBtn = new UIActionButton(panelX, btnY + btnGap * 3, PANEL_W, "Preview Camera (P)", () -> togglePreviewMode());
		previewBtn.camera = camHUD;
		add(previewBtn);

		infoText = new FlxText(
			12,
			FlxG.height - 48,
			FlxG.width - PANEL_W - 40,
			"Arrows nudge • Q/E anim • 1/2/3 role • Space replay • G ghost • P preview • RMB pan • Scroll zoom • ESC"
		);
		infoText.setFormat(UITheme.FONT, 20, UITheme.TEXT_DIM);
		infoText.setBorderStyle(SHADOW, 0xFF000000, 4);
		infoText.camera = camALT;
		infoText.active = false;
		add(infoText);
	}

	function listAllCharacters():Array<String>
	{
		var out:Array<String> = [];
		var seen:Map<String, Bool> = [];

		inline function add(path:String):Void
		{
			if (seen.exists(path)) return;
			seen.set(path, true);
			out.push(path);
		}

		for (entry in Paths.readDir('characters'))
		{
			if (Paths.exists('characters/$entry/data.json')) add(entry);
			for (sub in Paths.readDir('characters/$entry'))
			{
				if (Paths.exists('characters/$entry/$sub/data.json')) add('$entry/$sub');
			}
		}

		out.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return out;
	}

	function listAllStages():Array<String>
	{
		var out:Array<String> = [];
		for (entry in Paths.readDir('stages'))
		{
			if (Paths.exists('stages/$entry/data.json')) out.push(entry);
		}
		out.sort((a, b) -> Reflect.compare(a.toLowerCase(), b.toLowerCase()));
		return out;
	}

	// You may ask: Why the FUCK did you separate so many shit into functions?
	// and I reply: we may polish so its nicer,,.,,.,,,,

	function onCharacterPicked(name:String):Void
	{
		if (suppressCallbacks) return;
		loadCharacter(name);
	}

	function onStagePicked(name:String):Void
	{
		if (suppressCallbacks) return;
		loadStage(name);
	}

	function onRolePicked(label:String):Void
	{
		if (suppressCallbacks) return;
		final idx = ROLE_LABELS.indexOf(label);
		if (idx >= 0) setRole(idx);
	}

	function onAnimationPicked(name:String):Void
	{
		if (suppressCallbacks) return;
		currentAnim = name;
		syncCharOffsets();
		replaySelectedAnim();
	}

	function setRole(index:Int):Void
	{
		final next = Std.int(FlxMath.bound(index, 0, 2));
		if (next == currentRoleIndex && preview != null)
		{
			updateRoleHighlight();
			return;
		}
		currentRoleIndex = next;
		updateRoleHighlight();

		if (currentChar != null && currentChar != '') loadCharacter(currentChar);
		else
		{
			repositionChars();
			updtCamMarker();
		}

		infoText.text = 'Role: ${ROLE_LABELS[currentRoleIndex]} • "$currentChar" • Q/E anim • Space replay';
		infoText.color = FlxColor.WHITE;
	}

	function loadCharacter(name:String):Void
	{
		if (currentChar != '' && currentChar != name) previousChar = currentChar;
		clearStagePreview(false);

		currentChar = name;

		final group = roleGroup(currentRoleIndex);
		stage.addCharTo(name, group);

		stage.updatePositioning();
		setupRolePositions();

		preview = findCharInGroup(group);
		if (preview == null)
		{
			preview = new Character(0, 0, name, conductor);
			preview.type = ROLE_TYPES[currentRoleIndex];
			group.add(preview);
		}
		preview.conductor = conductor;
		restoreCharCamOffsets(preview);
		applyCharacterTransform(preview);

		if (ghost == null) updateGhost();

		refreshAnimationList();
		syncFields();
		repositionChars();
		updtCamMarker();
		updateMarkersPos();

		infoText.text = 'Loaded "$name" @ ${ROLE_LABELS[currentRoleIndex]} • ${animNames.length} anims';
		infoText.color = UITheme.ACCENT;
	}

	function restoreCharCamOffsets(char:Character):Void
	{
		if (char == null) return;
		if (char.data != null && char.data.camOffsets != null) char.camOffsets = [
			char.data.camOffsets[0] ?? 0.0,
			char.data.camOffsets[1] ?? 0.0
		];
		else
			char.camOffsets = [0.0, 0.0];
	}

	function applyCharacterTransform(char:Character, ?scaleOverride:Float):Void
	{
		if (char == null) return;

		final s = (scaleOverride != null) ? scaleOverride : ((char.data != null && char.data.scale != null) ? char.data.scale : 1.0);

		char.scale.set(1, 1);
		char.updateHitbox();
		char.origin.set(char.width * 0.5, char.height);
		char.scale.set(s, s);
	}

	function loadStage(name:String):Void
	{
		if (stage != null)
		{
			if (conductor != null) conductor.onBeat.remove(stage.onStageBeat);
			remove(stage, true);
			stage.destroy();
		}

		stage = new Stage(name, conductor);
		insert(0, stage);

		rolePositions = [[64, 396], [916, 396], [296, 374]];
		roleCamOffsets = [[0, 0], [0, 0], [0, 0]];

		stage.updatePositioning();
		setupRolePositions();
		applyStageCamera();
		updateMarkersPos();

		if (ghost != null)
		{
			ghost.destroy();
			ghost = null;
			ghostGroup = null;
		}

		if (currentChar != '') loadCharacter(currentChar);

		infoText.text = 'Stage: "$name"';
		infoText.color = UITheme.ACCENT;
	}

	function updateGhost():Void
	{
		if (currentChar == '') return;

		ghostChar = currentChar;

		if (ghost != null)
		{
			if (ghostGroup != null) ghostGroup.remove(ghost, true);
			ghost.destroy();
			ghost = null;
		}

		ghostGroup = roleGroup(currentRoleIndex);
		ghost = new Character(0, 0, ghostChar, null);
		ghost.alpha = 0.25;
		ghost.color = 0xFF8888FF;
		ghost.type = ROLE_TYPES[currentRoleIndex];
		ghostGroup.insert(0, ghost);

		if (ghost.isAnimate) ghost.useRenderTexture = true;

		final s = scaleStepper != null ? scaleStepper.value / 100.0 : ((ghost.data != null && ghost.data.scale != null) ? ghost.data.scale : 1.0);
		applyCharacterTransform(ghost, s);

		repositionChars();
		syncGhostPose();

		infoText.text = ghostFollowMode ? 'Ghost: "$ghostChar" (live follows "$currentChar")' : 'Ghost: "$ghostChar" (frozen on "$currentAnim")';
		infoText.color = UITheme.ACCENT;
	}

	function syncGhostPose():Void
	{
		if (ghost == null) return;
		final animToPlay = ghost.animation.exists(currentAnim) ? currentAnim : 'idle-0';
		if (ghost.animation.exists(animToPlay))
		{
			if (preview != null && preview.animOffsets.exists(currentAnim))
			{
				final off = preview.animOffsets.get(currentAnim);
				ghost.addOffset(animToPlay, off[0], off[1]);
			}
			ghost.playAnim(animToPlay, true);
		}
	}

	function refreshAnimationList():Void
	{
		animNames = [];
		if (preview != null && preview.animation != null)
		{
			for (n in preview.animation.getNameList()) animNames.push(n);
			animNames.sort(Reflect.compare);
		}
		if (animNames.length == 0) animNames = ['idle-0'];

		final prev = currentAnim;
		var idx = animNames.indexOf(prev);
		if (idx < 0) idx = animNames.indexOf('idle-0');
		if (idx < 0) idx = 0;
		currentAnim = animNames[idx];

		rebuildAnimDropdown(idx);
		replaySelectedAnim();
	}

	function rebuildAnimDropdown(selectedIdx:Int):Void
	{
		final panelW = PANEL_W;
		if (animDropdown != null)
		{
			if (panel.content != null) panel.content.remove(animDropdown, true);
			else
				panel.remove(animDropdown, true);
			animDropdown.destroy();
			animDropdown = null;
		}

		suppressCallbacks = true;
		animDropdown = new UIDropdown(0, 0, panelW, "Animation", animNames, null, selectedIdx, 12);
		animDropdown.camera = camHUD;
		animDropdown.onChange = onAnimationPicked;

		if (panel.content != null) panel.content.insert(3, animDropdown);
		else
			panel.addComponent(animDropdown);

		panel.layoutVertical();
		for (m in panel.content.members) if (m != null) m.camera = camHUD;
		suppressCallbacks = false;
	}

	function syncFields():Void
	{
		if (preview == null) return;
		suppressCallbacks = true;
		syncCharOffsets();

		final cam = (preview.data != null && preview.data.camOffsets != null) ? preview.data.camOffsets : preview.camOffsets;
		camXStepper.value = Std.int(cam != null && cam.length > 0 ? cam[0] : 0);
		camYStepper.value = Std.int(cam != null && cam.length > 1 ? cam[1] : 0);

		final extra = preview.data != null ? preview.data.extraOffsets : null;
		extraXStepper.value = Std.int(extra != null && extra.length > 0 ? extra[0] : 0);
		extraYStepper.value = Std.int(extra != null && extra.length > 1 ? extra[1] : 0);

		final sc = (preview.data != null && preview.data.scale != null) ? preview.data.scale : 1;
		scaleStepper.value = Std.int(Math.round(sc * 100));
		suppressCallbacks = false;
	}

	function syncCharOffsets():Void
	{
		if (preview == null) return;
		final off = preview.animOffsets.exists(currentAnim) ? preview.animOffsets.get(currentAnim) : null;
		offsetXStepper.value = Std.int(off != null ? off[0] : 0);
		offsetYStepper.value = Std.int(off != null ? off[1] : 0);
	}

	function applyAnimOffset():Void
	{
		if (suppressCallbacks || preview == null) return;
		final ox = offsetXStepper.value;
		final oy = offsetYStepper.value;
		preview.addOffset(currentAnim, ox, oy);
		final data = preview.getAnimData(currentAnim);
		if (data != null)
		{
			data.x = ox;
			data.y = oy;
		}
		if (preview.data != null && preview.data.animations != null)
		{
			for (a in preview.data.animations)
			{
				if (a != null && a.name == currentAnim)
				{
					a.x = ox;
					a.y = oy;
					break;
				}
			}
		}

		replaySelectedAnim();
	}

	function applyCamOffsets():Void
	{
		if (suppressCallbacks || preview == null) return;
		preview.camOffsets = [camXStepper.value, camYStepper.value];
		if (preview.data != null) preview.data.camOffsets = [camXStepper.value, camYStepper.value];
		updtCamMarker();
	}

	function applyExtraOffsets():Void
	{
		if (suppressCallbacks || preview == null) return;
		if (preview.data != null) preview.data.extraOffsets = [extraXStepper.value, extraYStepper.value];
		repositionChars();
		updtCamMarker();
	}

	function applyScale():Void
	{
		if (suppressCallbacks || preview == null) return;
		final s = scaleStepper.value / 100.0;
		if (preview.data != null) preview.data.scale = s;

		applyCharacterTransform(preview, s);

		if (ghost != null) applyCharacterTransform(ghost, s);

		repositionChars();
		updtCamMarker();
		replaySelectedAnim();
	}

	function repositionChars():Void
	{
		final group = roleGroup(currentRoleIndex);
		if (group == null) return;

		if (preview != null) preview.setPosition(
			group.x + (extraXStepper != null ? extraXStepper.value : 0),
			group.y + (extraYStepper != null ? extraYStepper.value : 0)
		);
		if (ghost != null && ghostGroup != null)
		{
			final ge = (ghost.data != null && ghost.data.extraOffsets != null) ? ghost.data.extraOffsets : [0.0, 0.0];
			ghost.setPosition(ghostGroup.x + (ge.length > 0 ? ge[0] : 0), ghostGroup.y + (ge.length > 1 ? ge[1] : 0));
		}
	}

	function roleGroup(index:Int):FlxSpriteGroup
	{
		return switch (index)
		{
			case 0:
				stage.opponents;
			case 1:
				stage.players;
			default:
				stage.spectators;
		};
	}

	function findCharInGroup(group:FlxSpriteGroup):Character
	{
		if (group == null) return null;
		for (m in group.members) if (m != null && Std.isOfType(m, Character) && m != ghost) return cast m;
		return null;
	}

	function clearStagePreview(clearGhost:Bool = true):Void
	{
		for (g in [stage.opponents, stage.players, stage.spectators])
		{
			if (g == null) continue;
			var i = g.members.length - 1;
			while (i >= 0)
			{
				final m = g.members[i];
				if (m != null && Std.isOfType(m, Character) && m != ghost)
				{
					g.remove(m, true);
					m.destroy();
				}
				i--;
			}
		}
		preview = null;
		if (clearGhost && ghost != null)
		{
			ghost.destroy();
			ghost = null;
			ghostGroup = null;
		}
	}

	function updateMarkersPos():Void
	{
		for (i in 0...roleMarkers.length)
		{
			final pos = rolePositions[i];
			roleMarkers[i].setPosition(pos[0] - 12, pos[1] - 12);
			roleLabels[i].setPosition(pos[0] - 40, pos[1] - 28);
		}
	}

	function getCamPos():FlxPoint
	{
		if (preview == null) return FlxPoint.get(0, 0);
		final mid = preview.getMidpoint();
		final px = mid.x + ((preview.camOffsets != null && preview.camOffsets.length > 0) ? preview.camOffsets[0] : 0.0) + roleCamOffsets[currentRoleIndex][0];
		final py = mid.y + ((preview.camOffsets != null && preview.camOffsets.length > 1) ? preview.camOffsets[1] : 0.0) + roleCamOffsets[currentRoleIndex][1];
		mid.put();
		return FlxPoint.get(px, py);
	}

	function updtCamMarker():Void
	{
		if (preview == null || camFocusMarker == null) return;
		final pos = getCamPos();
		camFocusMarker.setPosition(pos.x, pos.y);
		camFocusLabel.setPosition(pos.x - 60, pos.y - 28);
		pos.put();
	}

	function replaySelectedAnim():Void
	{
		if (preview == null) return;
		preview.playAnim(currentAnim, true);
		if (ghostFollowMode) syncGhostPose();
	}

	function mouseOverPanel():Bool
	{
		if (panelBg == null) return false;
		return FlxG.mouse.viewY >= panelBg.x;
	}

	function togglePreviewMode(?forceOn:Bool):Void
	{
		previewMode = forceOn ?? !previewMode;
		hudVisibility(!previewMode);

		infoText.color = FlxColor.WHITE;
		infoText.text = previewMode ? 'Preview mode is ACTIVE! Press P or ESC to stop.' : 'Role: ${ROLE_LABELS[currentRoleIndex]} • "$currentChar"';
	}

	function hudVisibility(v:Bool):Void
	{
		// LOLL wait lemme do this correctly, I was setting each object individually cus I wanted to keep
		// some shit visible
		// but uhmm I'll just separate the camera lol I think that works far better
		camHUD.visible = v;
	}

	function saveChar():Void
	{
		#if sys
		if (preview == null || preview.data == null || currentChar == '')
		{
			infoText.text = "Nothing to save.";
			infoText.color = UITheme.ACCENT;
			return;
		}
		final path = Paths.getPath('characters/$currentChar/data.json');
		sys.io.File.saveContent(path, haxe.Json.stringify(preview.data, null, "\t"));
		infoText.text = 'Saved "$currentChar" at $path! :D';
		infoText.color = UITheme.ACCENT;

		Paths.playSFX('toolkit/level-editor/save.wav');
		#end
	}

	override public function update(elapsed:Float):Void
	{
		super.update(elapsed);

		// hmm this kinda sucks lol I should lowk improve it
		if (UIOverlay.layer != null)
		{
			final idx = members.indexOf(UIOverlay.layer);
			if (idx >= 0 && idx != members.length - 1)
			{
				members.splice(idx, 1);
				members.push(UIOverlay.layer);
			}
		}

		if (FlxG.sound.music != null && FlxG.sound.music.playing) conductor.time = FlxG.sound.music.time;
		updtCamMarker();

		if (!UIDropdown.isAnyOpen() && UIEditFocus.current == null)
		{
			if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S) saveChar();

			if (FlxG.keys.justPressed.F5)
			{
				saveChar();
				FlxG.resetState();
				return;
			}

			if (FlxG.keys.justPressed.G)
			{
				if (FlxG.keys.pressed.SHIFT)
				{
					ghostFollowMode = !ghostFollowMode;
					if (ghostFollowMode) syncGhostPose();
					infoText.text = 'Ghost Follow: ${ghostFollowMode ? "ON (live)" : "OFF (frozen)"}';
					infoText.color = UITheme.ACCENT;
				}
				else
					updateGhost();
			}

			if (FlxG.keys.justPressed.P) togglePreviewMode();
		}

		if (previewMode && MoonInput.justPressed(BACK)) togglePreviewMode(false);
		else if (!previewMode && MoonInput.justPressed(BACK) && !UIDropdown.isAnyOpen() && UIEditFocus.current == null)
		{
			if (FlxG.sound.music != null) FlxG.sound.music.stop();
			FlxG.switchState(() -> new moon.menus.MainMenu());
		}

		if (previewMode && preview != null)
		{
			final targetZoom = (stage != null && stage.cameraSettings != null) ? (stage.cameraSettings.zoom ?? 1) : 1;
			camGAME.zoom = FlxMath.lerp(camGAME.zoom, targetZoom, elapsed * 4);

			final pos = getCamPos();
			camGAME.scroll.x = FlxMath.lerp(camGAME.scroll.x, pos.x - FlxG.width * 0.5 / camGAME.zoom, elapsed * 4);
			camGAME.scroll.y = FlxMath.lerp(camGAME.scroll.y, pos.y - FlxG.height * 0.5 / camGAME.zoom, elapsed * 4);
			pos.put();
		}

		if (!previewMode && !mouseOverPanel() && !UIDropdown.isAnyOpen())
		{
			// stole this from old syobon action advance lmaoooo
			if (FlxG.mouse.pressedRight || FlxG.mouse.pressedMiddle)
			{
				if (!camDragging)
				{
					camDragging = true;
					lastMousePos.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
				}
				else
				{
					camGAME.scroll.x -= (FlxG.mouse.viewX - lastMousePos.x) / camGAME.zoom;
					camGAME.scroll.y -= (FlxG.mouse.viewY - lastMousePos.y) / camGAME.zoom;
					lastMousePos.set(FlxG.mouse.viewX, FlxG.mouse.viewY);
				}
			}
			else
				camDragging = false;

			if (FlxG.mouse.wheel != 0)
			{
				final zoomFactor = FlxG.mouse.wheel > 0 ? 1.12 : (1 / 1.12);
				final oldZoom = camGAME.zoom;
				camGAME.zoom = FlxMath.bound(oldZoom * zoomFactor, ZOOM_MIN, ZOOM_MAX);

				final mx = FlxG.mouse.viewX;
				final my = FlxG.mouse.viewY;
				camGAME.scroll.x += mx / oldZoom - mx / camGAME.zoom;
				camGAME.scroll.y += my / oldZoom - my / camGAME.zoom;
			}
		}
		else if (!FlxG.mouse.pressedRight && !FlxG.mouse.pressedMiddle) camDragging = false;

		// what?
		// trace(UIDropdown.isAnyOpen());
		// oh huh, nvm i guess.
		if (!previewMode && preview != null && !UIDropdown.isAnyOpen() && UIEditFocus.current == null)
		{
			final step = FlxG.keys.pressed.SHIFT ? 10 : 1;
			var dx = 0;
			var dy = 0;
			if (FlxG.keys.justPressed.RIGHT) dx = -step;
			if (FlxG.keys.justPressed.LEFT) dx = step;
			if (FlxG.keys.justPressed.DOWN) dy = -step;
			if (FlxG.keys.justPressed.UP) dy = step;

			if (dx != 0 || dy != 0)
			{
				suppressCallbacks = true;
				offsetXStepper.value = offsetXStepper.value + dx;
				offsetYStepper.value = offsetYStepper.value + dy;
				suppressCallbacks = false;
				applyAnimOffset();
			}

			// UHMMMMMM...!!!
			if ((FlxG.keys.justPressed.Q || FlxG.keys.justPressed.E) && animNames.length > 0)
			{
				var idx = animNames.indexOf(currentAnim);
				if (idx < 0) idx = 0;

				idx += FlxG.keys.justPressed.E ? 1 : -1;

				if (idx < 0) idx = animNames.length - 1;
				if (idx >= animNames.length) idx = 0;

				currentAnim = animNames[idx];

				rebuildAnimDropdown(idx);
				syncCharOffsets();
				replaySelectedAnim();
			}

			if (FlxG.keys.justPressed.ONE) setRole(0);
			if (FlxG.keys.justPressed.TWO) setRole(1);
			if (FlxG.keys.justPressed.THREE) setRole(2);
			if (FlxG.keys.justPressed.SPACE) replaySelectedAnim();
		}
	}

	override public function destroy():Void
	{
		lastMousePos.put();
		clearStagePreview();
		super.destroy();
	}
}
