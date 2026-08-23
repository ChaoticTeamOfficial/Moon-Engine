from dataclasses import dataclass
from Options import Toggle, DefaultOnToggle, Choice, Range, DeathLink, PerGameCommonOptions


class UnlockMode(Choice):
    """What the main progression items unlock.
    Songs = individual song unlocks. Weeks = whole week unlocks.
    """
    display_name = "Unlock Mode"
    option_songs = 0
    option_weeks = 1
    default = 0


class SongClearCount(Range):
    """How many Song Clear locations are in the multiworld."""
    display_name = "Song Clear Locations"
    range_start = 5
    range_end = 100
    default = 15


class WeekClearCount(Range):
    """How many Week Clear locations are in the multiworld"""
    display_name = "Week Clear Locations"
    range_start = 0
    range_end = 30
    default = 5


class StartingSongUnlocks(Range):
    """How many Song Unlocks the player starts with."""
    display_name = "Starting Song Unlocks"
    range_start = 1
    range_end = 10
    default = 1


class StartingWeekUnlocks(Range):
    """How many Week Unlocks the player starts with (Unlock Mode = Weeks)."""
    display_name = "Starting Week Unlocks"
    range_start = 0
    range_end = 5
    default = 1


class SongClearByDifficulty(Toggle):
    """Separate location checks for each difficulty."""
    display_name = "Song Clears per Difficulty"


class SongClearByMix(Toggle):
    """Separate location checks per character mixes."""
    display_name = "Song Clears per Mix"


class SongClearByCharacter(Toggle):
    """Separate location checks per playable character."""
    display_name = "Song Clears per Character"


class SongClearByWeek(Toggle):
    """Also create Week Clear locations when a full week is completed."""
    display_name = "Week Clear Checks"


class DifficultiesAsChecks(Toggle):
    """Clearing a song on a difficulty counts as its own check (in addition to the base clear)."""
    display_name = "Difficulty Clears as Checks"


class UnlockableDifficulties(Toggle):
    """Difficulties themselves are unlock items. Songs start locked to a base difficulty until unlocked."""
    display_name = "Unlockable Difficulties"


class RandomizeStages(Toggle):
    """Stages can be gated / randomized."""
    display_name = "Randomize Stages"


class Goal(Choice):
    """What is required to complete the game."""
    display_name = "Goal"
    option_all_song_clears = 0
    option_percent_song_clears = 1
    option_all_week_clears = 2
    default = 0


class GoalPercent(Range):
    """When Goal is Percent Song Clears, how many percent of song clears are required (1-100)."""
    display_name = "Goal Percent"
    range_start = 50
    range_end = 100
    default = 80


class DeathLinkOption(DeathLink):
    """When you die, everyone who enabled Death Link also dies (and vice versa)."""
    display_name = "Death Link"


@dataclass
class MoonEngineOptions(PerGameCommonOptions):
    unlock_mode: UnlockMode
    song_clear_count: SongClearCount
    week_clear_count: WeekClearCount
    starting_song_unlocks: StartingSongUnlocks
    starting_week_unlocks: StartingWeekUnlocks
    song_clear_by_difficulty: SongClearByDifficulty
    song_clear_by_mix: SongClearByMix
    song_clear_by_character: SongClearByCharacter
    song_clear_by_week: SongClearByWeek
    difficulties_as_checks: DifficultiesAsChecks
    unlockable_difficulties: UnlockableDifficulties
    randomize_stages: RandomizeStages
    goal: Goal
    goal_percent: GoalPercent
    death_link: DeathLinkOption
