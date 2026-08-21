package moon.toolkit.level_editor;

import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.game.events.EventRegistry;
import moon.game.notetypes.NoteTypeRegistry;

class Library extends FlxGroup
{
	public var bg:MoonSprite;
	public var bgCopy:MoonSprite;
	public var bg2:MoonSprite;
	public var tabIndicator:FlxText;
	public var editing:Bool = false;
	public var selectedInfo:Null<EventInfo> = null;
	public var editingValues:Dynamic = null;

	private var content:FlxSpriteGroup;
	private var contentBaseY:Map<FlxBasic, Float> = [];
	private var scrollValue:Float = 0;
	private var totalContentHeight:Float = 0;
	private var maxScroll:Float = 0;
	private var scrollBarBg:MoonSprite;
	private var scrollBarThumb:MoonSprite;
	private var dragOffset:Null<Float> = null;

	public var form:EventFormUI = null;

	private static inline final PAD:Float = 16;
	private static inline final SPACING:Float = 16;
	private static inline final ITEM_SIZE:Float = 32;
	private static inline final SCROLL_BAR_WIDTH:Int = 10;
	private static inline final MIN_THUMB_HEIGHT:Int = 16;

	public function new()
	{
		super();

		final bgSize:FlxPoint = FlxPoint.get(532, 263);
		bg = new MoonSprite(116, FlxG.height - 300).makeGraphic(Std.int(bgSize.x), Std.int(bgSize.y), FlxColor.TRANSPARENT);
		add(bg);
		FlxSpriteUtil.drawRoundRect(bg, 0, 0, Std.int(bgSize.x), Std.int(bgSize.y), 24, 24, FlxColor.BLACK);
		bg.antialiasing = true;
		bg.alpha = 0.4;
		bg.active = false;

		bgCopy = new MoonSprite(bg.x, bg.y).makeGraphic(Std.int(bg.width), Std.int(bg.height), FlxColor.TRANSPARENT);
		bgCopy.shader = new BorderGlowShader();
		add(bgCopy);
		bgCopy.blend = ADD;
		bgCopy.active = false;

		bg2 = new MoonSprite().makeGraphic(Std.int(bg.width - 32), Std.int(bg.height / 1.5 + 16), FlxColor.TRANSPARENT);
		add(bg2);
		FlxSpriteUtil.drawRoundRect(bg2, 0, 0, bg2.width, bg2.height, 24, 24, FlxColor.BLACK);
		bg2.antialiasing = true;
		bg2.alpha = 0.3;
		bg2.active = false;
		bg2.setPosition(bg.x + bg.width / 2 - bg2.width / 2, bg.y + bg.height / 2 - bg2.height / 2 + 16);

		var icon = new MoonSprite(bg.x, bg.y - 6);
		icon.frames = Tilemap.getAtlasFrames("btnIcons");
		icon.frame = Tilemap.getFrame('library', 'btnIcons');
		icon.active = false;
		icon.antialiasing = true;
		icon.setGraphicSize(32, 32);
		add(icon);

		tabIndicator = new FlxText(bg.x + 48, bg.y + 16);
		add(tabIndicator);
		tabIndicator.setFormat(Paths.font('Inconsolata-Black.ttf'), 16, LEFT);
		tabIndicator.text = 'Loading...';
		tabIndicator.antialiasing = true;

		content = new FlxSpriteGroup();
		add(content);

		scrollBarBg = new MoonSprite(bg2.x + bg2.width - SCROLL_BAR_WIDTH, bg2.y).makeGraphic(SCROLL_BAR_WIDTH, Std.int(bg2.height), FlxColor.BLACK);
		scrollBarBg.alpha = 0.5;
		add(scrollBarBg);

		scrollBarThumb = new MoonSprite(0, 0).makeGraphic(SCROLL_BAR_WIDTH, Std.int(MIN_THUMB_HEIGHT), FlxColor.WHITE);
		scrollBarThumb.alpha = 0.6;
		add(scrollBarThumb);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		if (!visible) return;

		if (bgCopy.shader != null)
		{
			var shader:BorderGlowShader = cast bgCopy.shader;
			shader.update(elapsed);
			shader.enabled = editing;
		}

		if (scrollBarBg.visible && FlxG.mouse.overlaps(bg2))
		{
			if (FlxG.mouse.wheel != 0)
			{
				scrollValue -= FlxG.mouse.wheel * 30;
				scrollValue = FlxMath.bound(scrollValue, 0, maxScroll);
				updateThumbPosition();
				_applyScroll();
			}
		}

		if (scrollBarThumb.visible && FlxG.mouse.justPressed && FlxG.mouse.overlaps(scrollBarThumb)) dragOffset = FlxG.mouse.viewY - scrollBarThumb.y;

		if (FlxG.mouse.pressed && dragOffset != null)
		{
			scrollBarThumb.y = FlxMath.bound(FlxG.mouse.viewY - dragOffset, scrollBarBg.y, scrollBarBg.y + bg2.height - scrollBarThumb.height);
			scrollValue = (scrollBarThumb.y - scrollBarBg.y) / (bg2.height - scrollBarThumb.height) * maxScroll;
			_applyScroll();
		}

		if (FlxG.mouse.justReleased) dragOffset = null;

		_updateClipRects();

		if (selectedInfo == null)
		{
			for (member in content.members)
			{
				if (!Std.isOfType(member, EventSpr)) continue;
				if (member.overlapsPoint(FlxG.mouse.getViewPosition(), false))
				{
					member.alpha = 1;
					if (FlxG.mouse.justPressed)
					{
						editing = false;
						editingValues = null;
						selectedInfo = cast(member, EventSpr).info;
						refreshLibrary();
						break;
					}
				}
				else
					member.alpha = 0.5;
			}
		}
		else
		{
			for (member in content.members)
			{
				if (member.ID != 9999) continue;
				if (member.overlapsPoint(FlxG.mouse.getViewPosition(), false))
				{
					member.alpha = 1;
					if (FlxG.mouse.justPressed)
					{
						_exitEditOrSel();
						break;
					}
				}
				else
					member.alpha = 0.5;
			}
		}

		if (selectedInfo != null && FlxG.mouse.justPressed && FlxG.mouse.overlaps(tabIndicator)) _exitEditOrSel();
	}

