package moon.dependency.scripting;

import flixel.FlxState;

/**
 * A scripted state, which loads up using a script as well.
 * Highly inspired on Codename Engine.
 */
class MoonScriptedState extends FlxState
{
	// alright uhhh let's begin ts

	/**
	 * The script this state uses.
	 */
	public var script:MoonScript = new MoonScript();

	/**
	 * The state's name.
	 */
	public var stateName:String;

	/**
	 * Loads a state from a script.
	 * @param stateName The state's name (which is also the script's name).
	 */
	public function new(stateName:String)
	{
		super();
		script.load('data/states/$stateName.hx');
		script.set('state', this);
		script.set('add', this.add);
		script.set('remove', this.remove);
		script.set('insert', this.insert);
		script.set('bgColor', this.bgColor);
		this.stateName = stateName;
	}

	@:inheritDoc(FlxState.create)
	override public function create():Void
	{
		script.call('onCreate');
		super.create();
		script.call('onPostCreate');
	}

	/**
	 * Called when the game is updated each frame.
	 * @param elapsed 
	 */
	override public function update(elapsed:Float)
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

	@:inheritDoc(FlxState.onFocus)
	override public function onFocus()
	{
		super.onFocus();
		script.call('onFocus');
	}

	@:inheritDoc(FlxState.onFocusLost)
	override public function onFocusLost()
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

	override public function toString():String return 'SCRIPTED STATE: $stateName with ${members.length} members.';
}
