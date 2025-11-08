package moon.menus;

import flixel.util.FlxTimer;
import flixel.FlxCamera;
import flixel.FlxSubState;
import flixel.FlxG;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.math.FlxMath;
import flixel.input.gamepad.FlxGamepad;
import flixel.input.gamepad.FlxGamepadInputID as FlxPad;
import flixel.input.keyboard.FlxKey;
import flixel.effects.FlxFlicker;
import flixel.group.FlxGroup;
import flixel.FlxSprite;
import flixel.input.FlxInput.FlxInputState;
import moon.dependency.user.MoonInput.MoonKeys;

using StringTools;

class Keybinds extends FlxSubState
{
    private var curSelection:Int = 0;
    private var keysGrp:FlxTypedGroup<FlxText>;
    private var bindTextsGrp:FlxTypedGroup<FlxText>;
    private var linesGrp:FlxTypedGroup<FlxSprite>;

    private var selectableIndices:Array<Int> = [];
    private var headerIndices:Array<Int> = [];
    private var controlNames:Array<String> = [];

    private var positionOffsets:Array<Float> = [];
    private var rebindMode:Bool = false;
    private var showKeyboard:Bool = true;

    private var removeHoldTime:Float = 0;
    private var offsetY:Float = 200;
    private var allButtons:Array<FlxPad>;

    private static inline var MAX_BINDS:Int = 5;
    private static inline var INITIAL_REMOVE_DELAY:Float = 0.5;
    private static inline var REPEAT_REMOVE_DELAY:Float = 0.05;
    private static inline var LINE_SPACING:Float = 60;
    private static inline var EXTRA_CATEGORY_SPACING:Float = 90;