	private function _exitEditOrSel():Void
	{
		editing = false;
		editingValues = null;
		selectedInfo = null;
		LevelEditor.instance.deselectEditTargets();
		refreshLibrary();
	}

	public function refreshLibrary():Void
	{
		_clearForm();
		content.clear();
		contentBaseY.clear();
		scrollValue = 0;
		final curType = LevelEditor.instance.curType;

		if (selectedInfo == null)
		{
			tabIndicator.text = 'Library // ${curType}';

			var col:Int = 0;
			var row:Int = 0;
			final columns:Int = Math.floor((bg2.width - 2 * PAD - SCROLL_BAR_WIDTH + SPACING) / (ITEM_SIZE + SPACING));

			for (info in LevelEditor.instance.loadedEvents.get(curType))
			{
				var spr:EventSpr = new EventSpr(info.name, info.category);
				spr.info = info;
				spr.setGraphicSize(Std.int(ITEM_SIZE), Std.int(ITEM_SIZE));
				spr.updateHitbox();
				spr.antialiasing = false;
				spr.active = false;
				spr.alpha = 0.5;

				spr.x = bg2.x + PAD + col * (ITEM_SIZE + SPACING);
				spr.y = bg2.y + PAD + row * (ITEM_SIZE + SPACING);

				content.add(spr);
				contentBaseY.set(spr, spr.y);

				col++;
				if (col >= columns)
				{
					col = 0;
					row++;
				}
			}

			totalContentHeight = PAD + (row + (col > 0 ? 1 : 0)) * (ITEM_SIZE + SPACING) - (row > 0 ? SPACING : 0) + PAD;
			maxScroll = Math.max(0, totalContentHeight - bg2.height);

			final showScroll = maxScroll > 0;
			scrollBarBg.visible = showScroll;
			scrollBarThumb.visible = showScroll;

			if (showScroll)
			{
				scrollBarThumb.makeGraphic(
					SCROLL_BAR_WIDTH,
					Std.int(Math.max(MIN_THUMB_HEIGHT, (bg2.height / totalContentHeight) * bg2.height)),
					FlxColor.WHITE
				);
				scrollBarThumb.x = scrollBarBg.x;
				updateThumbPosition();
			}
		}
		else
		{
			tabIndicator.text = 'Library // ${curType} // ${selectedInfo.name}';

			var backBtn:MoonSprite = new MoonSprite(bg2.x + 16, bg2.y + PAD);
			backBtn.frames = Tilemap.getAtlasFrames("btnIcons");
			backBtn.frame = Tilemap.getFrame('arrowBack', 'btnIcons');
			backBtn.setGraphicSize(32, 32);
			backBtn.updateHitbox();
			backBtn.antialiasing = true;
			backBtn.alpha = 0.5;
			backBtn.active = false;
			backBtn.ID = 9999;
			content.add(backBtn);
			contentBaseY.set(backBtn, backBtn.y);

			var descTxt:FlxText = new FlxText(
				backBtn.x + backBtn.width + PAD,
				0,
				bg2.width - backBtn.width - SCROLL_BAR_WIDTH - PAD,
				selectedInfo.description
			);
			descTxt.setFormat(Paths.font('Inconsolata-Black.ttf'), 16, LEFT);
			descTxt.antialiasing = true;
			content.add(descTxt);
			descTxt.y = backBtn.y + backBtn.height / 2 - descTxt.height / 2;
			contentBaseY.set(descTxt, descTxt.y);

			final headerH = Math.max(backBtn.height, descTxt.height);
			totalContentHeight = PAD + headerH + PAD;
			maxScroll = 0;
			scrollBarBg.visible = false;
			scrollBarThumb.visible = false;

			final formY = bg2.y + PAD + headerH + 8;
			final fields = (curType == NOTES) ? NoteTypeRegistry.getEditorFields(selectedInfo.name) : EventRegistry.getEditorFields(selectedInfo.name);
			final dynamicProvider = (curType == NOTES) ? null : EventRegistry.getDynamicFieldsProvider(selectedInfo.name);

			form = new EventFormUI(
				bg2.x + 8,
				formY,
				bg2.width - 16,
				(bg2.y + bg2.height) - formY - 8,
				fields,
				editingValues, curType != NOTES && (selectedInfo.canRunOnCreate ?? true),
				false,
				dynamicProvider
			);
			add(form);
		}

		_applyScroll();
	}

