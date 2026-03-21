package moon.toolkit.level_editor;

import moon.toolkit.level_editor.LevelEditor.EventInfo;
import moon.game.events.EventRegistry;
import moon.game.events.EventFieldDef;
import openfl.Lib;
import openfl.ui.MouseCursor;
import openfl.ui.Mouse;

class Library extends FlxGroup
{
    public var bg:MoonSprite;
    public var bgCopy:MoonSprite;
    public var bg2:MoonSprite;
    public var tabIndicator:FlxText;

    public var editing:Bool = false;
    public var selectedInfo:Null<EventInfo> = null;

    public var currentEventTag(default, null):String = null;

    public var isFormScrollRegion(get, never):Bool;
    inline function get_isFormScrollRegion():Bool
    {
        if (!_form.isVisible) return false;
        final mx = FlxG.mouse.viewX;
        final my = FlxG.mouse.viewY;

        return mx >= _bg2ScreenX && mx <= _bg2ScreenX + bg2.width && my >= _bg2ScreenY + DETAIL_HEADER_H && my <= _bg2ScreenY + bg2.height;
    }

    private var content:FlxSpriteGroup;
    private var camLibrary:MoonCamera;
    private var scrollValue:Float = 0;
    private var totalContentHeight:Float = 0;
    private var maxScroll:Float = 0;
    private var scrollBarBg:MoonSprite;
    private var scrollBarThumb:MoonSprite;
    private var dragOffset:Null<Float> = null;

    private var _form:EventFormUI = new EventFormUI();
    private var _bg2ScreenX:Float = 0;
    private var _bg2ScreenY:Float = 0;

    // Layout stuffies
    private static inline final PAD:Float = 16;
    private static inline final SPACING:Float = 16;
    private static inline final ITEM_SIZE:Float      = 32;
    private static inline final SCROLL_BAR_WIDTH:Int = 10;
    private static inline final MIN_THUMB_HEIGHT:Int = 16;
    private static inline final DETAIL_HEADER_H:Float = 64;
    private static inline final FORM_H_PAD:Float = 12;

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

        camLibrary = new MoonCamera(Std.int(bg2.x), Std.int(bg2.y), Std.int(bg2.width), Std.int(bg2.height));
        camLibrary.bgColor = 0x00000000;
        FlxG.cameras.add(camLibrary, false);

        content = new FlxSpriteGroup();
        content.camera = camLibrary;
        add(content);

        scrollBarBg = new MoonSprite(bg2.x + bg2.width - SCROLL_BAR_WIDTH, bg2.y)
            .makeGraphic(SCROLL_BAR_WIDTH, Std.int(bg2.height), FlxColor.BLACK);
        scrollBarBg.alpha = 0.5;
        add(scrollBarBg);

        scrollBarThumb = new MoonSprite(0, 0)
            .makeGraphic(SCROLL_BAR_WIDTH, Std.int(MIN_THUMB_HEIGHT), FlxColor.WHITE);
        scrollBarThumb.alpha = 0.6;
        add(scrollBarThumb);

