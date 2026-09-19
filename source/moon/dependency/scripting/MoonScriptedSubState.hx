package moon.dependency.scripting;

/**
 * A scripted substate, which loads up using a script.
 */
class MoonScriptedSubState extends FlxSubState
{
	public var script:MoonScript = new MoonScript();
	public var stateName:String;

	/**
	 * @param stateName The substate's name (which is also the script's name).
	 * @param args Optional arguments that will be passed to the script's `onCreate` function.
	 */
	public function new(stateName:String, ?args:Array<Dynamic>)
	{
		super();
		this.stateName = stateName;

		script.load('data/substates/$stateName.hx');
		script.set('state', this);
		script.set('add', this.add);
		script.set('remove', this.remove);
		script.set('insert', this.insert);
		script.set('bgColor', this.bgColor);
		script.set('close', this.close);
		script.set('openSubState', this.openSubState);

		if (args != null) script.set('args', args);
	}

	override public function create():Void
	{
		script.call('onCreate');
		super.create();
		script.call('onPostCreate');
	}

	override public function update(elapsed:Float):Void
	{
		script.call('onUpdate', [elapsed]);
		super.update(elapsed);
		script.call('onPostUpdate', [elapsed]);
	}

	/**
	 * Called when the state is "killed".
	 */
	override public function kill()
	{
		super.kill();
		script.call('kill');
	}

	/**
	 * Called when the state is destroyed.
	 */
	override public function destroy()
	{
		super.destroy();
		script.call('destroy');
	}

	/**
	 * Called on every draw call.
	 */
	override public function draw()
	{
		super.draw();
		script.call('draw');
	}

	override public function close():Void
	{
		script.call('onClose');
		super.close();
	}

	override public function onFocus():Void
	{
		super.onFocus();
		script.call('onFocus');
	}

	override public function onFocusLost():Void
	{
		super.onFocusLost();
		script.call('onFocusLost');
	}

	@:inheritDoc(FlxState.onResize)
	override public function onResize(width:Int, height:Int)
	{
		super.onResize(width, height);
		script.call('onResize', [width, height]);
	}

	override public function toString():String return 'SCRIPTED SUBSTATE: $stateName';
}
