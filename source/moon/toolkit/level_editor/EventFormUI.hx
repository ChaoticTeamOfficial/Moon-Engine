package moon.toolkit.level_editor;

import flixel.util.FlxColor;
import moon.toolkit.ui.*;
import moon.game.events.EventFieldDef;

using StringTools;

// TODO: document
class EventFormUI extends UIScrollPage
{
	private var _fields:Array<EventFieldDef>;
	private var _widgets:Map<String, UIComponent>;
	private var _initialValues:Dynamic;

	public function new(x:Float, y:Float, w:Float, h:Float, fields:Array<EventFieldDef>, ?initialValues:Dynamic)
	{
		super(x, y, w, h);

		visible = true;
		active = true;

		_fields = fields ?? [];
		_widgets = [];
		_initialValues = initialValues;

		for (field in _fields) _buildRow(field);

		layoutVertical();
	}

	private function _buildRow(field:EventFieldDef):Void
	{
		final hasOverride = _initialValues != null && Reflect.hasField(_initialValues, field.name);
		final overrideVal:Dynamic = hasOverride ? Reflect.field(_initialValues, field.name) : null;

		var widget:UIComponent = null;
		switch (field.type)
		{
			case TEXT:
				var tb = new UITextBox(0, 0, viewWidth, field.label);
				tb.text = hasOverride ? Std.string(overrideVal) : ((field.defaultValue != null) ? Std.string(field.defaultValue) : '');
				widget = tb;

			case NUMBER:
				final min = field.min ?? 0;
				final max = field.max ?? 100;
				final step = field.step ?? 1;
				final defVal = hasOverride ? Std.parseFloat(
					Std.string(overrideVal)
				) : ((field.defaultValue != null) ? Std.parseFloat(Std.string(field.defaultValue)) : min);
				var sl = new UISlider(0, 0, viewWidth, field.label, min, max, defVal, step);
				widget = sl;

			case DROPDOWN:
				final opts = field.options ?? [];
				final wanted = hasOverride ? Std.string(overrideVal) : ((field.defaultValue != null) ? Std.string(field.defaultValue) : null);
				var startIndex = 0;
				if (wanted != null)
				{
					final idx = opts.indexOf(wanted);
					if (idx >= 0) startIndex = idx;
				}
				var dd = new UIDropdown(0, 0, viewWidth, field.label, opts, null, startIndex);
				widget = dd;

			case CHECKBOX:
				final isChecked = hasOverride ? (overrideVal == true) : ((field.defaultValue != null) ? (field.defaultValue == true) : false);
				var cb = new UICheckbox(0, 0, viewWidth, field.label, isChecked);
				widget = cb;

			case COLOR:
				final raw:Dynamic = hasOverride ? overrideVal : field.defaultValue;
				var col:FlxColor = FlxColor.WHITE;
				if (raw != null)
				{
					if (Std.isOfType(raw, String))
					{
						var colorStr:String = cast raw;
						if (!colorStr.startsWith("#")) colorStr = "#" + colorStr;
						col = FlxColor.fromString(colorStr);
					}
					else
						col = Std.int(raw);
				}
				var cp = new UIColorPicker(0, 0, viewWidth, field.label, col);
				widget = cp;
		}

		if (widget != null)
		{
			_widgets.set(field.name, widget);
			addComponent(widget);
		}
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
					Reflect.setField(result, field.name, cast(w, UITextBox).text);
				case NUMBER:
					Reflect.setField(result, field.name, cast(w, UISlider).value);
				case DROPDOWN:
					final dd = cast(w, UIDropdown);
					final val = (
						dd.selectedIndex >= 0
						&& dd.selectedIndex < dd.options.length
					) ? dd.options[dd.selectedIndex] : Std.string(field.defaultValue ?? '');
					Reflect.setField(result, field.name, val);
				case CHECKBOX:
					Reflect.setField(result, field.name, cast(w, UICheckbox).checked);
				case COLOR:
					final cp = cast(w, UIColorPicker);
					final colorValue = "#" + StringTools.hex(cp.value, 6);
					Reflect.setField(result, field.name, colorValue);
			}
		}
		return result;
	}

	public function dispose():Void
	{
		destroy();
	}

	override public function destroy():Void
	{
		super.destroy();
		_widgets = [];
	}
}
