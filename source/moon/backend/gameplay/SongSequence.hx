package moon.backend.gameplay;

typedef Sequence =
{
	/**
	 * The sequence's position in milliseconds.
	 */
	var ?time:Float;

	/**
	 * The sequence's position by step.
	 */
	var ?step:Float;

	/**
	 * The sequence's position by beat.
	 */
	var ?beat:Float;

	/**
	 * The callback in which will be executed as soon as this sequence is triggered.
	 */
	var callback:Void->Void;
};
/*class SongSequence
	{
	public var sequences:Array<Sequence> = [];

	public function new(?sequences:Array<Sequence>)
	{
		this.sequences = sequences ?? [];
	}
	}
 */
