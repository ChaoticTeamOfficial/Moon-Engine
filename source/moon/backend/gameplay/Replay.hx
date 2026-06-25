package moon.backend.gameplay;

/**
 * A replay input event.
 */
typedef ReplayInput =
{
	/**
	 * The song time the event happened.
	 */
	var time:Float;

	/**
	 * The note direction.
	 */
	var dir:Int;

	/**
	 * Whether it's a press or a release.
	 */
	var press:Bool;

	/**
	 * The judgement string at the time of the hit.
	 */
	var judgement:Null<String>;
};

/**
 * A class that contains replay info.
 */
class Replay
{
	public var song:String;
	public var difficulty:String;
	public var mix:String;
	public var inputs:Array<ReplayInput> = [];
	public var filename:String = '';
	public var displayName:String = '';
	public var date:Dynamic;
	public var stats:PlayerStats;

	public function new(song:String, difficulty:String, mix:String)
	{
		this.song = song;
		this.difficulty = difficulty;
		this.mix = mix;
	}

	public function toString():String return '(${mix.toUpperCase()}) $song on ${difficulty.toUpperCase()}';
}
