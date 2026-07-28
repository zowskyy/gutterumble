extends Node3D
# Character Creator — texture-slot customization.
# Lets the player pick skin tone, outfit, hair, and a gang colour.
# Applies changes live to the preview model and saves via SaveManager.

const MOUSE_SCENE := preload("res://assets/characters/mouse/mouse.glb")

# Texture options per slot
const SKIN_OPTIONS: Array[Dictionary] = [
	{"label": "Dark",   "path": "res://assets/characters/mouse/mouse_young_darkskinned_male_diffuse.png"},
]
const HAIR_OPTIONS: Array[Dictionary] = [
	{"label": "Afro",  "path": "res://assets/characters/mouse/mouse_afro_diffuse.png"},
]
const SHIRT_OPTIONS: Array[Dictionary] = [
	{"label": "Hoodie",  "path": "res://assets/characters/mouse/mouse_hoodietex1.png", "unlock_wins": 0},
	{"label": "Hoodie 2","path": "res://assets/characters/mouse/mouse_normalshoodie.png", "unlock_wins": 5},
]
const PANTS_OPTIONS: Array[Dictionary] = [
	{"label": "Cargo",   "path": "res://assets/characters/mouse/mouse_cargo_pants_diff.png"},
]
const SHOE_OPTIONS: Array[Dictionary] = [
	{"label": "Kicks",   "path": "res://assets/characters/mouse/mouse_shoes02_diffuse.png"},
]
# unlock_wins gates these behind SaveManager's win count rather than a
# separate persisted "unlocked items" list — whether something's unlocked
# is a pure function of wins, so there's nothing new to save/load/desync.
# Skin/Pants/Shoes have exactly one option each (only one texture exists
# per slot in the current asset set) so there's nothing to gate there yet.
const GANG_COLORS: Array[Dictionary] = [
	{"label": "Blue",   "color": Color(0.15, 0.45, 1.0), "unlock_wins": 0},
	{"label": "Red",    "color": Color(1.0,  0.18, 0.18), "unlock_wins": 3},
	{"label": "Green",  "color": Color(0.15, 0.85, 0.35), "unlock_wins": 6},
	{"label": "Gold",   "color": Color(1.0,  0.70, 0.0), "unlock_wins": 10},
	{"label": "Purple", "color": Color(0.65, 0.20, 0.90), "unlock_wins": 15},
	{"label": "White",  "color": Color(0.95, 0.95, 0.95), "unlock_wins": 20},
]

var _appearance: Dictionary = {}
var _preview_model: Node3D  = null

# Slot indices
var _skin_idx: int  = 0
var _hair_idx: int  = 0
var _shirt_idx: int = 0
var _pants_idx: int = 0
var _shoe_idx: int  = 0
var _gang_idx: int  = 0

@onready var _back_btn: Button      = $UI/BackButton
@onready var _save_btn: Button      = $UI/SaveButton
@onready var _skin_lbl: Label       = $UI/Slots/SkinRow/Label
@onready var _hair_lbl: Label       = $UI/Slots/HairRow/Label
@onready var _shirt_lbl: Label      = $UI/Slots/ShirtRow/Label
@onready var _pants_lbl: Label      = $UI/Slots/PantsRow/Label
@onready var _shoe_lbl: Label       = $UI/Slots/ShoeRow/Label
@onready var _gang_lbl: Label       = $UI/Slots/GangRow/Label
@onready var _gang_swatch: ColorRect = $UI/Slots/GangRow/Swatch
@onready var _unlock_hint: Label    = $UI/Slots/UnlockHintLabel
@onready var _base_body: Node3D     = $BaseBody

func _ready() -> void:
	# Spawn preview model
	_preview_model = MOUSE_SCENE.instantiate()
	_base_body.add_child(_preview_model)
	_preview_model.position = Vector3.ZERO

	# Load saved appearance
	_appearance = SaveManager.load_appearance()
	_skin_idx   = _appearance.get("skin_idx",  0)
	_hair_idx   = _appearance.get("hair_idx",  0)
	_shirt_idx  = _appearance.get("shirt_idx", 0)
	_pants_idx  = _appearance.get("pants_idx", 0)
	_shoe_idx   = _appearance.get("shoe_idx",  0)
	_gang_idx   = _appearance.get("gang_idx",  0)

	# A saved index could point at something not (yet) unlocked — e.g. a save
	# file from before unlock gating existed, or one edited by hand. Index 0
	# is always unlocked by convention (unlock_wins defaults to 0), so it's
	# always a safe fallback.
	if not _is_unlocked(SHIRT_OPTIONS, _shirt_idx):
		_shirt_idx = 0
	if not _is_unlocked(GANG_COLORS, _gang_idx):
		_gang_idx = 0

	_refresh_labels()

	# Wire buttons
	if _back_btn:
		_back_btn.pressed.connect(_on_back)
	if _save_btn:
		_save_btn.pressed.connect(_on_save)
	_wire_slot_buttons()

func _process(delta: float) -> void:
	if _preview_model:
		_preview_model.rotate_y(delta * 0.6)

# ── Slot button wiring ────────────────────────────────────────────────────────