	private function _applyScroll():Void
	{
		for (member in content.members)
		{
			if (!Std.isOfType(member, FlxSprite)) continue;
			cast(member, FlxSprite).y = (contentBaseY.get(member) ?? cast(member, FlxSprite).y) - scrollValue;
		}
		_updateClipRects();
	}

	private function _updateClipRects():Void
	{
		final clipBounds = FlxRect.get(0, bg2.y, bg2.width, bg2.height);
		for (member in content.members)
		{
			if (!Std.isOfType(member, FlxSprite) || cast(member, FlxSprite).ID == 9999) continue;
			final spr:FlxSprite = cast member;
			final sprTop = spr.y;
			final sprBottom = spr.y + spr.height;
			final clipTop = bg2.y;
			final clipBottom = bg2.y + bg2.height;

			if (sprBottom <= clipTop || sprTop >= clipBottom)
			{
				spr.visible = false;
				continue;
			}

			spr.visible = true;
			final visTop = Math.max(sprTop, clipTop);
			final visBottom = Math.min(sprBottom, clipBottom);
			spr.clipRect = FlxRect.get(0, visTop - sprTop, spr.width, visBottom - visTop);
		}
		clipBounds.put();
	}

	private function _clearForm():Void
	{
		if (form == null) return;
		remove(form, true);
		form.dispose();
		form = null;
	}

	private function updateThumbPosition():Void scrollBarThumb.y = scrollBarBg.y + (scrollValue / maxScroll) * (bg2.height - scrollBarThumb.height);

	override public function destroy():Void
	{
		_clearForm();
		super.destroy();
	}
}
