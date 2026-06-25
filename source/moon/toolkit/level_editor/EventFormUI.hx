package moon.toolkit.level_editor;

import haxe.ui.components.*;
import haxe.ui.components.popups.*;
import haxe.ui.containers.*;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import moon.game.events.EventFieldDef;

using StringTools;

// TODO: document

/**
 * A class that handles how events should look like in the library!
 * Basically, it takes the events editable fields and converts to haxeui stuff!!
 */
class EventFormUI
{
	public var root:VBox;

	private var _scroll:ScrollView;
	private var _placeBtn:Button;
	private var _fields:Array<EventFieldDef>;
	private var _widgets:Map<String, Component>;

	static inline final BTN_H:Float = 32;
	static inline final GAP:Float = 32;

	private var _initialValues:Dynamic;

	public function new(x:Float, y:Float, w:Float, h:Float, fields:Array<EventFieldDef>, ?initialValues:Dynamic)
	{
		_fields = fields ?? [];
		_widgets = [];
		_initialValues = initialValues;

		_scroll = new ScrollView();
		_scroll.left = x;
		_scroll.top = y;
		_scroll.width = w;
		_scroll.height = h - BTN_H + GAP;

		_scroll.styleString = "background-color: #0d0c0d; border: none; padding: 0;";

		root = new VBox();
		root.width = w - 32;
		root.styleString = "background-color: #0d0c0d; border: none; padding: 4px; spacing: 5px;";
		_scroll.addComponent(root);

		for (field in _fields) _buildRow(field);

		Screen.instance.addComponent(_scroll);
	}

	private function _buildRow(field:EventFieldDef):Void
	{
		var row = new HBox();
		row.width = root.width;
		row.styleString = "spacing: 6px;";

		var lbl = new Label();
		lbl.text = field.label;
		lbl.width = 108;
		lbl.styleString = "font-size: 12px; color: #cccccc; vertical-align: center;";
		row.addComponent(lbl);

		final hasOverride = _initialValues != null && Reflect.hasField(_initialValues, field.name);
		final overrideVal:Dynamic = hasOverride ? Reflect.field(_initialValues, field.name) : null;

		var widget:Component = null;
		switch (field.type)
		{
			case TEXT:
				var tf = new TextField();
				tf.text = hasOverride ? Std.string(overrideVal) : ((field.defaultValue != null) ? Std.string(field.defaultValue) : '');
				tf.percentWidth = 100;
				widget = tf;

			case NUMBER:
				var ns = new NumberStepper();
				ns.value = hasOverride ? Std.parseFloat(
					Std.string(overrideVal)
				) : ((field.defaultValue != null) ? Std.parseFloat(Std.string(field.defaultValue)) : 0);
				if (field.min != null) ns.min = field.min;
				if (field.max != null) ns.max = field.max;
				if (field.step != null) ns.step = field.step;
				ns.percentWidth = 100;
				widget = ns;

			case DROPDOWN:
				var dd = new DropDown();
				dd.percentWidth = 100;
				if (field.options != null) for (opt in field.options) dd.dataSource.add({
					text: opt
				});

				final wanted = hasOverride ? Std.string(overrideVal) : ((field.defaultValue != null) ? Std.string(field.defaultValue) : null);
				if (wanted != null && field.options != null)
				{
					final idx = field.options.indexOf(wanted);
					if (idx >= 0) dd.selectedIndex = idx;
				}
				widget = dd;

			case CHECKBOX:
				var cb = new CheckBox();
				cb.selected = hasOverride ? (overrideVal == true) : ((field.defaultValue != null) ? (field.defaultValue == true) : false);
				widget = cb;

			case COLOR:
				var colorP = new ColorPickerPopup();
				colorP.percentWidth = 100;
				colorP.liveTracking = true;

				final raw:Dynamic = hasOverride ? overrideVal : field.defaultValue;
				if (raw != null)
				{
					var colorStr:String = null;
					if (Std.isOfType(raw, String))
					{
						colorStr = cast raw;
						if (!colorStr.startsWith("#")) colorStr = "#" + colorStr;
					}
					else
						colorStr = "#" + StringTools.hex(Std.int(raw), 6);

					if (colorStr != null) colorP.selectedItem = haxe.ui.util.Color.fromString(colorStr);
				}

				widget = colorP;
		}

		if (widget != null)
		{
			_widgets.set(field.name, widget);
			row.addComponent(widget);
		}

		root.addComponent(row);
	}

	public function getValues():Dynamic
	{
		var result:Dynamic = {};
		for (field in _fields)
		{
			final w = _widgets.get(field.name);
			if (w == null) continue;

			switch (field.type)
			{
				case TEXT:
					Reflect.setField(result, field.name, cast(w, TextField).text);
				case NUMBER:
					Reflect.setField(result, field.name, cast(w, NumberStepper).value);
				case DROPDOWN:
					final dd = cast(w, DropDown);
					Reflect.setField(result, field.name, (dd.selectedItem != null) ? dd.selectedItem.text : Std.string(field.defaultValue ?? ''));
				case CHECKBOX:
					Reflect.setField(result, field.name, cast(w, CheckBox).selected);
				case COLOR:
					// Reflect.setField(result, field.name, Std.int(cast(w, ColorPicker).currentColor));
					final colorP = cast(w, ColorPickerPopup);
					var colorValue:Dynamic = null;

					if (colorP.selectedItem != null)
					{
						final col = colorP.selectedItem;
						colorValue = "#" + StringTools.hex(col, 6);
					}
					else
						colorValue = "#FFFFFF";

					Reflect.setField(result, field.name, colorValue);
			}
		}
		return result;
	}

	public function dispose():Void
	{
		if (_scroll != null)
		{
			Screen.instance.removeComponent(_scroll);
			_scroll = null;
		}
		if (_placeBtn != null)
		{
			Screen.instance.removeComponent(_placeBtn);
			_placeBtn = null;
		}
		root = null;
		_widgets = [];
	}
}
