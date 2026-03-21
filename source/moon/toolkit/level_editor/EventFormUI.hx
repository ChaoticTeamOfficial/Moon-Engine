package moon.toolkit.level_editor;

import haxe.ui.components.*;
import haxe.ui.containers.*;
import haxe.ui.core.*;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.UIEvent;
import moon.game.events.EventFieldDef;

class EventFormUI
{
    private var _root:VBox;
    private var _scroll:ScrollView;
    private var _fieldMap:Map<String, Component> = [];

    /** Called whenever any field value changes. **/
    public var onChange:Void->Void;

    public function new() {}

    /**
     * Builds and displays the form.
     * @param fields   Field definitions returned by the event.
     * @param x        Screen X.
     * @param y        Screen Y.
     * @param w        Available width.
     * @param h        Available height.
     * @param values   Pre-populate fields from an existing values object.
     */
    public function show(fields:Array<EventFieldDef>, x:Float, y:Float, w:Float, h:Float, ?values:Dynamic):Void
    {
        hide();
        _fieldMap = [];

        if (fields == null || fields.length == 0) return;
        _root = new VBox();
        _root.left  = x;
        _root.top   = y;
        _root.width = w;
        _root.height = h;
        _clearBg(_root);
        _root.styleString += " padding:0px; spacing:0px;";

        _scroll = new ScrollView();
        _scroll.width  = w;
        _scroll.height = h;
        _clearBg(_scroll);
        // horizontal-scroll:hidden prevents the scroll from expanding or showing a horizontal bar
        _scroll.styleString += " content-width:100%; padding:4px; spacing:6px; horizontal-scroll:hidden;";
        _root.addComponent(_scroll);

        for (field in fields)
            _scroll.addComponent(_buildRow(field, w - 20, values));

        Screen.instance.addComponent(_root);

        _bringToFront();
    }

    /** Returns the current field values as a flat Dynamic object. **/
    public function getValues():Dynamic
    {
        var obj:Dynamic = {};
        for (name => comp in _fieldMap)
        {
            if (Std.isOfType(comp, TextField))
                Reflect.setField(obj, name, cast(comp, TextField).text);
            else if (Std.isOfType(comp, NumberStepper))
                Reflect.setField(obj, name, cast(comp, NumberStepper).value);
            else if (Std.isOfType(comp, DropDown))
            {
                final dd = cast(comp, DropDown);
                Reflect.setField(obj, name, (dd.selectedItem != null) ? dd.selectedItem.text : '');
            }
            else if (Std.isOfType(comp, CheckBox))
                Reflect.setField(obj, name, cast(comp, CheckBox).selected);
        }
        return obj;
    }

    public function hide():Void
    {
        if (_root != null)
        {
            Screen.instance.removeComponent(_root, true);
            _root   = null;
            _scroll = null;
        }
        _fieldMap = [];
    }

    public var isVisible(get, never):Bool;
    inline function get_isVisible():Bool return _root != null;

    private function _buildRow(field:EventFieldDef, totalW:Float, values:Dynamic):HBox
    {
        final LABEL_W:Float = 110;
        // subtract LABEL_W, HBox spacing (8), and extra 16 to stay inside the scroll's padding
        final INPUT_W:Float = totalW - LABEL_W - 24;

        var row = new HBox();
        row.width = totalW;
        _clearBg(row);
        row.styleString += " spacing:8px; vertical-align:center;";

        var lbl = new Label();
        lbl.text  = field.label;
        lbl.width = LABEL_W;
        _clearBg(lbl);
        lbl.styleString += "color:#EBEBEB; font-size:13px; vertical-align:center;";
        row.addComponent(lbl);

        final cur:Dynamic = (values != null && Reflect.hasField(values, field.name))
            ? Reflect.field(values, field.name)
            : field.defaultValue;

        switch (field.type)
        {
            case TEXT:
                var tf = new TextField();
                tf.text = cur != null ? Std.string(cur) : '';
                tf.width = INPUT_W;
                tf.onChange = _cb;
                row.addComponent(tf);
                _fieldMap.set(field.name, tf);

            case NUMBER:
                var ns = new NumberStepper();
                ns.min = field.min ?? Math.NEGATIVE_INFINITY;
                ns.max = field.max ?? Math.POSITIVE_INFINITY;
                ns.step = field.step ?? 1;
                ns.value = cur != null ? Std.parseFloat(Std.string(cur)) : 0;
                ns.width = INPUT_W;
                ns.onChange = _cb;
                row.addComponent(ns);
                _fieldMap.set(field.name, ns);

            case DROPDOWN:
                var dd = new DropDown();
                var ds = new ArrayDataSource<Dynamic>();
                if (field.options != null)
                    for (opt in field.options) ds.add({text: opt});
                    	
                dd.dataSource = ds;
                dd.width = INPUT_W;
                if (cur != null && field.options != null)
                {
                    final idx = field.options.indexOf(Std.string(cur));
                    if (idx >= 0) dd.selectedIndex = idx;
                }
                dd.onChange = _cb;
                row.addComponent(dd);
                _fieldMap.set(field.name, dd);

            case CHECKBOX:
                var cb = new CheckBox();
                cb.selected = (cur == true || cur == 'true');
                cb.onChange = _cb;
                row.addComponent(cb);
                _fieldMap.set(field.name, cb);
        }

        return row;
    }

    private inline function _clearBg(c:Component):Void
    {
        c.customStyle.backgroundColor = 0x000000;
        c.customStyle.backgroundOpacity = 0;
        c.customStyle.borderLeftSize = 0;
        c.customStyle.borderRightSize = 0;
        c.customStyle.borderTopSize = 0;
        c.customStyle.borderBottomSize = 0;
        c.styleString = "background-color:transparent; border:none;";
    }

    private static function _bringToFront():Void
    {
        final state = FlxG.state;
        if (state != null)
        {
            for (m in state.members)
            {
                if (m == null) continue;
                final cls = Type.getClassName(Type.getClass(m));
                if (cls != null && cls.indexOf("haxe.ui") != -1)
                {
                    state.remove(m, true);
                    state.add(m);
                    return;
                }
            }
        }

        try
        {
            final stage = openfl.Lib.current.stage;
            for (i in 0...stage.numChildren)
            {
                final child = stage.getChildAt(i);
                final cls   = Type.getClassName(Type.getClass(child));
                if (cls != null && cls.indexOf("haxeui") != -1)
                {
                    stage.setChildIndex(child, stage.numChildren - 1);
                    return;
                }
            }
        }
        catch (_) {}
    }

    @:noCompletion private function _cb(_:UIEvent):Void
        if (onChange != null) onChange();
}
