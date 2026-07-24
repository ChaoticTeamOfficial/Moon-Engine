package moon.backend;

import lime.app.Event;

@:publicFields
/**
 * Conductor made entirely by [SomeGuyWhoLovesCoding](https://github.com/SomeGuyWhoLovesCoding)
 * Revamped math by [sword_352](https://github.com/Sword352).
 * All I made here was to make some few changes that I am comfortable with, so all credits goes to them.
 */
class Conductor
{
	// -- EVENTS

	/**
	 * An event dispatched once a 'step' is triggered.
	 */
	var onStep:Event<Float->Void> = new Event<Float->Void>();

	/**
	 * An event dispatched once a 'beat' is triggered.
	 */
	var onBeat:Event<Float->Void> = new Event<Float->Void>();

	/**
	 * An event dispatched once a 'measure' is triggered.
	 */
	var onMeasure:Event<Float->Void> = new Event<Float->Void>();

	// -- CROCHET VALUES

	/**
	 * A step crochet's duration. Divide it by 1000 if you use it on tweens.
	 */
	var stepCrochet(default, null):Float = 150;

	/**
	 * A beat crochet's duration. Divide it by 1000 if you use it on tweens.
	 */
	var crochet(default, null):Float = 600;

	/**
	 * A measure crochet's duration. Divide it by 1000 if you use it on tweens.
	 */
	var measureCrochet(default, null):Float = 2400;

	/**
	 * Beats per minute.
	 */
	var bpm(default, null):Float = 100;

	/**
	 * Is the conductor active?
	 */
	var active:Bool;

	/**
	 * The conductor's time position.
	 */
	var time(default, set):Float = 0;

	@:dox(hide)
	private var catchUp:Bool = false;

	@:dox(hide)
	function set_time(value:Float):Float
	{
		time = value;
		final calc = (time - offsetTime);
		_stepTracker = Math.ffloor(stepOffset + calc / stepCrochet);
		_beatTracker = Math.ffloor(beatOffset + calc / crochet);
		_measureTracker = Math.ffloor(measureOffset + calc / measureCrochet);

		if (active)
		{
			if (curStep != _stepTracker)
			{
				final dir = (_stepTracker > curStep) ? 1 : -1;
				if (Math.abs(_stepTracker - curStep) > 8) catchUp = true;

				while (curStep != _stepTracker)
				{
					curStep += dir;
					if (!catchUp) onStep.dispatch(curStep);
				}
				catchUp = false;
			}

			if (curBeat != _beatTracker)
			{
				final dir = (_beatTracker > curBeat) ? 1 : -1;
				if (Math.abs(_beatTracker - curBeat) > 2) catchUp = true;

				while (curBeat != _beatTracker)
				{
					curBeat += dir;
					if (!catchUp) onBeat.dispatch(curBeat);
				}
				catchUp = false;
			}

			if (curMeasure != _measureTracker)
			{
				final dir = (_measureTracker > curMeasure) ? 1 : -1;
				if (Math.abs(_measureTracker - curMeasure) > 1) catchUp = true;

				while (curMeasure != _measureTracker)
				{
					curMeasure += dir;
					if (!catchUp) onMeasure.dispatch(curMeasure);
				}
				catchUp = false;
			}
		}
		else
		{
			curStep = _stepTracker;
			curBeat = _beatTracker;
			curMeasure = _measureTracker;
		}

		return time;
	}

	/**
	 * The current step counter.
	 */
	var curStep(default, null):Float = 0;

	/**
	 * The current beat counter.
	 */
	var curBeat(default, null):Float = 0;

	/**
	 * The current measure counter.
	 */
	var curMeasure(default, null):Float = 0;

	private var _stepTracker(default, null):Float = 0;
	private var _beatTracker(default, null):Float = 0;
	private var _measureTracker(default, null):Float = 0;

	/**
	 * An offset that will be applied to the conductor's time.
	 */
	var offsetTime(default, null):Float = 0;

	/**
	 * An offset that will be applied to the conductor's steps.
	 */
	var stepOffset(default, null):Float = 0;

	/**
	 * An offset that will be applied to the conductor's beats.
	 */
	var beatOffset(default, null):Float = 0;

	/**
	 * An offset that will be applied to the conductor's measures.
	 */
	var measureOffset(default, null):Float = 0;

	/**
	 * Time signature numerator.
	 */
	var numerator:Float = 4;

	/**
	 * Time signature denominator.
	 */
	var denominator:Float = 4;

	private var _initialBpm:Float;
	private var _initialNumerator:Float;
	private var _initialDenominator:Float;

	/**
		Change the conductor's beats per minute.
		This also includes time signatures.
		@param position The position you want to execute the event on.
		@param newBpm The new beats per minute.
		@param newNumerator The new numerator of the time signature.
		@param newDenominator The new denominator of the time signature.
	**/
	inline function changeBpmAt(position:Float, newBpm:Float = 0, newNumerator:Float = 4, newDenominator:Float = 4):Void
	{
		final calc = (position - offsetTime);
		stepOffset += calc / stepCrochet;
		beatOffset += calc / crochet;
		measureOffset += calc / measureCrochet;
		offsetTime = position;

		if (newBpm > 0)
		{
			bpm = newBpm;
			stepCrochet = 60000 / (bpm * 4);
		}

		numerator = newNumerator;
		denominator = newDenominator;

		crochet = stepCrochet * 4;
		measureCrochet = crochet * numerator * (4.0 / denominator);
	}

	/**
		Reset the conductor back to its initial state.
	**/
	inline function reset():Void
	{
		offsetTime = stepOffset = beatOffset = measureOffset = 0.0;
		curStep = curBeat = curMeasure = 0;
		changeBpmAt(0, _initialBpm, _initialNumerator, _initialDenominator);
		time = 0.0;
	}

	/**
		Destroy the conductor and remove all event listeners.
	**/
	inline function destroy():Void
	{
		onStep.removeAll();
		onBeat.removeAll();
		onMeasure.removeAll();
	}

	/**
		Constructs a conductor.
		@param initialBpm The initial beats per minute.
		@param initialNumerator The initial numerator of the time signature.
		@param initialDenominator The initial denominator of the time signature.
	**/
	function new(initialBpm:Float = 100, initialNumerator:Float = 4, initialDenominator:Float = 4):Void
	{
		_initialBpm = initialBpm;
		_initialNumerator = initialNumerator;
		_initialDenominator = initialDenominator;
		changeBpmAt(0, initialBpm, initialNumerator, initialDenominator);
		active = true;
	}

	// other

	/**
	 * Converts a given time (in ms) into the step it falls on.
	 * @param t The time to convert.
	 * @return Float
	 */
	inline function getStepAtTime(t:Float):Float
	{
		return stepOffset + (t - offsetTime) / stepCrochet;
	}
}
