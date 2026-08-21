package moon.toolkit.level_editor;

import moon.toolkit.ui.*;
import moon.game.events.EventFieldDef;

using StringTools;

class EventFormUI extends UIScrollPage
{
	private var _fields:Array<EventFieldDef>;
	private var _dynamicFields:Array<EventFieldDef>;
	private var _dynamicFieldNames:Array<String>;
	private var _widgets:Map<String, UIComponent>;
	private var _initialValues:Dynamic;
	private var _showRunOnLoadToggle:Bool;
	private var _runOnLoadCheckbox:UICheckbox;
	private var _dynamicFieldsProvider:String->Array<EventFieldDef>;

	public function new(x:Float, y:Float, w:Float, h:Float, fields:Array<EventFieldDef>, ?initialValues:Dynamic, showRunOnLoadToggle:Bool = false, runOnLoadDefault:Bool = true, ?dynamicFieldsProvider:String->
		Array<EventFieldDef>)
	{
		super(x, y, w, h);

		visible = true;
		active = true;

		_fields = fields ?? [];
		_dynamicFields = [];
		_dynamicFieldNames = [];
		_widgets = [];
		_initialValues = initialValues;
		_showRunOnLoadToggle = showRunOnLoadToggle;
		_dynamicFieldsProvider = dynamicFieldsProvider;

		for (field in _fields) _buildRow(field);

		if (_dynamicFieldsProvider != null)
		{
			final controllerValue = _getControllerValue();
			if (controllerValue != null) _rebuildDynamicFields(controllerValue);
		}

		if (_showRunOnLoadToggle)
		{
			_runOnLoadCheckbox = new UICheckbox(0, 0, viewWidth, "Start after loading song", runOnLoadDefault);
			addComponent(_runOnLoadCheckbox);
		}

		layoutVertical();
	}

	private function _buildRow(field:EventFieldDef, isDynamic:Bool = false):Void
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
				widget = new UISlider(0, 0, viewWidth, field.label, min, max, defVal, step);

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
				if (field.controlsDynamicFields == true && _dynamicFieldsProvider != null) dd.onChange = (val) -> _rebuildDynamicFields(val);
				widget = dd;

			case CHECKBOX:
				final isChecked = hasOverride ? (overrideVal == true) : ((field.defaultValue != null) ? (field.defaultValue == true) : false);
				widget = new UICheckbox(0, 0, viewWidth, field.label, isChecked);

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
				widget = new UIColorPicker(0, 0, viewWidth, field.label, col);
		}

		if (widget != null)
		{
			_widgets.set(field.name, widget);
			addComponent(widget);
			if (isDynamic) _dynamicFieldNames.push(field.name);
		}
	}

	private function _getControllerValue():Null<String>
	{
		for (field in _fields)
		{
			if (field.controlsDynamicFields != true) continue;
			final w = _widgets.get(field.name);
			if (w == null || !Std.isOfType(w, UIDropdown)) continue;
			final dd:UIDropdown = cast w;
			if (dd.selectedIndex >= 0 && dd.selectedIndex < dd.options.length) return dd.options[dd.selectedIndex];
			return field.defaultValue != null ? Std.string(field.defaultValue) : null;
		}
		return null;
	}

	private function _rebuildDynamicFields(selectedValue:String):Void
	{
		for (name in _dynamicFieldNames)
		{
			final w = _widgets.get(name);
			if (w != null)
			{
				content.remove(w, true);
				w.destroy();
				_widgets.remove(name);
			}
		}
		_dynamicFieldNames = [];
		_dynamicFields = [];

		if (_runOnLoadCheckbox != null) content.remove(_runOnLoadCheckbox, true);

		if (_dynamicFieldsProvider != null)
		{
			_dynamicFields = _dynamicFieldsProvider(selectedValue) ?? [];
			for (field in _dynamicFields) _buildRow(field, true);
		}

		if (_runOnLoadCheckbox != null) addComponent(_runOnLoadCheckbox);

		layoutVertical();
	}

	public function getRunOnLoad():Bool return (_runOnLoadCheckbox != null) ? _runOnLoadCheckbox.checked : false;

	public function setRunOnLoad(v:Bool):Void if (_runOnLoadCheckbox != null) _runOnLoadCheckbox.checked = v;

	public function getValues():Dynamic
	{
		var result:Dynamic = {};
		for (field in _fields) _writeFieldValue(result, field);
		for (field in _dynamicFields) _writeFieldValue(result, field);
		return result;
	}

	private function _writeFieldValue(result:Dynamic, field:EventFieldDef):Void
	{
		final w = _widgets.get(field.name);
		if (w == null) return;

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
				Reflect.setField(result, field.name, cast(w, UIColorPicker).value.toWebString());
		}
	}

	public function dispose():Void
	{
		destroy();
	}

	override public function destroy():Void
	{
		super.destroy();
		_widgets = [];
		_dynamicFields = [];
		_dynamicFieldNames = [];
		_runOnLoadCheckbox = null;
		_dynamicFieldsProvider = null;
	}
}
