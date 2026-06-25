package moon.backend.data;

using StringTools;

/**
 * Structure for a Dialogue Line.
**/
typedef DialogueLine =
{
	/**
	 * The character who's speaking.
	 */
	var ?character:String;

	/**
	 * The expression a character will do.
	 */
	var ?expression:String;

	/**
	 * The text displayed when a character speaks.
	 */
	var text:String;

	/**
	 * The text's speed.
	 */
	var ?speed:Float;

	/**
	 * The event that'll execute on this dialogue line (if exists.)
	 */
	var ?events:Array<DialogueEvent>;

	/**
	 * Color that overrides the character's one if exists.
	 */
	var ?color:Array<Int>;

	/**
	 * The tweened animation the portrait will do.
	 */
	var ?anim:moon.game.obj.dialogue.Portrait.PortraitAnim;
}

/**
 * Structure for a Dialogue Event.
**/
typedef DialogueEvent =
{
	/**
	 * Character range in the line that this event affects.
	 * Inclusive start, exclusive end.
	 */
	var ?range:
		{start:Int, end:Int};

	/**
	 * The event's name.
	 */
	var name:String;

	/**
	 * The event's values.
	 */
	var values:Dynamic;
}

/**
 * Structure for a Dialogue File.
 */
typedef DialogueFile =
{
	/**
	 * All the lines a dialogue can have.
	 */
	lines:Array<DialogueLine>
}

@:publicFields
@:forward
/**
 * This abstract basically loads a dialogue file and returns it.
 */
abstract Dialogue(DialogueFile) from DialogueFile to DialogueFile
{
	/**
	 * Gets a dialogue file and returns its data.
	 * @param dialogueFile the Path to the dialogue file (Paths usage is not needed.)
	 */
	static function getDialogue(dialogueFile:String):Dialogue
	{
		if (Paths.exists('$dialogueFile.json')) return Paths.JSON(dialogueFile);

		trace('[DIALOGUE] $dialogueFile.json was not found.', "ERROR");
		return null;
	}
}

/**
 * Class used for parsing dialogue tag events. I won't write it's documentation that much because it's very... complicated.
 * Plus I don't see why modders would need it soo... if you're reading this, my apologies :(
**/
class DialogueParser
{
	/**
	 * Parses a text containing event to a certain structure (text, events)
	 * tagSchema maps tagName -> Array<paramNames>.
	 */
	public static function parseTaggedText(text:String, ?tagSchema:Map<String, Array<String>> = null):
		{text:String, events:Array<DialogueEvent>}
	{
		var events:Array<DialogueEvent> = [];
		var cleanText = new StringBuf();
		var cleanPos = 0;

		// stack to track open tags
		var stack:Array<
			{name:String, argsStr:String, start:Int}> = [];

		// regex to match <tag>, <tag=...>, </tag>, <tag/...> and such!
		// it took... me a few researches to figure this out.
		// it truly seems more confusing than what it is
		final tagRegex = ~/<(\/?)([\w-]+)(?:=([^>]*?))?(\/?)>/g;

		var pos = 0;
		var lastEnd = 0;

		while (tagRegex.matchSub(text, pos))
		{
			final matchPos = tagRegex.matchedPos();
			final fullTag = tagRegex.matched(0);
			final isClosing = tagRegex.matched(1) == "/";
			final tagName = tagRegex.matched(2).trim();
			final argsStr = (tagRegex.matched(3) != null) ? tagRegex.matched(3).trim() : "";
			final isSelfClosing = tagRegex.matched(4) == "/";

			// Add text before this tag
			var textBefore = text.substring(lastEnd, matchPos.pos);
			cleanText.add(textBefore);
			cleanPos += textBefore.length;

			if (isClosing)
			{
				// find matching opening tag
				var openIdx = -1;
				for (i in 0...stack.length)
				{
					if (stack[stack.length - 1 - i].name == tagName)
					{
						openIdx = stack.length - 1 - i;
						break;
					}
				}

				if (openIdx != -1)
				{
					final open = stack.splice(openIdx, 1)[0];
					events.push({
						range: {
							start: open.start,
							end: cleanPos
						},
						name: open.name,
						values: parseTagValues(open.name, open.argsStr, tagSchema)
					});
				}
				// it should hopefully ignore unmatched closed tags?
			}
			else
			{
				// opening or self-closing tag
				var open = {
					name: tagName,
					argsStr: argsStr,
					start: cleanPos
				};

				if (isSelfClosing)
				{
					events.push({
						range: {
							start: cleanPos,
							end: cleanPos
						},
						name: tagName,
						values: parseTagValues(tagName, argsStr, tagSchema)
					});
				}
				else
					stack.push(open);
			}

			pos = matchPos.pos + matchPos.len;
			lastEnd = pos;
		}

		// add remaining text after last tag
		final remaining = text.substring(lastEnd);
		cleanText.add(remaining);
		cleanPos += remaining.length;

		// close any unclosed tags at the end
		for (open in stack)
		{
			events.push({
				range: {
					start: open.start,
					end: cleanPos
				},
				name: open.name,
				values: parseTagValues(open.name, open.argsStr, tagSchema)
			});
		}

		return {
			text: cleanText.toString(),
			events: events
		};
	}

	private static function parseTagValues(name:String, argsStr:String, tagSchema:Map<String, Array<String>>):Dynamic
	{
		if (argsStr == null || argsStr.length == 0) return null;

		var rawArgs = argsStr.split(",").map(s -> s.trim());
		var values:Array<Dynamic> = [];

		for (arg in rawArgs)
		{
			var num = Std.parseFloat(arg);
			values.push((num == num && arg != "NaN") ? num : arg);
		}

		// if schema exists, convert to named object
		if (tagSchema != null && tagSchema.exists(name))
		{
			var paramNames = tagSchema.get(name);
			var obj:Dynamic = {};
			for (i in 0...values.length) Reflect.setField(obj, (i < paramNames.length) ? paramNames[i] : 'arg$i', values[i]);

			return obj;
		}

		// otherwise return array or single value
		return (values.length == 1) ? values[0] : values;
	}
}
