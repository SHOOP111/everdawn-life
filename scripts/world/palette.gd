class_name Palette
extends RefCounted

const INK := Color("17252d")
const DEEP_WATER := Color("214e64")
const WATER := Color("32758a")
const FOAM := Color("6bb0ad")
const SAND := Color("d0b36a")
const DRY_GRASS := Color("8c9a4d")
const GRASS := Color("5b9b58")
const LIGHT_GRASS := Color("79b95d")
const FOREST := Color("336447")
const HIGHLAND := Color("697451")
const DIRT := Color("8f6845")
const DARK_DIRT := Color("604737")
const WOOD := Color("a6663e")
const DARK_WOOD := Color("653b36")
const ROOF_RED := Color("a74c43")
const ROOF_BLUE := Color("456d89")
const CREAM := Color("ead8ad")
const GOLD := Color("edc36b")
const NIGHT := Color("16213c")
const SKIN := Color("e4a672")
const WHITE := Color("fff4d8")
const SHADOW := Color(0.05, 0.08, 0.11, 0.35)

static func season_grass(season: int) -> Color:
	match season:
		1: return Color("6ca34f")
		2: return Color("9a9147")
		3: return Color("82958b")
		_: return GRASS
