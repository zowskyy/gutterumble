extends CanvasLayer
## On-screen touch controls for offline mobile play.
## Buttons call InputRouter.pulse_touch_action only — no combat APIs.
## Joystick calls set_touch_move / clear_touch_move. Multitouch-safe via finger index.

const STICK_SIZE := 140.0
const BTN_SIZE := 64.0
const SMALL_BTN := 48.0
const MARGIN := 16.0

var _root: Control
var _stick_base: Control
var _stick_knob: Control
var _btn_row: HBoxContainer
var _safe_pad: Vector4 = Vector4.ZERO  # left, top, right, bottom

var _stick_finger: int = -1
var _stick_origin: Vector2 = Vector2.ZERO

func _ready() -> void:
	layer = 15
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_apply_safe_area()
	# Show on touch/mobile; keep visible for desktop mouse testing of the stick.
	visible = true
	if not DisplayServer.is_touchscreen_available() and not OS.has_feature("mobile"):
		# Still visible for desktop drag-testing; no-op branch documents intent.
		visible = true

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_SIZE_CHANGED or what == NOTIFICATION_APPLICATION_RESUMED:
		_apply_safe_area()

func _build_ui() -> void:
	_root = Control.new()
	_root.name = "Root"
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_stick_base = Control.new()
	_stick_base.name = "StickBase"
	_stick_base.custom_minimum_size = Vector2(STICK_SIZE, STICK_SIZE)
	_stick_base.size = Vector2(STICK_SIZE, STICK_SIZE)
	_stick_base.mouse_filter = Control.MOUSE_FILTER_STOP
	_stick_base.gui_input.connect(_on_stick_gui_input)
	_root.add_child(_stick_base)

	var stick_bg := ColorRect.new()
	stick_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	stick_bg.color = Color(1, 1, 1, 0.18)
	stick_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(stick_bg)

	_stick_knob = ColorRect.new()
	_stick_knob.name = "StickKnob"
	_stick_knob.size = Vector2(48, 48)
	_stick_knob.color = Color(1, 1, 1, 0.45)
	_stick_knob.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stick_base.add_child(_stick_knob)
	_center_knob()

	_btn_row = HBoxContainer.new()
	_btn_row.name = "Buttons"
	_btn_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_btn_row.add_theme_constant_override("separation", 10)
	_root.add_child(_btn_row)

	_add_action_button(_btn_row, "Light", "light", Vector2(BTN_SIZE, BTN_SIZE))
	_add_action_button(_btn_row, "Heavy", "heavy", Vector2(BTN_SIZE, BTN_SIZE))
	_add_action_button(_btn_row, "Dodge", "dodge", Vector2(BTN_SIZE, BTN_SIZE))
	_add_action_button(_btn_row, "Special", "special", Vector2(BTN_SIZE, BTN_SIZE))
	_add_action_button(_btn_row, "Use", "interact", Vector2(SMALL_BTN, SMALL_BTN))
	_add_action_button(_btn_row, "Revive", "revive", Vector2(SMALL_BTN, SMALL_BTN))
	_add_action_button(_btn_row, "Pause", "pause", Vector2(SMALL_BTN, SMALL_BTN))

func _add_action_button(parent: Control, label: String, action: String, min_size: Vector2) -> void:
	# Touch buttons must call pulse_touch_action only.
	if action.is_empty():
		return  # error: reject empty action
	var btn := Button.new()
	btn.text = label
	btn.custom_minimum_size = min_size
	btn.focus_mode = Control.FOCUS_NONE
	btn.pressed.connect(func() -> void:
		InputRouter.pulse_touch_action(action)
	)
	parent.add_child(btn)

func _apply_safe_area() -> void:
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var win: Vector2i = get_window().size
	if win.x <= 0 or win.y <= 0:
		return  # error: invalid window size
	var left: float = float(safe.position.x)
	var top: float = float(safe.position.y)
	var right: float = float(win.x - (safe.position.x + safe.size.x))
	var bottom: float = float(win.y - (safe.position.y + safe.size.y))
	_safe_pad = Vector4(
		maxf(0.0, left),
		maxf(0.0, top),
		maxf(0.0, right),
		maxf(0.0, bottom)
	)
	_layout_controls()

func _layout_controls() -> void:
	if _stick_base == null or _btn_row == null:
		return
	var win: Vector2 = Vector2(get_window().size)
	var left_m: float = MARGIN + _safe_pad.x
	var bottom_m: float = MARGIN + _safe_pad.w
	var right_m: float = MARGIN + _safe_pad.z

	_stick_base.position = Vector2(left_m, win.y - bottom_m - STICK_SIZE)
	_stick_base.size = Vector2(STICK_SIZE, STICK_SIZE)

	_btn_row.reset_size()
	var row_size: Vector2 = _btn_row.get_combined_minimum_size()
	_btn_row.position = Vector2(win.x - right_m - row_size.x, win.y - bottom_m - maxf(BTN_SIZE, row_size.y))
	_center_knob()

func _center_knob() -> void:
	if _stick_knob == null or _stick_base == null:
		return
	_stick_knob.position = (_stick_base.size - _stick_knob.size) * 0.5

func _on_stick_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		var st := event as InputEventScreenTouch
		if st.pressed and _stick_finger < 0:
			_stick_finger = st.index
			_stick_origin = _stick_base.size * 0.5
			_update_stick(st.position)
		elif not st.pressed and st.index == _stick_finger:
			_release_stick()
	elif event is InputEventScreenDrag:
		var sd := event as InputEventScreenDrag
		if sd.index == _stick_finger:
			_update_stick(sd.position)
	elif event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed and _stick_finger < 0:
			_stick_finger = 0
			_stick_origin = _stick_base.size * 0.5
			_update_stick(mb.position)
		elif not mb.pressed and _stick_finger == 0:
			_release_stick()
	elif event is InputEventMouseMotion:
		var mm := event as InputEventMouseMotion
		if _stick_finger == 0 and (mm.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			_update_stick(mm.position)

func _update_stick(local_pos: Vector2) -> void:
	var delta: Vector2 = local_pos - _stick_origin
	var max_r: float = STICK_SIZE * 0.5 - 8.0
	if delta.length() > max_r:
		delta = delta.normalized() * max_r
	_stick_knob.position = _stick_origin + delta - _stick_knob.size * 0.5
	var strength: float = clampf(delta.length() / max_r, 0.0, 1.0)
	var move := Vector2.ZERO
	if strength > 0.05:
		move = delta.normalized() * strength
		# Screen y-down → gameplay y-forward (negative screen y = forward).
		move.y = -move.y
	InputRouter.set_touch_move(move)

func _release_stick() -> void:
	_stick_finger = -1
	_center_knob()
	InputRouter.clear_touch_move()
