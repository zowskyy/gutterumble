extends Node3D
# Character Creator — texture-slot customization.
# Lets the player pick skin tone, outfit, hair, and a gang colour.
# Option tables live in CustomizationManager (single source of truth shared
# with the code that applies a saved appearance to the actual in-arena
# fighter) — this script only owns UI state and the live preview.

const MOUSE_SCENE := preload("res://assets/characters/mouse/mouse.glb")

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
	if not _is_unlocked(CustomizationManager.SHIRT_OPTIONS, _shirt_idx):
		_shirt_idx = 0
	if not _is_unlocked(CustomizationManager.GANG_COLORS, _gang_idx):
		_gang_idx = 0

	_refresh_labels()
	_update_preview()

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
		"skin":  _skin_idx  = wrapi(_skin_idx  + dir, 0, CustomizationManager.SKIN_OPTIONS.size())
		"hair":  _hair_idx  = wrapi(_hair_idx  + dir, 0, CustomizationManager.HAIR_OPTIONS.size())
		"shirt": _shirt_idx = _cycle_unlocked(CustomizationManager.SHIRT_OPTIONS, _shirt_idx, dir)
		"pants": _pants_idx = wrapi(_pants_idx + dir, 0, CustomizationManager.PANTS_OPTIONS.size())
		"shoe":  _shoe_idx  = wrapi(_shoe_idx  + dir, 0, CustomizationManager.SHOE_OPTIONS.size())
		"gang":  _gang_idx  = _cycle_unlocked(CustomizationManager.GANG_COLORS, _gang_idx, dir)
	_refresh_labels()
	_update_preview()

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
	if _skin_lbl:  _skin_lbl.text  = CustomizationManager.SKIN_OPTIONS[_skin_idx].get("label", "")
	if _hair_lbl:  _hair_lbl.text  = CustomizationManager.HAIR_OPTIONS[_hair_idx].get("label", "")
	if _shirt_lbl: _shirt_lbl.text = CustomizationManager.SHIRT_OPTIONS[_shirt_idx].get("label", "")
	if _pants_lbl: _pants_lbl.text = CustomizationManager.PANTS_OPTIONS[_pants_idx].get("label", "")
	if _shoe_lbl:  _shoe_lbl.text  = CustomizationManager.SHOE_OPTIONS[_shoe_idx].get("label", "")
	if _gang_lbl:
		_gang_lbl.text = CustomizationManager.GANG_COLORS[_gang_idx].get("label", "")
	if _gang_swatch:
		_gang_swatch.color = CustomizationManager.GANG_COLORS[_gang_idx].get("color", Color.WHITE)
	if _unlock_hint:
		# Gang colors have more tiers than shirts, so they're more likely to
		# have a next-unlock worth mentioning; shirts as a fallback.
		var hint := _next_locked_hint(CustomizationManager.GANG_COLORS)
		if hint.is_empty():
			hint = _next_locked_hint(CustomizationManager.SHIRT_OPTIONS)
		_unlock_hint.text = hint

# Applies the current in-progress selection to the live preview mesh —
# previously the preview only ever showed the default glb textures; cycling
# options changed the label text but never the actual 3D model.
func _update_preview() -> void:
	if not _preview_model:
		return
	CustomizationManager.apply_to_fighter(_preview_model, {
		"skin_idx":  _skin_idx,
		"hair_idx":  _hair_idx,
		"shirt_idx": _shirt_idx,
		"pants_idx": _pants_idx,
		"shoe_idx":  _shoe_idx,
	})

func _on_save() -> void:
	var data := {
		"skin_idx":  _skin_idx,
		"hair_idx":  _hair_idx,
		"shirt_idx": _shirt_idx,
		"pants_idx": _pants_idx,
		"shoe_idx":  _shoe_idx,
		"gang_idx":  _gang_idx,
		"gang_color": CustomizationManager.GANG_COLORS[_gang_idx].get("color", Color.WHITE).to_html(),
	}
	SaveManager.save_appearance(data)
	CustomizationManager.load_character_appearance({"appearance": data})
	AudioManager.play_sfx("ui_confirm")

func _on_back() -> void:
	AudioManager.play_sfx("ui_back")
	GameManager.go_to_main_menu()
