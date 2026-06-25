package;

import moon.game.obj.*;
import moon.game.*;

@:publicFields
/**
 * A class which provides "shortcut" access to certain functions or variables
 * across the game easily.
 * For example, instead of doing:
 * `PlayState.instance.stage.opponents.members[0]`
 * You will now be able to:
 * `Shortcuts.getOpponent(0)`
 */
class Shortcuts
{
	// --- GAMEPLAY RELATED SHORTCUTS

	/**
	 * Returns a opponent from the game's stage.
	 * @param index The index value. 0 is the first member in it.
	 */
	static function getOpponent(index:Int = 0):Character
	{
		final char = PlayState.instance.stage.opponents.members[index];
		if (Std.isOfType(char, Character)) return cast char;

		trace('[SHORTCUTS] $index at opponents is not a Character!', "ERROR");
		return null;
	}

	/**
	 * Returns a player from the game's stage.
	 * @param index The index value. 0 is the first member in it.
	 */
	static function getPlayer(index:Int = 0):Character
	{
		final char = PlayState.instance.stage.players.members[index];
		if (Std.isOfType(char, Character)) return cast char;

		trace('[SHORTCUTS] $index at players is not a Character!', "ERROR");
		return null;
	}

	/**
	 * Returns a spectator from the game's stage.
	 * @param index The index value. 0 is the first member in it.
	 */
	static function getSpectator(index:Int = 0):Character
	{
		final char = PlayState.instance.stage.spectators.members[index];
		if (Std.isOfType(char, Character)) return cast char;

		trace('[SHORTCUTS] $index at spectators is not a Character!', "ERROR");
		return null;
	}

	/**
	 * Returns a `PlayerStats` from the playfield.
	 * @param player The player name. Must match all the available players in playfield. (opponent counts as one.)
	 */
	static function getStats(player:String = 'p1'):moon.backend.gameplay.PlayerStats return PlayField.instance.inputHandlers.get(player).stats;

	/**
	 * Returns chart content from the game's PlayField.
	 */
	static function getChart():moon.backend.data.Chart.ChartStruct return PlayField.instance.chart.content;
}
