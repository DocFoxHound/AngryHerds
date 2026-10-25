## Every herd animal and wolf kind: stats, looks, and when the animals join the herd.

## Animals in the order the herd screen lists them.
const LINEUP_ORDER := ["sheep", "goat", "cow", "chicken", "duck", "pig", "bull"]
const LINEUP_SIZE := 6

const ANIMALS := {
	"sheep": {"name": "Sheep", "color": Color(0.95, 0.95, 0.92), "mass": 3.0, "ability": "", "unlock": 1,
		"voice": "baa", "about": "Sturdy and woolly. No tricks, just a hard head."},
	"goat": {"name": "Goat", "color": Color(0.80, 0.68, 0.50), "mass": 2.5, "ability": "dash", "unlock": 11,
		"voice": "bleat", "about": "Click mid-flight to charge forward."},
	"cow": {"name": "Cow", "color": Color(0.98, 0.96, 0.90), "mass": 5.0, "ability": "pound", "unlock": 21,
		"voice": "moo", "about": "Heavy. Click mid-flight to slam straight down."},
	"chicken": {"name": "Chicken", "color": Color(0.99, 0.98, 0.95), "mass": 1.8, "ability": "egg", "unlock": 31,
		"voice": "cluck", "size": 0.85, "about": "Click mid-flight to drop an exploding egg."},
	"duck": {"name": "Duck", "color": Color(1.0, 0.86, 0.25), "mass": 2.2, "ability": "split", "unlock": 51,
		"voice": "quack", "about": "Click mid-flight to split into three."},
	"pig": {"name": "Pig", "color": Color(1.0, 0.72, 0.76), "mass": 3.5, "ability": "explode", "unlock": 71,
		"voice": "oink", "about": "Explodes in a mud bomb: click mid-flight, or it goes off after landing."},
	"bull": {"name": "Bull", "color": Color(0.42, 0.26, 0.16), "mass": 9.0, "ability": "stampede", "unlock": 91,
		"voice": "snort", "size": 1.3, "about": "Huge. Click mid-flight to stampede straight ahead."},
	# Only appears when a duck splits.
	"duckling": {"name": "Duckling", "color": Color(1.0, 0.9, 0.4), "mass": 1.0, "ability": "", "unlock": 1000,
		"voice": "", "size": 0.6, "about": ""},
}

## size scales the base radius of 20. armor soaks damage until the hat flies off.
## extras are drawn accessories (see Art.wolf).
const WOLVES := {
	"pup": {"name": "Wolf Pup", "size": 0.8, "health": 60.0, "fur": Color(0.58, 0.58, 0.62), "points": 3000},
	"wolf": {"name": "Wolf", "size": 1.0, "health": 100.0, "fur": Color(0.45, 0.45, 0.50), "points": 5000},
	"big": {"name": "Big Wolf", "size": 1.45, "health": 200.0, "fur": Color(0.36, 0.33, 0.37), "points": 10000, "extras": ["scar"]},
	"fisher": {"name": "Fisher Wolf", "size": 1.0, "health": 120.0, "fur": Color(0.5, 0.48, 0.45), "points": 5000, "extras": ["buckethat"]},
	"bandit": {"name": "Bandit Wolf", "size": 1.0, "health": 130.0, "fur": Color(0.6, 0.47, 0.35), "points": 6000, "extras": ["mask", "cowboy"]},
	"hardhat": {"name": "Hard Hat Wolf", "size": 1.0, "health": 100.0, "fur": Color(0.48, 0.46, 0.5), "points": 7000, "armor": 120.0, "extras": ["hardhat"]},
	"snow": {"name": "Snow Wolf", "size": 1.05, "health": 150.0, "fur": Color(0.86, 0.89, 0.95), "points": 6000, "extras": ["scarf"]},
	"pirate": {"name": "Pirate Wolf", "size": 1.0, "health": 130.0, "fur": Color(0.52, 0.44, 0.4), "points": 6000, "extras": ["bandana", "eyepatch"]},
	"captain": {"name": "Pirate Captain", "size": 1.45, "health": 240.0, "fur": Color(0.4, 0.34, 0.32), "points": 12000, "extras": ["tricorn", "eyepatch"]},
	"suit": {"name": "Mob Wolf", "size": 1.0, "health": 130.0, "fur": Color(0.4, 0.4, 0.44), "points": 6000, "extras": ["shades", "tie"]},
	"ghost": {"name": "Ghost Wolf", "size": 1.0, "health": 110.0, "fur": Color(0.78, 0.85, 0.98, 0.8), "points": 6000, "extras": ["glow"]},
	"magma": {"name": "Magma Wolf", "size": 1.05, "health": 180.0, "fur": Color(0.55, 0.22, 0.18), "points": 7000, "extras": ["horns"]},
	"knight": {"name": "Knight Wolf", "size": 1.05, "health": 160.0, "fur": Color(0.42, 0.42, 0.48), "points": 9000, "armor": 160.0, "extras": ["knight"]},
	# Bosses guard the tenth level of each area.
	"boss_farm": {"name": "Big Bad Wolf", "size": 1.9, "health": 400.0, "fur": Color(0.4, 0.38, 0.42), "points": 25000, "boss": true, "extras": ["scar"]},
	"boss_forest": {"name": "Alpha Fang", "size": 1.9, "health": 480.0, "fur": Color(0.3, 0.3, 0.33), "points": 25000, "boss": true, "extras": ["scar", "leafcrown"]},
	"boss_river": {"name": "Old Muddy", "size": 1.95, "health": 560.0, "fur": Color(0.45, 0.38, 0.28), "points": 25000, "boss": true, "extras": ["buckethat", "scar"]},
	"boss_canyon": {"name": "Bandit King", "size": 1.95, "health": 640.0, "fur": Color(0.62, 0.45, 0.3), "points": 25000, "boss": true, "extras": ["mask", "cowboy"]},
	"boss_peaks": {"name": "Yeti Wolf", "size": 2.1, "health": 720.0, "fur": Color(0.93, 0.95, 1.0), "points": 25000, "boss": true, "extras": ["horns", "scarf"]},
	"boss_pirate": {"name": "Captain Blackfang", "size": 2.0, "health": 800.0, "fur": Color(0.25, 0.22, 0.24), "points": 25000, "boss": true, "extras": ["tricorn", "eyepatch", "scar"]},
	"boss_city": {"name": "Don Wolfgang", "size": 2.0, "health": 880.0, "fur": Color(0.35, 0.35, 0.4), "points": 25000, "boss": true, "extras": ["tophat", "shades", "tie"]},
	"boss_graveyard": {"name": "The Howler", "size": 2.0, "health": 960.0, "fur": Color(0.75, 0.82, 1.0, 0.8), "points": 25000, "boss": true, "extras": ["glow", "crown"]},
	"boss_volcano": {"name": "Magma Fang", "size": 2.05, "health": 1040.0, "fur": Color(0.5, 0.16, 0.12), "points": 25000, "boss": true, "extras": ["horns", "scar"]},
	"boss_castle": {"name": "The Wolf King", "size": 2.2, "health": 1200.0, "fur": Color(0.28, 0.27, 0.32), "points": 50000, "boss": true, "extras": ["cape", "crown", "scar"]},
}


static func wolf_radius(variant: String) -> float:
	return 20.0 * float(WOLVES[variant].size)


static func animal_size(kind: String) -> float:
	return float(ANIMALS[kind].get("size", 1.0))


## The animal that joins the herd at exactly this level, or "".
static func animal_unlocked_at(level: int) -> String:
	for kind in LINEUP_ORDER:
		if ANIMALS[kind].unlock == level:
			return kind
	return ""