func _wire_slot_buttons() -> void:
	_connect_arrow("UI/Slots/SkinRow/Prev",  func() -> void: _cycle("skin",  -1))
	_connect_arrow("UI/Slots/SkinRow/Next",  func() -> void: _cycle("skin",   1))
	_connect_arrow("UI/Slots/HairRow/Prev",  func() -> void: _cycle("hair",  -1))
	_connect_arrow("UI/Slots/HairRow/Next",  func() -> void: _cycle("hair",   1))
	_connect_arrow("UI/Slots/ShirtRow/Prev", func() -> void: _cycle("shirt", -1))
	_connect_arrow("UI/Slots/ShirtRow/Next", func() -> void: _cycle("shirt",  1))
	_connect_arrow("UI/Slots/PantsRow/Prev", func() -> void: _cycle("pants", -1))
	_connect_arrow("UI/Slots/PantsRow/Next", func() -> void: _cycle("pants",  1))
	_connect_arrow("UI/Slots/ShoeRow/Prev",  func() -> void: _cycle("shoe",  -1))
	_connect_arrow("UI/Slots/ShoeRow/Next",  func() -> void: _cycle("shoe",   1))
	_connect_arrow("UI/Slots/GangRow/Prev",  func() -> void: _cycle("gang",  -1))
	_connect_arrow("UI/Slots/GangRow/Next",  func() -> void: _cycle("gang",   1))

func _connect_arrow(path: String, cb: Callable) -> void:
	var btn := get_node_or_null(path) as Button
	if btn:
		btn.pressed.connect(cb)

func _cycle(slot: String, dir: int) -> void:
	AudioManager.play_sfx("ui_confirm")
	match slot:
		"skin":  _skin_idx  = wrapi(_skin_idx  + dir, 0, SKIN_OPTIONS.size())
		"hair":  _hair_idx  = wrapi(_hair_idx  + dir, 0, HAIR_OPTIONS.size())
		"shirt": _shirt_idx = _cycle_unlocked(SHIRT_OPTIONS, _shirt_idx, dir)
		"pants": _pants_idx = wrapi(_pants_idx + dir, 0, PANTS_OPTIONS.size())
		"shoe":  _shoe_idx  = wrapi(_shoe_idx  + dir, 0, SHOE_OPTIONS.size())
		"gang":  _gang_idx  = _cycle_unlocked(GANG_COLORS, _gang_idx, dir)
	_refresh_labels()

# ── Unlocks ───────────────────────────────────────────────────────────────────

func _is_unlocked(options: Array[Dictionary], idx: int) -> bool:
	if idx < 0 or idx >= options.size():
		return false
	return SaveManager.get_stat("wins") >= int(options[idx].get("unlock_wins", 0))

# Skips locked entries entirely rather than letting the player land on one —
# they'd have no way to select it anyway, so showing it as "current" would
# just be confusing. Bounded to options.size() steps since index 0 is always
# unlocked by convention, guaranteeing a stopping point.
func _cycle_unlocked(options: Array[Dictionary], current: int, dir: int) -> int:
	var idx := current
	for _i in range(options.size()):
		idx = wrapi(idx + dir, 0, options.size())
		if _is_unlocked(options, idx):
			return idx
	return current

func _next_locked_hint(options: Array[Dictionary]) -> String:
	var wins := SaveManager.get_stat("wins")
	var best_req := -1
	var best_label := ""
	for opt in options:
		var req: int = int(opt.get("unlock_wins", 0))
		if req > wins and (best_req == -1 or req < best_req):
			best_req = req
			best_label = opt.get("label", "")
	if best_req == -1:
		return ""
	return "Win %d more to unlock %s" % [best_req - wins, best_label]

func _refresh_labels() -> void:
	if _skin_lbl:  _skin_lbl.text  = SKIN_OPTIONS[_skin_idx].get("label", "")
	if _hair_lbl:  _hair_lbl.text  = HAIR_OPTIONS[_hair_idx].get("label", "")
	if _shirt_lbl: _shirt_lbl.text = SHIRT_OPTIONS[_shirt_idx].get("label", "")
	if _pants_lbl: _pants_lbl.text = PANTS_OPTIONS[_pants_idx].get("label", "")
	if _shoe_lbl:  _shoe_lbl.text  = SHOE_OPTIONS[_shoe_idx].get("label", "")
	if _gang_lbl:
		_gang_lbl.text = GANG_COLORS[_gang_idx].get("label", "")
	if _gang_swatch:
		_gang_swatch.color = GANG_COLORS[_gang_idx].get("color", Color.WHITE)
	if _unlock_hint:
		# Gang colors have more tiers than shirts, so they're more likely to
		# have a next-unlock worth mentioning; shirts as a fallback.
		var hint := _next_locked_hint(GANG_COLORS)
		if hint.is_empty():
			hint = _next_locked_hint(SHIRT_OPTIONS)
		_unlock_hint.text = hint

func _on_save() -> void:
	var data := {
		"skin_idx":  _skin_idx,
		"hair_idx":  _hair_idx,
		"shirt_idx": _shirt_idx,
		"pants_idx": _pants_idx,
		"shoe_idx":  _shoe_idx,
		"gang_idx":  _gang_idx,
		"gang_color": GANG_COLORS[_gang_idx].get("color", Color.WHITE).to_html(),
	}
	SaveManager.save_appearance(data)
	CustomizationManager.load_character_appearance({"appearance": data})
	AudioManager.play_sfx("ui_confirm")

func _on_back() -> void:
	AudioManager.play_sfx("ui_back")
	GameManager.go_to_main_menu()
