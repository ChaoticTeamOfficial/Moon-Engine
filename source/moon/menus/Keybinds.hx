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
import flixel.group.FlxSpriteGroup;
import flixel.FlxSprite;
import flixel.input.FlxInput.FlxInputState;
import moon.dependency.user.MoonInput.MoonKeys;

using StringTools;

class Keybinds extends FlxSubState
{
    private var curSelection:Int = 0;
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

    private var menuContainer:FlxSpriteGroup;
    private var leftItems:Array<FlxText> = [];
    private var rightItems:Array<FlxText> = [];
    private var lineItems:Array<FlxSprite> = [];

    public function new(camera:FlxCamera):Void
    {
        super();
        this.camera = camera;

        menuContainer = new FlxSpriteGroup();
        add(menuContainer);

        removeHoldTime = 0;
        allButtons = [];
        for (key in FlxPad.fromStringMap.keys())
        {
            final id:FlxPad = FlxPad.fromString(key);
            if (id != FlxPad.ANY && id != FlxPad.NONE)
                allButtons.push(id);
        }
       
        // build headers and sections
        addHeader("Notes");
        final noteControls = ["LEFT", "DOWN", "UP", "RIGHT", "RESET"];
        final noteLabels = ["← Left (First Key)", "↓ Down (Second Key)", "↑ Up (Third Key)", "→ Right (Fourth Key)", 'Reset'];

        for (i in 0...noteControls.length)
            addKeyItem(noteControls[i], noteLabels[i]);

        addHeader("UI");
        final uiControls = ["UI_LEFT", "UI_DOWN", "UI_UP", "UI_RIGHT", "ACCEPT", "BACK", "PAUSE"];
        final uiLabels = ["Left", "Down", "Up", "Right", "Accept", "Cancel", "Pause"];

        for (i in 0...uiControls.length)
            addKeyItem(uiControls[i], uiLabels[i]);

        var pos:Float = 0;
        for (i in 0...leftItems.length)
        {
            if (headerIndices.contains(i) && headerIndices.indexOf(i) > 0)
                pos += EXTRA_CATEGORY_SPACING;

            positionOffsets.push(pos);

            leftItems[i].y = pos;
            rightItems[i].y = pos;

            pos += LINE_SPACING;
        }

        // Shitty headers
        for (j in 0...lineItems.length)
            lineItems[j].y = leftItems[headerIndices[j]].y + leftItems[headerIndices[j]].height + 32;

        refreshList();
        changeSelection(0);

        menuContainer.y = (FlxG.height / 2 - offsetY) - positionOffsets[selectableIndices[0]];
    }
   
    override public function update(elapsed:Float):Void
    {
        super.update(elapsed);

        // Navigation / rebind input
        if (rebindMode) handleRebinding(elapsed);
        else
        {
            if (MoonInput.justPressed(UI_UP)) changeSelection(-1);
            else if (MoonInput.justPressed(UI_DOWN)) changeSelection(1);
            if (MoonInput.justPressed(ACCEPT)) openRebindMode();
            else if (MoonInput.justPressed(BACK)) close();
            else if (FlxG.keys.justPressed.TAB)
            {
                showKeyboard = !showKeyboard;
                refreshList();
            }
        }

        final selectedIndex = selectableIndices[curSelection];
        var targetY:Float = FlxG.height / 2 - offsetY - positionOffsets[selectedIndex];
        menuContainer.y = FlxMath.lerp(menuContainer.y, targetY, elapsed * 6);

        for (i in 0...leftItems.length)
        {
            var col = (i == selectedIndex) ? FlxColor.CYAN : FlxColor.WHITE;
            leftItems[i].color = col;
            rightItems[i].color = col;
        }
    }

    private function refreshList():Void
    {
        for (i in 0...controlNames.length)
        {
            var keyStrings:Array<String> = [];
            for (k in MoonInput.binds.get(controlNames[i])[showKeyboard ? 0 : 1])
                keyStrings.push(showKeyboard ? getKeyString(k) : getGamepadString(k));
            rightItems[selectableIndices[i]].text = keyStrings.join(', ');
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

    final headerFont = Paths.font('HoltwoodOne.ttf');
    final font = Paths.font('vcr.ttf');
    private function addHeader(label:String):Void
    {
        var headerText = new FlxText(50, 0, 400, label);
        headerText.setFormat(headerFont, 32, FlxColor.WHITE, LEFT);
        menuContainer.add(headerText);
        leftItems.push(headerText);

        var emptyBind = new FlxText(500, 0, 700, "");
        emptyBind.setFormat(font, 32, FlxColor.WHITE, LEFT);
        menuContainer.add(emptyBind);
        rightItems.push(emptyBind);

        var line = new FlxSprite(20, 0).makeGraphic(FlxG.width - 40, 1, FlxColor.WHITE);
        menuContainer.add(line);
        lineItems.push(line);

        headerIndices.push(leftItems.length - 1);
    }

    private function addKeyItem(control:String, label:String):Void
    {
        if (!MoonInput.binds.exists(control)) return;

        var actionText = new FlxText(50, 0, 400, label);
        actionText.setFormat(font, 32, FlxColor.WHITE, LEFT);
        menuContainer.add(actionText);
        leftItems.push(actionText);

        var bindText = new FlxText(500, 0, 700, "");
        bindText.setFormat(font, 32, FlxColor.WHITE, LEFT);
        menuContainer.add(bindText);
        rightItems.push(bindText);

        selectableIndices.push(leftItems.length - 1);
        controlNames.push(control);
    }

    private function getKeyString(key:FlxKey):String
    {
        return switch(key)
        {
            case LEFT: '←';
            case DOWN: '↓';
            case UP: '↑';
            case RIGHT: '→';
            case ENTER: "Enter";
            case SPACE: "Space";
            case BACKSPACE: "Backspace";
            case ESCAPE: "Esc"; // not even possible lmfao but whatever
            case TAB: "Tab";
            default: key.toString().replace("_", " ");
        };
    }

    private function getGamepadString(gamepadKey:FlxPad):String
        return gamepadKey.toString().replace("_", " ");
}