    public function new(camera:FlxCamera):Void
    {
        super();
        this.camera = camera;
        keysGrp = new FlxTypedGroup<FlxText>();
        bindTextsGrp = new FlxTypedGroup<FlxText>();
        linesGrp = new FlxTypedGroup<FlxSprite>();
        removeHoldTime = 0;
        allButtons = [];
        for (key in FlxPad.fromStringMap.keys())
        {
            var id:FlxPad = FlxPad.fromString(key);
            if (id != FlxPad.ANY && id != FlxPad.NONE)
                allButtons.push(id);
        }
        
        // build headers and sectionssss
        addHeader("Notes");
        final noteControls = ["LEFT", "DOWN", "UP", "RIGHT", "RESET"];
        final noteLabels = ["Left (First Key)", "Down (Second Key)", "Up (Third Key)", "Right (Fourth Key)", 'Reset'];
        final arrows = ['←', '↓', '↑', '→', ''];
        for (i in 0...noteControls.length)
            addKeyItem(noteControls[i], arrows[i] + ' ' + noteLabels[i]);

        addHeader("UI");
        var uiControls = ["UI_UP", "UI_DOWN", "UI_LEFT", "UI_RIGHT", "ACCEPT", "BACK", "PAUSE"];
        var uiLabels = ["Up", "Down", "Left", "Right", "Accept", "Cancel", "CharScreen"];
        for (i in 0...uiControls.length)
            addKeyItem(uiControls[i], uiLabels[i]);

        // Add lines for headers omg they suck (lie)
        for (j in 0...headerIndices.length)
            linesGrp.add(new FlxSprite(20, 0).makeGraphic(FlxG.width - 40, 1, FlxColor.WHITE));

        add(keysGrp);
        add(bindTextsGrp);
        add(linesGrp);

        var pos:Float = 0;
        for (i in 0...keysGrp.length)
        {
            if (headerIndices.contains(i) && headerIndices.indexOf(i) > 0)
                pos += EXTRA_CATEGORY_SPACING;

            positionOffsets.push(pos);
            pos += LINE_SPACING;
        }

        refreshList();
        changeSelection(0);
    }
    
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);
        updateTextPositions(elapsed);
        if (rebindMode) handleRebinding(elapsed);
        else
        {
            if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
            else if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
            if (MoonInput.justPressed(ACCEPT)) openRebindMode();
            else if (MoonInput.justPressed(BACK)) close();
            else if (FlxG.keys.justPressed.TAB && Global.allowInputs)
            {
                showKeyboard = !showKeyboard;
                refreshList();
            }
        }
    }

    private function refreshList():Void
    {
        for (i in 0...controlNames.length)
        {
            var control = controlNames[i];
            var itemIndex = selectableIndices[i];
            var bindType = showKeyboard ? 0 : 1;
            var keyList:Array<Dynamic> = MoonInput.binds.get(control)[bindType];
            var keyStrings:Array<String> = [];
            for (k in keyList)
                keyStrings.push(showKeyboard ? getKeyString(k) : getGamepadString(k));
            bindTextsGrp.members[itemIndex].text = keyStrings.join(', ');
        }
    }

    private function changeSelection(change:Int = 0):Void
    {
        curSelection = FlxMath.wrap(curSelection + change, 0, controlNames.length - 1);
    }

    private function openRebindMode():Void
    {
        new FlxTimer().start(0.1, (_) -> {
            rebindMode = true;
            removeHoldTime = 0;
        });
    }

    private function handleRebinding(elapsed:Float):Void
    {
        var isKeyboard:Bool = showKeyboard;
        var bindType:Int = isKeyboard ? 0 : 1;
        var control:String = controlNames[curSelection];
        var keyList:Array<Dynamic> = MoonInput.binds.get(control)[bindType];
        var removePressed:Bool = false;
        if (isKeyboard)
            removePressed = FlxG.keys.pressed.BACKSPACE || FlxG.keys.pressed.DELETE;
        else
        {
            if (FlxG.gamepads.lastActive == null)
            {
                rebindMode = false;
                return;
            }
            removePressed = FlxG.gamepads.lastActive.pressed.X;
        }
        if (removePressed)
        {
            if (removeHoldTime == 0)
            {
                if (keyList.length > 0) keyList.pop();
                removeHoldTime = elapsed;
            }
            else removeHoldTime += elapsed;

            if (removeHoldTime > INITIAL_REMOVE_DELAY)
            {
                if (keyList.length > 0) keyList.pop();
                removeHoldTime -= REPEAT_REMOVE_DELAY;
            }
            refreshList();
            MoonInput.saveControls();
        }
        else removeHoldTime = 0;
        if (isKeyboard)
        {
            final keyCode:Int = FlxG.keys.firstJustPressed();
            if (keyCode != -1)
            {
                var key:FlxKey = keyCode;
                if (key == FlxKey.ESCAPE)
                    rebindMode = false;

                else if (key != FlxKey.BACKSPACE && key != FlxKey.DELETE)
                {
                    if (keyList.length < MAX_BINDS && !keyList.contains(key))
                    {
                        keyList.push(key);
                        refreshList();
                        MoonInput.saveControls();
                    }
                }
            }
        }
        else // Controller
        {
            var pressedButton:FlxPad = FlxPad.NONE;
            for (button in allButtons)
            {
                if (FlxG.gamepads.lastActive.checkStatus(button, JUST_PRESSED))
                {
                    pressedButton = button;
                    break;
                }
            }
            if (pressedButton != FlxPad.NONE)
            {
                if (pressedButton == FlxPad.B)
                    rebindMode = false;
                else if (pressedButton != FlxPad.X)
                {
                    if (keyList.length < MAX_BINDS && !keyList.contains(pressedButton))
                    {
                        keyList.push(pressedButton);
                        refreshList();
                        MoonInput.saveControls();
                    }
                }
            }
        }
    }

    private function updateTextPositions(elapsed:Float):Void
    {
        final centerY = FlxG.height / 2 - offsetY;
        final selectedIndex = selectableIndices[curSelection];
        final selectedPos = positionOffsets[selectedIndex];
        for (i in 0...keysGrp.length)
        {
            final targetY = centerY + (positionOffsets[i] - selectedPos);
            keysGrp.members[i].y = FlxMath.lerp(keysGrp.members[i].y, targetY, elapsed * 6);
            bindTextsGrp.members[i].y = FlxMath.lerp(bindTextsGrp.members[i].y, targetY, elapsed * 6);
        }

        for (i in 0...keysGrp.length)
        {
            final col = (i == selectedIndex) ? FlxColor.CYAN : FlxColor.WHITE;
            keysGrp.members[i].color = col;
            bindTextsGrp.members[i].color = col;
        }

        for (j in 0...headerIndices.length)
        {
            final headerI = headerIndices[j];
            linesGrp.members[j].y = keysGrp.members[headerI].y + keysGrp.members[headerI].height + 16;
            linesGrp.members[j].x = 20;
        }
    }

    private function addHeader(label:String):Void
    {
        var headerText = new FlxText(50, 0, 400, label);
        headerText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, LEFT);
        keysGrp.add(headerText);

        var emptyBind = new FlxText(500, 0, 700, "");
        emptyBind.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, LEFT);
        bindTextsGrp.add(emptyBind);
        headerIndices.push(keysGrp.length - 1);
    }

    private function addKeyItem(control:String, label:String):Void
    {
        if (!MoonInput.binds.exists(control)) return;
        var actionText = new FlxText(50, 0, 400, label);
        actionText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, LEFT);
        keysGrp.add(actionText);

        var bindText = new FlxText(500, 0, 700, "");
        bindText.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, LEFT);
        bindTextsGrp.add(bindText);

        selectableIndices.push(keysGrp.length - 1);
        controlNames.push(control);
    }

    private function getKeyString(key:FlxKey):String
    {
        return switch(key)
        {
            case LEFT: "LeftArrow";
            case DOWN: "DownArrow";
            case UP: "UpArrow";
            case RIGHT: "RightArrow";
            case ENTER: "Enter";
            case SPACE: "Space";
            case BACKSPACE: "Backspace";
            case ESCAPE: "Esc";
            case TAB: "Tab";
            default: key.toString().replace("_", " ");
        };
    }
    private function getGamepadString(gamepadKey:FlxPad):String
        return gamepadKey.toString().replace("_", " ");
}