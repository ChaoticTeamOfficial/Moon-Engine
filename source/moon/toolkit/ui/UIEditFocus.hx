package moon.toolkit.ui;

/**
 * Implemented by any control that can accept typed keyboard input.
 */
interface ITextEditable
{
	function blurEdit():Void;
}

/**
 * Implemented by any control that draws transient "editor chrome".
 */
interface IEditorChromeHideable
{
	function forceHideEditorChrome():Void;
}

/**
 * Global single-owner for "something is currently accepting typed keyboard
 * input", shared by every editable control.
 */
class UIEditFocus
{
	public static var current:ITextEditable;

	public static function request(target:ITextEditable):Void
	{
		if (current == target) return;

		if (current != null) current.blurEdit();
		current = target;

		if (openfl.Lib.current.stage.window != null) openfl.Lib.current.stage.window.textInputEnabled = target != null;
		if (target != null) openfl.Lib.current.stage.focus = openfl.Lib.current.stage;
	}

	/** 
	 * Releases ownership only if `target` is the one that currently holds it.
	 */
	public static function release(target:ITextEditable):Void if (current == target) request(null);
}
