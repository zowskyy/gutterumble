# Android Input Architecture

**Command 03.** Canonical gameplay intent for keyboard, gamepad, and touch.

## Pipeline

```
Keyboard / Gamepad / Touch UI
            │
            ▼
     InputRouter (autoload)
            │
            ▼
      InputCommand
   (sequence, move, edges)
            │
            ▼
   PlayerController FSM
```

Touch buttons **must not** call combat APIs (`take_damage`, hitboxes, etc.). They only call:

- `InputRouter.set_touch_move(v)` / `clear_touch_move()`
- `InputRouter.pulse_touch_action("light"|"heavy"|"dodge"|"special"|"interact"|"revive"|"pause")`

## Files

| Path | Role |
|------|------|
| `systems/input_command.gd` | `class_name InputCommand` |
| `autoloads/input_router.gd` | Merge InputMap + touch pulses |
| `scenes/ui/touch_controls.tscn` | Virtual stick + action buttons + safe area |
| `scenes/ui/pause_menu.gd` | Resume/Quit wired; ESC / Start / pause pulse |
| `scenes/player/player_controller.gd` | Consumes `InputCommand` once per physics frame |

## Actions (`project.godot`)

| Action | Sources |
|--------|---------|
| `ui_*` | Engine defaults (keys + typical gamepad axes) |
| `attack_light` / `attack_heavy` / `dodge` / `special_attack` | Keyboard (+ future gamepad bindings) |
| `interact` / `revive` / `pause_menu` | Reserved for environmental / revive / pause |

## Safe area

`touch_controls.gd` reads `DisplayServer.get_display_safe_area()` and insets stick/buttons.

## Network foreshadow

Online clients will serialize the same `InputCommand` fields to the dedicated server. Do not add damage/KO/reward fields to this struct.
