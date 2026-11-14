extends RefCounted
# All the upgrade info lives here so the upgrade menu, the pause menu and the player always agree.
#
# You can pick the same upgrade again, but the % ones give less each time:
# every repeat is worth DECAY times the pick before it (15% -> 10.5% -> 7.4% ...)
# so they level off instead of getting super op.

const DECAY = 0.7

const LIST = [
	{"id": "max_health", "title": "+1 Max Health"},
	{"id": "speed", "title": "Swift Feet"},
	{"id": "fire_rate", "title": "Quick Shot"},
	{"id": "bounces", "title": "Extra Bounce"},
	{"id": "ball_speed", "title": "Fast Arrow"},
	{"id": "checkpoint", "title": "Checkpoint"},
]

# what the very first pick of each % upgrade gives
const FIRST_PICK = {"speed": 0.15, "fire_rate": 0.20, "ball_speed": 0.20}


# total bonus after picking an upgrade `level` times.
# % upgrades give a fraction (0.15 = +15%), health and bounces just give +1 per pick.
static func bonus(id: String, level: int) -> float:
	if FIRST_PICK.has(id):
		return FIRST_PICK[id] * (1.0 - pow(DECAY, level)) / (1.0 - DECAY)
	return float(level)


static func title(id: String) -> String:
	for u in LIST:
		if u.id == id:
			return u.title
	return id


# text on the upgrade card. level = how many times you already have it
static func card_desc(id: String, level: int, wave: int) -> String:
	var gain = int(round((bonus(id, level + 1) - bonus(id, level)) * 100.0))
	var another = "another " if level > 0 else ""
	match id:
		"max_health":
			return "Survive one more hit."
		"speed":
			return "Move %s%d%% faster." % [another, gain]
		"fire_rate":
			return "Shoot %s%d%% more often." % [another, gain]
		"bounces":
			return "Arrows bounce one more time."
		"ball_speed":
			return "Arrows travel %s%d%% faster." % [another, gain]
		"checkpoint":
			return "Skip the upgrade and restart at wave %d instead of wave 1." % wave
	return ""


# one line for the pause menu showing what you have in total
static func owned_desc(id: String, level: int) -> String:
	var pct = int(round(bonus(id, level) * 100.0))
	match id:
		"max_health":
			return "+%d max health" % level
		"speed":
			return "+%d%% move speed" % pct
		"fire_rate":
			return "+%d%% fire rate" % pct
		"bounces":
			return "+%d arrow bounce%s" % [level, "" if level == 1 else "s"]
		"ball_speed":
			return "+%d%% arrow speed" % pct
		"checkpoint":
			return "used %d time%s" % [level, "" if level == 1 else "s"]
	return ""