        _bg2ScreenX = bg2.x;
        _bg2ScreenY = bg2.y;
    }

    public function getConfiguredValues():Dynamic
    {
        if (_form.isVisible) return _form.getValues();
        return {};
    }

    override public function update(elapsed:Float)
    {
        super.update(elapsed);

        if (bgCopy.shader != null)
        {
            var shader:BorderGlowShader = cast bgCopy.shader;
            shader.update(elapsed);
            shader.enabled = editing;
        }

        if (!isFormScrollRegion && scrollBarBg.visible && FlxG.mouse.overlaps(bg2))
        {
            if (FlxG.mouse.wheel != 0)
            {
                scrollValue -= FlxG.mouse.wheel * 30;
                scrollValue = FlxMath.bound(scrollValue, 0, maxScroll);
                updateThumbPosition();
            }
        }

        if (scrollBarThumb.visible)
            if (FlxG.mouse.justPressed && FlxG.mouse.overlaps(scrollBarThumb))
                dragOffset = FlxG.mouse.viewY - scrollBarThumb.y;

        if (FlxG.mouse.pressed && dragOffset != null)
        {
            scrollBarThumb.y = FlxG.mouse.viewY - dragOffset;
            scrollBarThumb.y = FlxMath.bound(
                scrollBarThumb.y, scrollBarBg.y,
                scrollBarBg.y + bg2.height - scrollBarThumb.height
            );
            scrollValue = (scrollBarThumb.y - scrollBarBg.y)
                / (bg2.height - scrollBarThumb.height) * maxScroll;
        }

        if (FlxG.mouse.justReleased) dragOffset = null;

        camLibrary.scroll.set(bg2.x, bg2.y + scrollValue);

        // interactions
        final mouseWorld:FlxPoint = FlxG.mouse.getWorldPosition(camLibrary);

        if (selectedInfo == null)
        {
            for (member in content.members)
            {
                if (Std.isOfType(member, EventSpr))
                {
                    if (member.overlapsPoint(mouseWorld, false))
                    {
                        member.alpha = 1;
                        if (FlxG.mouse.justPressed)
                        {
                            selectedInfo = cast(member, EventSpr).info;
                            refreshLibrary();
                            break;
                        }
                    }
                    else member.alpha = 0.5;
                }
            }
        }
        else
        {
            for (member in content.members)
            {
                if (member.ID == 9999)
                {
                    if (member.overlapsPoint(mouseWorld, false))
                    {
                        member.alpha = 1;
                        if (FlxG.mouse.justPressed)
                        {
                            selectedInfo = null;
                            refreshLibrary();
                            break;
                        }
                    }
                    else member.alpha = 0.5;
                }
            }
        }

        if (selectedInfo != null && FlxG.mouse.justPressed && FlxG.mouse.overlaps(tabIndicator))
        {
            selectedInfo = null;
            refreshLibrary();
        }
    }

    public function refreshLibrary():Void
    {
        content.clear();
        scrollValue = 0;
        _form.hide();

        final curType = LevelEditor.instance.curType;

        if (selectedInfo == null)
        {
            // browse mode
            currentEventTag = null;
            tabIndicator.text = 'Library // ${curType}';

            var col:Int = 0;
            var row:Int = 0;
            final columns:Int = Math.floor(
                (bg2.width - 2 * PAD - SCROLL_BAR_WIDTH + SPACING) / (ITEM_SIZE + SPACING)
            );

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

                col++;
                if (col >= columns) { col = 0; row++; }
            }

            totalContentHeight = PAD + (row + (col > 0 ? 1 : 0)) * (ITEM_SIZE + SPACING)
                - (row > 0 ? SPACING : 0) + PAD;
            maxScroll = Math.max(0, totalContentHeight - bg2.height);
            _updateScrollbar();
        }
        else
        {
            // detail / configure mode
            currentEventTag = selectedInfo.name;
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

            var descTxt:FlxText = new FlxText(
                backBtn.x + backBtn.width + PAD, 0,
                bg2.width - backBtn.width - PAD * 2 - SCROLL_BAR_WIDTH,
                selectedInfo.description
            );
            descTxt.setFormat(Paths.font('Inconsolata-Black.ttf'), 14, LEFT);
            descTxt.antialiasing = true;
            content.add(descTxt);
            descTxt.y = backBtn.y + backBtn.height / 2 - descTxt.height / 2;

            final fields:Array<EventFieldDef> = EventRegistry.getEditorFields(selectedInfo.name);

            if (fields.length > 0)
            {
                final scale = _screenScale();
                _form.show(fields, (_bg2ScreenX + FORM_H_PAD) * scale.x, (_bg2ScreenY + DETAIL_HEADER_H) * scale.y, (bg2.width - FORM_H_PAD * 2 - SCROLL_BAR_WIDTH) * scale.x, (bg2.height - DETAIL_HEADER_H - 8) * scale.y);
            }

            totalContentHeight = DETAIL_HEADER_H;
            maxScroll = 0;
            _updateScrollbar();
        }
    }

    override public function destroy():Void
    {
        _form.hide();
        super.destroy();
    }

    private function _updateScrollbar():Void
    {
        maxScroll = Math.max(0, totalContentHeight - bg2.height);
        final show = maxScroll > 0;
        scrollBarBg.visible = show;
        scrollBarThumb.visible = show;

        if (show)
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

    private function updateThumbPosition():Void
        scrollBarThumb.y = scrollBarBg.y
            + (scrollValue / maxScroll) * (bg2.height - scrollBarThumb.height);

    private inline function _screenScale():{x:Float, y:Float}
    {
        final sw = openfl.Lib.current.stage.stageWidth;
        final sh = openfl.Lib.current.stage.stageHeight;
        return {
            x: sw / Constants.GAME_WIDTH,
            y: sh / Constants.GAME_HEIGHT
        };
    }
}
