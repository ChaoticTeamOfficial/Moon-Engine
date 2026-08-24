from typing import Dict, NamedTuple
from BaseClasses import ItemClassification


class ItemData(NamedTuple):
    id: int
    classification: ItemClassification


SONG_UNLOCK_BASE = 1000
WEEK_UNLOCK_BASE = 2000
DIFFICULTY_UNLOCK_BASE = 3000

# Max counts the world supports
MAX_SONGS = 100
MAX_WEEKS = 30

DIFFICULTY_NAMES = [
    "Easy",
    "Normal",
    "Hard",
    "Erect",
    "Nightmare",
]

item_table: Dict[str, ItemData] = {
    "Extra Health": ItemData(9000, ItemClassification.useful),
    "Filler Note": ItemData(9001, ItemClassification.filler),
    "Health Drain Trap": ItemData(9100, ItemClassification.trap),
    "Video Trap": ItemData(9101, ItemClassification.trap),
}

item_name_to_id: Dict[str, int] = {
    "Extra Health": 9000,
    "Filler Note": 9001,
    "Health Drain Trap": 9100,
    "Video Trap": 9101,
}

for i in range(1, MAX_SONGS + 1):
    item_name_to_id[f"Song Unlock {i}"] = SONG_UNLOCK_BASE + i

for i in range(1, MAX_WEEKS + 1):
    item_name_to_id[f"Week Unlock {i}"] = WEEK_UNLOCK_BASE + i

for i, diff in enumerate(DIFFICULTY_NAMES):
    item_name_to_id[f"Difficulty Unlock - {diff}"] = DIFFICULTY_UNLOCK_BASE + i


def song_unlock_name(index: int) -> str:
    return f"Song Unlock {index}"


def week_unlock_name(index: int) -> str:
    return f"Week Unlock {index}"


def difficulty_unlock_name(name: str) -> str:
    return f"Difficulty Unlock - {name}"


def build_dynamic_items(
    song_count: int,
    week_count: int,
    unlockable_difficulties: bool,
) -> Dict[str, ItemData]:
    """Item metadata used during generation."""
    items = dict(item_table)

    for i in range(1, song_count + 1):
        items[song_unlock_name(i)] = ItemData(
            SONG_UNLOCK_BASE + i, ItemClassification.progression
        )

    for i in range(1, week_count + 1):
        items[week_unlock_name(i)] = ItemData(
            WEEK_UNLOCK_BASE + i, ItemClassification.progression
        )

    if unlockable_difficulties:
        for i, diff in enumerate(DIFFICULTY_NAMES):
            items[difficulty_unlock_name(diff)] = ItemData(
                DIFFICULTY_UNLOCK_BASE + i, ItemClassification.progression
            )

    return items