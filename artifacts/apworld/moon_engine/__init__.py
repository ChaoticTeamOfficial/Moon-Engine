from typing import Dict, List

from BaseClasses import Region, Location, Item, ItemClassification
from worlds.AutoWorld import World, WebWorld
from worlds.generic.Rules import set_rule, add_rule

from .Items import (
    ItemData,
    build_dynamic_items,
    song_unlock_name,
    week_unlock_name,
    difficulty_unlock_name,
    DIFFICULTY_NAMES,
    item_name_to_id as _static_item_name_to_id,
)
from .Locations import (
    build_dynamic_locations,
    song_clear_name,
    week_clear_name,
    location_name_to_id as _static_location_name_to_id,
)
from .Options import MoonEngineOptions


class MoonEngineWeb(WebWorld):
    theme = "partyTime"
    rich_text_options_doc = True


class MoonEngineItem(Item):
    game = "Moon Engine"


class MoonEngineLocation(Location):
    game = "Moon Engine"


class MoonEngineWorld(World):
    """
    Friday Night Funkin' – Moon Engine

    A Funkin' Archipelago world.
    """
    game = "Moon Engine"
    options_dataclass = MoonEngineOptions
    options: MoonEngineOptions
    topology_present = False
    web = MoonEngineWeb()

    item_name_to_id = _static_item_name_to_id
    location_name_to_id = _static_location_name_to_id
    _item_data: Dict[str, ItemData] = {}
    _location_data: Dict = {}

    def generate_early(self) -> None:
        song_count = self.options.song_clear_count.value
        week_count = self.options.week_clear_count.value
        if not self.options.song_clear_by_week:
            week_count = 0

        self._item_data = build_dynamic_items(
            song_count,
            week_count,
            bool(self.options.unlockable_difficulties),
        )
        self._location_data = build_dynamic_locations(song_count, week_count)
        self.item_name_to_id = dict(_static_item_name_to_id)
        self.location_name_to_id = dict(_static_location_name_to_id)

        MoonEngineWorld.item_name_to_id = _static_item_name_to_id
        MoonEngineWorld.location_name_to_id = _static_location_name_to_id

    def create_regions(self) -> None:
        menu = Region("Menu", self.player, self.multiworld)
        self.multiworld.regions.append(menu)

        for name, data in self._location_data.items():
            loc = MoonEngineLocation(self.player, name, data.id, menu)
            menu.locations.append(loc)

        victory_item = MoonEngineItem(
            "Victory",
            ItemClassification.progression,
            None,
            self.player,
        )
        self.multiworld.get_location("Victory", self.player).place_locked_item(victory_item)

        self.multiworld.completion_condition[self.player] = (
            lambda state: state.has("Victory", self.player)
        )

    def create_items(self) -> None:
        song_count = self.options.song_clear_count.value
        week_count = self.options.week_clear_count.value
        if not self.options.song_clear_by_week:
            week_count = 0

        real_location_count = sum(
            1 for data in self._location_data.values() if data.id is not None
        )

        itempool: List[Item] = []

        # Song unlocks
        all_song_indices = list(range(1, song_count + 1))
        start_song_indices = []
        if self.options.unlock_mode == 0:
            n_start = min(self.options.starting_song_unlocks.value, song_count)
            start_song_indices = self.random.sample(all_song_indices, n_start)
            for i in start_song_indices:
                self.multiworld.push_precollected(self.create_item(song_unlock_name(i)))

        for i in all_song_indices:
            if i not in start_song_indices:
                itempool.append(self.create_item(song_unlock_name(i)))

        # Week unlocks
        all_week_indices = list(range(1, week_count + 1))
        start_week_indices = []
        if self.options.unlock_mode == 1 and week_count > 0:
            n_start = min(self.options.starting_week_unlocks.value, week_count)
            start_week_indices = self.random.sample(all_week_indices, n_start)
            for i in start_week_indices:
                self.multiworld.push_precollected(self.create_item(week_unlock_name(i)))

        for i in all_week_indices:
            if i not in start_week_indices:
                itempool.append(self.create_item(week_unlock_name(i)))

        # Difficulty unlocks
        if self.options.unlockable_difficulties:
            room = real_location_count - len(itempool)
            for diff in DIFFICULTY_NAMES:
                if room <= 0:
                    break
                itempool.append(self.create_item(difficulty_unlock_name(diff)))
                room -= 1

        while len(itempool) < real_location_count:
            itempool.append(self.create_item("Filler Note"))

        while len(itempool) > real_location_count:
            dropped = False
            for j in range(len(itempool) - 1, -1, -1):
                if itempool[j].name in ("Filler Note", "Extra Health"):
                    itempool.pop(j)
                    dropped = True
                    break
            if not dropped:
                itempool.pop()

        self.multiworld.itempool += itempool

    def create_item(self, name: str) -> MoonEngineItem:
        data = self._item_data[name]
        return MoonEngineItem(name, data.classification, data.id, self.player)

    def set_rules(self) -> None:
        song_count = self.options.song_clear_count.value
        week_count = self.options.week_clear_count.value
        if not self.options.song_clear_by_week:
            week_count = 0

        song_unlock_names = [song_unlock_name(i) for i in range(1, song_count + 1)]
        week_unlock_names = [week_unlock_name(i) for i in range(1, week_count + 1)]

        for i in range(1, song_count + 1):
            set_rule(
                self.multiworld.get_location(song_clear_name(i), self.player),
                lambda state, n=i, names=song_unlock_names: state.count_from_list_unique(names, self.player) >= n,
            )

        for i in range(1, week_count + 1):
            set_rule(
                self.multiworld.get_location(week_clear_name(i), self.player),
                lambda state, n=i, names=week_unlock_names: state.count_from_list_unique(names, self.player) >= n,
            )

        victory = self.multiworld.get_location("Victory", self.player)
        goal = self.options.goal.value

        if goal == 2 and week_count > 0:
            for i in range(1, week_count + 1):
                add_rule(
                    victory,
                    lambda state, n=i: state.can_reach(week_clear_name(n), "Location", self.player),
                )
        elif goal == 1:
            needed = max(1, (song_count * self.options.goal_percent.value) // 100)
            for i in range(1, needed + 1):
                add_rule(
                    victory,
                    lambda state, n=i: state.can_reach(song_clear_name(n), "Location", self.player),
                )
        else:
            for i in range(1, song_count + 1):
                add_rule(
                    victory,
                    lambda state, n=i: state.can_reach(song_clear_name(n), "Location", self.player),
                )

    def fill_slot_data(self) -> Dict:
        return {
            "unlock_mode": self.options.unlock_mode.value,
            "song_clear_count": self.options.song_clear_count.value,
            "week_clear_count": self.options.week_clear_count.value if self.options.song_clear_by_week else 0,
            "starting_song_unlocks": self.options.starting_song_unlocks.value,
            "starting_week_unlocks": self.options.starting_week_unlocks.value,
            "song_clear_by_difficulty": bool(self.options.song_clear_by_difficulty),
            "song_clear_by_mix": bool(self.options.song_clear_by_mix),
            "song_clear_by_character": bool(self.options.song_clear_by_character),
            "song_clear_by_week": bool(self.options.song_clear_by_week),
            "difficulties_as_checks": bool(self.options.difficulties_as_checks),
            "unlockable_difficulties": bool(self.options.unlockable_difficulties),
            "randomize_stages": bool(self.options.randomize_stages),
            "goal": self.options.goal.value,
            "goal_percent": self.options.goal_percent.value,
            "death_link": bool(self.options.death_link),
        }