from typing import Dict, NamedTuple, Optional


class LocationData(NamedTuple):
    id: Optional[int]


SONG_CLEAR_BASE = 10000
WEEK_CLEAR_BASE = 20000

MAX_SONGS = 100
MAX_WEEKS = 30

location_table: Dict[str, LocationData] = {
    "Victory": LocationData(None),
}

location_name_to_id: Dict[str, int] = {}

for i in range(1, MAX_SONGS + 1):
    location_name_to_id[f"Song Clear {i}"] = SONG_CLEAR_BASE + i

for i in range(1, MAX_WEEKS + 1):
    location_name_to_id[f"Week Clear {i}"] = WEEK_CLEAR_BASE + i


def song_clear_name(index: int) -> str:
    return f"Song Clear {index}"


def week_clear_name(index: int) -> str:
    return f"Week Clear {index}"


def build_dynamic_locations(song_count: int, week_count: int) -> Dict[str, LocationData]:
    locs = dict(location_table)

    for i in range(1, song_count + 1):
        locs[song_clear_name(i)] = LocationData(SONG_CLEAR_BASE + i)

    for i in range(1, week_count + 1):
        locs[week_clear_name(i)] = LocationData(WEEK_CLEAR_BASE + i)

    return locs