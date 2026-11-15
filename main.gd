extends Node2D

# =====================================================================
# DATARAIN — EXACT HTML5 PROTOTYPE PORT + HEALTH BAR & SPIKES (GODOT 4)
# =====================================================================

# Exact Tuning Constants from your HTML5 Prototype
const WALK_SPEED := 285.0
const SPRINT_SPEED := 505.0
const CROUCH_SPEED := 135.0
const GROUND_ACCEL := 3100.0
const SPRINT_ACCEL := 3800.0
const AIR_ACCEL := 1750.0
const GROUND_FRICTION := 3300.0
const CROUCH_FRICTION := 4300.0
const AIR_DRAG := 80.0
const SPRINT_JUMP_BOOST := 1.075
const MAX_HORIZONTAL_SPEED := 590.0

const GRAVITY := 2350.0
const FALL_GRAVITY_MULTIPLIER := 1.12
const JUMP_CUT_MULTIPLIER := 2.15
const MAX_FALL_SPEED := 1450.0
const JUMP_SPEED := 685.0
const SUPER_DOUBLE_JUMP_MULT := 1.56
const SUPER_STOMP_SPEED := 2250.0
const SUPER_STOMP_LAND_DURATION := 0.46

const MAX_STAMINA := 100.0
const STAMINA_REGEN_RATE := 28.0
const STAMINA_REGEN_DELAY := 0.65
const SPRINT_STAMINA_DRAIN := 16.0
const DASH_STAMINA_COST := 30.0
const SUPER_DOUBLE_JUMP_COST := 35.0
const DASH_SPEED := 980.0
const DASH_DURATION := 0.14
const DASH_COOLDOWN := 0.25

var game_state := "playing"
var player_state_direction := 1.0
var dash_timer := 0.0
var dash_cooldown_timer := 0.0
var stamina := MAX_STAMINA
var stamina_regen_timer := 0.0
var shake_intensity := 0.0

var cam: Camera2D
var stamina_bar_fill: ColorRect
var stamina_text: Label
var death_overlay: Control
const SUPERJUMP_SPEED_MULT := 1.304 # 1.304^2 = exact 1.7x jump height
const SUPERJUMP_CHARGE_TIME := 0.18 # Must hold crouch for 0.18s first so it's never accidental
var crouch_hold_timer := 0.0
var is_superjumping := false
var is_stomping := false
const DOUBLE_JUMP_MULT := 1.42
const STOMP_SPEED := 1350.0
const MEGA_STOMP_SPEED := 1850.0
const STOMP_LAND_DURATION := 0.22
const MEGA_STOMP_LAND_DURATION := 0.36

var has_double_jump := false
var jump_tier := 0 # 0 = normal jump, 1 = superjump, 2 = double jump
var stomp_tier := 0 # 0 = none, 1 = normal stomp, 2 = mega stomp
var stomp_land_timer := 0.0
var normal_land_timer := 0.0
var grass_blades: Array[Dictionary] = []

const COYOTE_TIME := 0.10
const JUMP_BUFFER_TIME := 0.13

const PLAYER_WIDTH := 32.0
const PLAYER_HEIGHT := 48.0
const PLAYER_SHEET_PATH := "res://assets/sprites/player_sheet.png"
const PLAYER_TEMPLATE_PATH := "res://assets/sprites/player_sheet_template.png"
const NORMAL_LAND_DURATION := 0.20
const GROUND_MIN_HEIGHT := 82.0
const GROUND_MAX_HEIGHT := 138.0
const SPIKE_TEX_PATH := "res://assets/sprites/spike.png"
const SPIKE_TEMPLATE_PATH := "res://assets/sprites/spike_template.png"
const GROUND_TOP_PATH := "res://assets/sprites/ground_top.png"
const GROUND_SPIKE_PATH := "res://assets/sprites/ground_spike.png"
const GROUND_UNDER_PATH := "res://assets/sprites/ground_under.png"
const GRASS_TEX_PATH := "res://assets/sprites/grass.png"
const HP_FRAME_PATH := "res://assets/sprites/hp_frame.png"
const STAMINA_FRAME_PATH := "res://assets/sprites/stamina_frame.png"
const GROUND_SPIKE_LEFT_PATH := "res://assets/sprites/ground_spike_left.png"
const GROUND_SPIKE_RIGHT_PATH := "res://assets/sprites/ground_spike_right.png"

# Phase 2 Health & Spikes Constants
const MAX_HP := 100
const SPIKE_DAMAGE := 25
const INVULN_TIME := 0.85
const SPIKE_KNOCKBACK := Vector2(360.0, -430.0)

# Kinematics & Animation State (Kept modular for future slams/gliding/combat)
var vx := 0.0
var vy := 0.0
var grounded := true
var facing := 1.0
var state := "idle"
var coyote_timer := COYOTE_TIME
var jump_buffer_timer := 0.0
var landing_squash := 0.0
var last_impact_vy := 0.0

var anim_lean := 0.0
var anim_scale_x := 1.0
var anim_scale_y := 1.0

# Health State
var hp := MAX_HP
var invuln_timer := 0.0
var spawn_pos := Vector2(260.0, 580.0)
var floor_y := 580.0
var ground_height := 110.0
var arena_width := 1280.0
var arena_height := 648.0

# Nodes (Isolated visual Sprite2D nodes for 1-drag texture replacement later)
var player_body: CharacterBody2D
var player_visual_pivot: Node2D
var player_sprite: AnimatedSprite2D
var spikes_area: Area2D
var hp_bar_fill: ColorRect
var hp_text: Label

func _setup_input_map() -> void:
	var bindings := {
		"move_left": KEY_A,
		"move_right": KEY_D,
		"sprint": KEY_CTRL,
		"crouch": KEY_SHIFT,
		"jump": KEY_SPACE,
		"stomp": KEY_S,
		"dash": KEY_Q,

	}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		var ev := InputEventKey.new()
		ev.physical_keycode = bindings[action]
		InputMap.action_add_event(action, ev)

func _ready() -> void:
	_setup_input_map()
	RenderingServer.set_default_clear_color(Color(0.22, 0.24, 0.28))
	var viewport_size := Vector2(1152.0, 648.0)
	arena_width = viewport_size.x
	ground_height = clampf(viewport_size.y * 0.13, GROUND_MIN_HEIGHT, GROUND_MAX_HEIGHT)
	floor_y = roundf(viewport_size.y - ground_height)
	spawn_pos = Vector2(arena_width * 0.25, floor_y)

	cam = Camera2D.new()
	cam.position = viewport_size * 0.5
	add_child(cam)

	_setup_baseplate()
	_setup_player()
	_setup_hud()
	_setup_spikes()
	_setup_death_screen()


func _setup_death_screen() -> void:
	var ui_layer := CanvasLayer.new()
	ui_layer.name = "DeathScreen"
	ui_layer.layer = 10
	add_child(ui_layer)

	death_overlay = Control.new()
	death_overlay.visible = false
	ui_layer.add_child(death_overlay)

	var death_bg := ColorRect.new()
	death_bg.size = Vector2(arena_width, arena_height)
	death_bg.color = Color(0.04, 0.0, 0.0, 0.85)
	death_overlay.add_child(death_bg)

	var died_lbl := Label.new()
	died_lbl.text = "YOU DIED"
	died_lbl.position = Vector2(arena_width * 0.5 - 105.0, arena_height * 0.31)
	died_lbl.add_theme_font_size_override("font_size", 42)
	died_lbl.modulate = Color(0.95, 0.25, 0.30)
	death_overlay.add_child(died_lbl)

	var retry_btn := Button.new()
	retry_btn.text = "RETRY (R)"
	retry_btn.position = Vector2(arena_width * 0.5 - 85.0, arena_height * 0.46)
	retry_btn.size = Vector2(170.0, 46.0)
	retry_btn.pressed.connect(_retry_game)
	death_overlay.add_child(retry_btn)

	var menu_btn := Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.position = Vector2(arena_width * 0.5 - 85.0, arena_height * 0.55)
	menu_btn.size = Vector2(170.0, 46.0)
	menu_btn.pressed.connect(_return_to_menu)
	death_overlay.add_child(menu_btn)


func _retry_game() -> void:
	game_state = "playing"
	death_overlay.visible = false
	hp = MAX_HP
	stamina = MAX_STAMINA
	invuln_timer = 0.0
	dash_timer = 0.0
	dash_cooldown_timer = 0.0
	jump_tier = 0
	stomp_tier = 0
	stomp_land_timer = 0.0
	player_body.position = spawn_pos
	vx = 0.0
	vy = 0.0
	hp_bar_fill.size.x = 206.0
	hp_text.text = "%d / %d" % [hp, MAX_HP]
	stamina_bar_fill.size.x = 206.0
	stamina_text.text = "100"


func _return_to_menu() -> void:
	get_tree().change_scene_to_file("res://control.tscn")


# ---------------------------------------------------------------------
# 1. SOLID BLUE BASEPLATE (FLAT UNLIT)
# ---------------------------------------------------------------------
func _setup_baseplate() -> void:
	var ground_body := StaticBody2D.new()
	ground_body.name = "Ground"
	add_child(ground_body)

	var total_w := arena_width + 200.0
	var ground_h := maxf(ground_height, 128.0)

	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(total_w, ground_h)
	col.shape = rect
	col.position = Vector2(arena_width * 0.5, floor_y + ground_h * 0.5)
	ground_body.add_child(col)

	var tex_top: Texture2D = load(GROUND_TOP_PATH) if ResourceLoader.exists(GROUND_TOP_PATH) else null
	var tex_spike: Texture2D = load(GROUND_SPIKE_PATH) if ResourceLoader.exists(GROUND_SPIKE_PATH) else tex_top
	var tex_spike_left: Texture2D = load(GROUND_SPIKE_LEFT_PATH) if ResourceLoader.exists(GROUND_SPIKE_LEFT_PATH) else tex_top
	var tex_spike_right: Texture2D = load(GROUND_SPIKE_RIGHT_PATH) if ResourceLoader.exists(GROUND_SPIKE_RIGHT_PATH) else tex_top
	var tex_under: Texture2D = load(GROUND_UNDER_PATH) if ResourceLoader.exists(GROUND_UNDER_PATH) else tex_top
	var grass_tex: Texture2D = load(GRASS_TEX_PATH) if ResourceLoader.exists(GRASS_TEX_PATH) else null

	if tex_top == null:
		var fallback := ColorRect.new()
		fallback.size = Vector2(total_w, ground_h)
		fallback.position = Vector2(-100.0, floor_y)
		fallback.color = Color(0.18, 0.22, 0.28)
		ground_body.add_child(fallback)
		return

	var tile_size := 32.0
	var start_x := -100.0
	var cols := int(ceil(total_w / tile_size))
	var rows := int(ceil(ground_h / tile_size))

	var center_col := int(round((arena_width * 0.68 - start_x) / tile_size))

	for r in rows:
		for c in cols:
			var tile_x := start_x + float(c) * tile_size
			var tile_y := floor_y + float(r) * tile_size
			var tile_center_x := tile_x + tile_size * 0.5

			var chosen_tex: Texture2D
			var is_underground := r > 0
			var is_border := false
			var under_spikes := (c >= center_col - 1 and c <= center_col + 1)

			if is_underground:
				chosen_tex = tex_under
			elif under_spikes:
				chosen_tex = tex_spike
			elif c == center_col - 2:
				chosen_tex = tex_spike_right
				is_border = true
			elif c == center_col + 2:
				chosen_tex = tex_spike_left
				is_border = true
			else:
				chosen_tex = tex_top

			var sp := Sprite2D.new()
			sp.texture = chosen_tex
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.centered = true
			sp.scale = Vector2(tile_size / float(chosen_tex.get_width()), tile_size / float(chosen_tex.get_height()))
			sp.position = Vector2(tile_x + tile_size * 0.5, tile_y + tile_size * 0.5)

			if is_underground:
				sp.rotation = deg_to_rad(90.0 * float(randi() % 4))
				sp.flip_h = randf() > 0.5
				sp.flip_v = randf() > 0.5
			elif not is_border:
				sp.flip_h = randf() > 0.5

			ground_body.add_child(sp)

			if not is_underground and not is_border and not under_spikes and grass_tex != null:
				if randf() < 0.72:
					var g_pivot := Node2D.new()
					g_pivot.position = Vector2(tile_center_x + randf_range(-5.0, 5.0), floor_y)
					add_child(g_pivot)

					var g_sp := Sprite2D.new()
					g_sp.texture = grass_tex
					g_sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
					g_sp.centered = false
					var gw := 32.0
					var gh := 24.0
					g_sp.scale = Vector2(gw / float(grass_tex.get_width()), gh / float(grass_tex.get_height()))
					g_sp.position = Vector2(-gw * 0.5, -gh)
					g_sp.flip_h = randf() > 0.5
					g_pivot.add_child(g_sp)

					grass_blades.append({
						"node": g_pivot,
						"x": g_pivot.position.x,
						"angle": 0.0,
						"vel": 0.0,
						"phase": randf() * TAU
					})

# ---------------------------------------------------------------------
# 2. GRAY PLAYER PILL (ANCHORED AT FEET)
# ---------------------------------------------------------------------
func _setup_player() -> void:
	player_body = CharacterBody2D.new()
	player_body.name = "Player"
	player_body.position = spawn_pos
	add_child(player_body)

	var col := CollisionShape2D.new()
	var cap := CapsuleShape2D.new()
	cap.radius = PLAYER_WIDTH * 0.5
	cap.height = PLAYER_HEIGHT
	col.shape = cap
	col.position = Vector2(0.0, -PLAYER_HEIGHT * 0.5)
	player_body.add_child(col)

	player_visual_pivot = Node2D.new()
	player_visual_pivot.name = "VisualPivot"
	player_body.add_child(player_visual_pivot)

	var sheet_tex: Texture2D
	if ResourceLoader.exists(PLAYER_SHEET_PATH):
		sheet_tex = load(PLAYER_SHEET_PATH)
	elif ResourceLoader.exists(PLAYER_TEMPLATE_PATH):
		sheet_tex = load(PLAYER_TEMPLATE_PATH)
	else:
		sheet_tex = _create_rect_texture(192, 240, Color(0.58, 0.60, 0.64))

	player_sprite = AnimatedSprite2D.new()
	player_sprite.name = "PlayerSprite_ReplaceMe"
	player_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	player_sprite.sprite_frames = _build_player_sprite_frames(sheet_tex)
	player_sprite.scale = Vector2(1.75, 1.75)
	player_sprite.offset = Vector2(0.0, -PLAYER_HEIGHT * 0.5)
	player_sprite.play("idle")
	player_visual_pivot.add_child(player_sprite)


func _build_player_sprite_frames(sheet: Texture2D) -> SpriteFrames:
	var sf := SpriteFrames.new()
	if sf.has_animation("default"):
		sf.remove_animation("default")

	_add_sheet_anim(sf, sheet, "idle", 0, 0, 4, 3.5, true)
	_add_sheet_anim(sf, sheet, "walk", 1, 0, 6, 10.0, true)
	_add_sheet_anim(sf, sheet, "sprint", 2, 0, 6, 15.0, true)
	_add_sheet_anim(sf, sheet, "crouch", 3, 0, 1, 6.0, false)
	_add_sheet_anim(sf, sheet, "crouch_walk", 3, 1, 4, 8.0, true)
	_add_sheet_anim(sf, sheet, "jump", 4, 0, 1, 8.0, false)
	_add_sheet_anim(sf, sheet, "fall", 4, 1, 1, 8.0, false)
	_add_sheet_anim(sf, sheet, "land", 4, 2, 1, 8.0, false)
	_add_sheet_anim(sf, sheet, "dash", 4, 3, 1, 12.0, false)
	_add_sheet_anim(sf, sheet, "stomp", 4, 4, 1, 12.0, false)
	_add_sheet_anim(sf, sheet, "stomp_land", 4, 5, 1, 10.0, false)

	return sf


func _add_sheet_anim(sf: SpriteFrames, sheet: Texture2D, anim_name: String, row: int, start_col: int, count: int, fps: float, loop: bool) -> void:
	sf.add_animation(anim_name)
	sf.set_animation_speed(anim_name, fps)
	sf.set_animation_loop(anim_name, loop)
	var fw := int(PLAYER_WIDTH)
	var fh := int(PLAYER_HEIGHT)
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2((start_col + i) * fw, row * fh, fw, fh)
		sf.add_frame(anim_name, atlas)


# ---------------------------------------------------------------------
# 3. SPIKES (PLACEHOLDER TRIANGLES)
# ---------------------------------------------------------------------
func _setup_spikes() -> void:
	var tile_size := 32.0
	var start_x := -100.0
	var center_col := int(round((arena_width * 0.68 - start_x) / tile_size))
	var snapped_spike_x := start_x + (float(center_col) + 0.5) * tile_size
	spikes_area = spawn_spike(Vector2(snapped_spike_x, floor_y), 3)

func spawn_spike(bottom_center_pos: Vector2, count: int = 3) -> Area2D:
	var spike := Area2D.new()
	spike.name = "spike"
	spike.position = bottom_center_pos
	add_child(spike)

	var single_w := 32.0
	var single_h := 34.0
	var total_w := single_w * float(maxi(1, count))

	# Hitbox proporțional cu numărul de țepi
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(total_w - 6.0, single_h - 6.0)
	col.shape = shape
	col.position = Vector2(0.0, -single_h * 0.5 + 3.0)
	spike.add_child(col)

	var spike_tex: Texture2D
	if ResourceLoader.exists(SPIKE_TEX_PATH):
		spike_tex = load(SPIKE_TEX_PATH)
	elif ResourceLoader.exists(SPIKE_TEMPLATE_PATH):
		spike_tex = load(SPIKE_TEMPLATE_PATH)

	if spike_tex != null:
		var start_x := -total_w * 0.5 + single_w * 0.5
		var scale_x := single_w / float(spike_tex.get_width())
		var scale_y := single_h / float(spike_tex.get_height())
		for i in count:
			var sp := Sprite2D.new()
			sp.name = "SpikePiece_%d" % i
			sp.texture = spike_tex
			sp.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sp.scale = Vector2(scale_x, scale_y)
			sp.flip_h = randf() > 0.5
			sp.position = Vector2(start_x + i * single_w, -single_h * 0.5)
			spike.add_child(sp)
	else:
		var fallback := Sprite2D.new()
		fallback.name = "SpikeSprite_ReplaceMe"
		fallback.texture = _create_spikes_texture(int(total_w), int(single_h), count, Color(0.90, 0.20, 0.25))
		fallback.offset = Vector2(0.0, -single_h * 0.5)
		spike.add_child(fallback)

	spike.body_entered.connect(_on_spike_entered)
	return spike


# ---------------------------------------------------------------------
# 4. TOP-LEFT HUD HEALTH BAR + SUBTLE TITLE
# ---------------------------------------------------------------------
func _setup_hud() -> void:
	var hud := CanvasLayer.new()
	hud.name = "HUD"
	add_child(hud)

	var title := Label.new()
	title.text = "DataRain"
	title.position = Vector2(24.0, 12.0)
	title.add_theme_font_size_override("font_size", 18)
	title.modulate = Color(0.85, 0.88, 0.94, 0.75)
	hud.add_child(title)

	# 1. Bara de HP (196x20 interior la (26, 50), chenar la (14, 38), text aliniat stânga)
	hp_bar_fill = ColorRect.new()
	hp_bar_fill.position = Vector2(26.0, 50.0)
	hp_bar_fill.size = Vector2(195.0, 20.0)
	hp_bar_fill.color = Color("b80606")
	hud.add_child(hp_bar_fill)

	if ResourceLoader.exists(HP_FRAME_PATH):
		var hp_frame := TextureRect.new()
		hp_frame.name = "HpFrame"
		hp_frame.texture = load(HP_FRAME_PATH)
		hp_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		hp_frame.stretch_mode = TextureRect.STRETCH_KEEP
		hp_frame.position = Vector2(14.0, 38.0)
		hud.add_child(hp_frame)

	hp_text = Label.new()
	hp_text.text = "100 / 100"
	hp_text.position = Vector2(32.0, 49.0)
	hp_text.size = Vector2(180.0, 20.0)
	hp_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hp_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hp_text.add_theme_font_size_override("font_size", 13)
	hp_text.add_theme_color_override("font_color", Color("4d0000"))
	hp_text.add_theme_constant_override("outline_size", 1)
	hp_text.add_theme_color_override("font_outline_color", Color("e02424"))
	hud.add_child(hp_text)

	# 2. Bara de Stamina (urcată cu 8px: interior 146x14 la (25, 79), chenar la (14, 68), text aliniat stânga)
	stamina_bar_fill = ColorRect.new()
	stamina_bar_fill.position = Vector2(25.0, 79.0)
	stamina_bar_fill.size = Vector2(146.0, 14.0)
	stamina_bar_fill.color = Color("8787ff")
	hud.add_child(stamina_bar_fill)

	if ResourceLoader.exists(STAMINA_FRAME_PATH):
		var stam_frame := TextureRect.new()
		stam_frame.name = "StaminaFrame"
		stam_frame.texture = load(STAMINA_FRAME_PATH)
		stam_frame.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		stam_frame.stretch_mode = TextureRect.STRETCH_KEEP
		stam_frame.position = Vector2(14.0, 68.0)
		hud.add_child(stam_frame)

	stamina_text = Label.new()
	stamina_text.text = "100"
	stamina_text.position = Vector2(30.0, 75.0)
	stamina_text.size = Vector2(130.0, 14.0)
	stamina_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamina_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	stamina_text.add_theme_font_size_override("font_size", 11)
	stamina_text.add_theme_color_override("font_color", Color("25256b"))
	stamina_text.add_theme_constant_override("outline_size", 1)
	stamina_text.add_theme_color_override("font_outline_color", Color("b0b0ff"))
	hud.add_child(stamina_text)

# ---------------------------------------------------------------------
# EXACT HTML5 PHYSICS & ANIMATION LOOP
# ---------------------------------------------------------------------
func _physics_process(dt: float) -> void:
	if shake_intensity > 0.0:
		shake_intensity = maxf(0.0, shake_intensity - 38.0 * dt)
		cam.offset = Vector2(randf_range(-shake_intensity, shake_intensity), randf_range(-shake_intensity, shake_intensity))
	else:
		cam.offset = Vector2.ZERO

	if game_state == "dead":
		if Input.is_physical_key_pressed(KEY_R) or Input.is_physical_key_pressed(KEY_ENTER):
			_retry_game()
		elif Input.is_physical_key_pressed(KEY_ESCAPE):
			_return_to_menu()
		return

	if invuln_timer > 0.0:
		invuln_timer = maxf(0.0, invuln_timer - dt)
		player_sprite.modulate.a = 0.4 if int(invuln_timer * 20.0) % 2 == 0 else 1.0
	else:
		player_sprite.modulate.a = 1.0

	var was_grounded := grounded
	var direction := Input.get_axis("move_left", "move_right")
	if direction != 0.0:
		player_state_direction = signf(direction)
		player_sprite.flip_h = player_state_direction < 0.0

	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer = JUMP_BUFFER_TIME
	else:
		jump_buffer_timer = maxf(0.0, jump_buffer_timer - dt)

	coyote_timer = COYOTE_TIME if grounded else maxf(0.0, coyote_timer - dt)

	if stomp_land_timer > 0.0:
		stomp_land_timer = maxf(0.0, stomp_land_timer - dt)
	if normal_land_timer > 0.0:
		normal_land_timer = maxf(0.0, normal_land_timer - dt)

	dash_cooldown_timer = maxf(0.0, dash_cooldown_timer - dt)

	var crouching := Input.is_action_pressed("crouch") and grounded
	if crouching:
		crouch_hold_timer += dt
	else:
		crouch_hold_timer = 0.0

	var wants_sprint := Input.is_action_pressed("sprint") and absf(direction) > 0.0 and grounded and not crouching
	var sprinting := wants_sprint and stamina > 1.0

	if sprinting:
		stamina = maxf(0.0, stamina - SPRINT_STAMINA_DRAIN * dt)
		stamina_regen_timer = STAMINA_REGEN_DELAY
	elif stamina_regen_timer > 0.0:
		stamina_regen_timer = maxf(0.0, stamina_regen_timer - dt)
	else:
		stamina = minf(MAX_STAMINA, stamina + STAMINA_REGEN_RATE * dt)

	if Input.is_action_just_pressed("dash") and dash_timer <= 0.0 and dash_cooldown_timer <= 0.0 and stomp_tier == 0 and stamina >= DASH_STAMINA_COST:
		stamina -= DASH_STAMINA_COST
		stamina_regen_timer = STAMINA_REGEN_DELAY
		dash_timer = DASH_DURATION
		dash_cooldown_timer = DASH_COOLDOWN
		vx = player_state_direction * DASH_SPEED
		vy = 0.0
		anim_scale_x = 1.38
		anim_scale_y = 0.74

	if dash_timer > 0.0:
		dash_timer = maxf(0.0, dash_timer - dt)
		vx = player_state_direction * DASH_SPEED
		vy = 0.0
	else:
		var target_speed := CROUCH_SPEED if crouching else (SPRINT_SPEED if sprinting else WALK_SPEED)
		if stomp_land_timer > 0.0:
			target_speed *= 0.35

		if direction != 0.0:
			var accel := (SPRINT_ACCEL if sprinting else GROUND_ACCEL) if grounded else AIR_ACCEL
			vx = _approach(vx, direction * target_speed, accel * dt)
		elif grounded:
			var friction := CROUCH_FRICTION if crouching else GROUND_FRICTION
			vx = _approach(vx, 0.0, friction * dt)
		else:
			vx = _approach(vx, 0.0, AIR_DRAG * dt)

		vx = clampf(vx, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)

	if jump_buffer_timer > 0.0 and stomp_tier == 0 and dash_timer <= 0.0:
		if coyote_timer > 0.0:
			if crouching and crouch_hold_timer >= SUPERJUMP_CHARGE_TIME:
				vy = -JUMP_SPEED * SUPERJUMP_SPEED_MULT
				anim_scale_x = 0.78
				anim_scale_y = 1.34
				crouch_hold_timer = 0.0
				jump_tier = 1
			else:
				vy = -JUMP_SPEED
				jump_tier = 0
				if sprinting and absf(vx) > WALK_SPEED:
					vx = clampf(vx * SPRINT_JUMP_BOOST, -MAX_HORIZONTAL_SPEED, MAX_HORIZONTAL_SPEED)
			grounded = false
			coyote_timer = 0.0
			jump_buffer_timer = 0.0
		elif has_double_jump:
			has_double_jump = false
			jump_buffer_timer = 0.0
			if jump_tier == 1 and stamina >= SUPER_DOUBLE_JUMP_COST:
				stamina -= SUPER_DOUBLE_JUMP_COST
				stamina_regen_timer = STAMINA_REGEN_DELAY
				vy = -JUMP_SPEED * SUPER_DOUBLE_JUMP_MULT
				jump_tier = 3
				anim_scale_x = 0.72
				anim_scale_y = 1.46
				shake_intensity = 3.5
			else:
				vy = -JUMP_SPEED * DOUBLE_JUMP_MULT
				jump_tier = 2
				anim_scale_x = 0.84
				anim_scale_y = 1.32

	if not grounded and dash_timer <= 0.0 and jump_tier > 0 and vy > 0.0 and Input.is_action_pressed("stomp"):
		stomp_tier = jump_tier

	if stomp_tier == 1:
		vx = _approach(vx, 0.0, GROUND_FRICTION * dt)
		vy = STOMP_SPEED
		anim_scale_x = 0.72
		anim_scale_y = 1.38
	elif stomp_tier == 2:
		vx = _approach(vx, 0.0, GROUND_FRICTION * 1.5 * dt)
		vy = MEGA_STOMP_SPEED
		anim_scale_x = 0.62
		anim_scale_y = 1.50
	elif stomp_tier == 3:
		vx = _approach(vx, 0.0, GROUND_FRICTION * 2.0 * dt)
		vy = SUPER_STOMP_SPEED
		anim_scale_x = 0.54
		anim_scale_y = 1.62

	if dash_timer <= 0.0 and stomp_tier == 0:
		var grav := GRAVITY
		if vy < 0.0 and not Input.is_action_pressed("jump"):
			grav *= JUMP_CUT_MULTIPLIER
		elif vy > 0.0:
			grav *= FALL_GRAVITY_MULTIPLIER
		vy = minf(vy + grav * dt, MAX_FALL_SPEED)

	var impact_speed := vy
	player_body.velocity = Vector2(vx, vy)
	last_impact_vy = maxf(vy, 0.0)
	player_body.move_and_slide()

	var half_w := PLAYER_WIDTH * 0.5
	player_body.position.x = clampf(player_body.position.x, half_w, arena_width - half_w)

	grounded = player_body.is_on_floor()
	if grounded:
		vy = 0.0
		coyote_timer = COYOTE_TIME
		has_double_jump = true
		if not was_grounded and stomp_tier == 0:
			normal_land_timer = NORMAL_LAND_DURATION
			if impact_speed > 320.0:
				landing_squash = minf(0.2, (impact_speed / MAX_FALL_SPEED) * 0.24)

		if stomp_tier == 1:
			landing_squash = 0.36
			stomp_land_timer = STOMP_LAND_DURATION
			shake_intensity = 5.0
		elif stomp_tier == 2:
			landing_squash = 0.50
			stomp_land_timer = MEGA_STOMP_LAND_DURATION
			shake_intensity = 8.5
		elif stomp_tier == 3:
			landing_squash = 0.62
			stomp_land_timer = SUPER_STOMP_LAND_DURATION
			shake_intensity = 14.0

		jump_tier = 0
		stomp_tier = 0
	else:
		vy = player_body.velocity.y
	vx = player_body.velocity.x

	state = _resolve_player_state(crouching, sprinting)
	if player_sprite.animation != state:
		player_sprite.play(state)

	_update_player_animation(dt)
	stamina_bar_fill.size.x = 148.0 * (stamina / MAX_STAMINA)
	stamina_text.text = "%d" % int(roundf(stamina))

func _resolve_player_state(crouching: bool, sprinting: bool) -> String:
	if dash_timer > 0.0:
		return "dash"
	if stomp_tier > 0:
		return "stomp"
	if stomp_land_timer > 0.0:
		return "stomp_land"
	if not grounded:
		return "jump" if vy < 0.0 else "fall"
	if crouching:
		return "crouch_walk" if absf(vx) > 5.0 else "crouch"
	if normal_land_timer > 0.0:
		return "land"
	var spd := absf(vx)
	if sprinting and spd > 8.0:
		return "sprint"
	if spd > 8.0:
		return "walk"
	return "idle"
func _update_player_animation(dt: float) -> void:
	if player_visual_pivot == null or player_sprite == null:
		return

	if absf(vx) > 5.0:
		player_state_direction = -1.0 if vx < 0.0 else 1.0
	player_sprite.flip_h = player_state_direction < 0.0

	var next_anim := "idle"
	var target_sx := 1.0
	var target_sy := 1.0
	var target_y_offset := 0.0
	var lerp_speed := 14.0

	if is_stomping or state == "stomp":
		next_anim = "stomp"
		target_sx = 0.90
		target_sy = 1.12
		lerp_speed = 24.0
	elif dash_timer > 0.0 or state == "dash":
		next_anim = "dash"
		target_sx = 1.0
		target_sy = 1.0
		lerp_speed = 28.0
	elif not grounded:
		var air_vy := player_body.velocity.y
		if air_vy <= -240.0:
			next_anim = "jump"
			target_y_offset = -1.5
		elif air_vy < 240.0:
			next_anim = "crouch"
			target_y_offset = -2.0
		else:
			next_anim = "fall"
			target_y_offset = 1.5
		target_sx = 1.0
		target_sy = 1.0
		lerp_speed = 18.0

	elif stomp_land_timer > 0.0:
		next_anim = "stomp_land"
		target_sx = 1.22
		target_sy = 0.78
		lerp_speed = 28.0
	elif normal_land_timer > 0.0:
		next_anim = "land"
		target_sx = 1.10
		target_sy = 0.90
		lerp_speed = 24.0
	elif state == "crouch_walk":
		next_anim = "crouch_walk"
		var c_phase := (float(player_sprite.frame) + player_sprite.frame_progress) * PI * 0.5
		var creep_wave := absf(sin(c_phase))
		target_sx = 1.04 + creep_wave * 0.03
		target_sy = 0.96 - creep_wave * 0.03
		lerp_speed = 16.0
	elif state == "crouch":
		next_anim = "crouch"
		target_sx = 1.06
		target_sy = 0.94
		lerp_speed = 18.0
	elif state == "sprint":
		next_anim = "sprint"
		var r_phase := (float(player_sprite.frame) + player_sprite.frame_progress) * (PI / 3.0)
		var run_wave := absf(sin(r_phase))
		target_sx = 1.0 + run_wave * 0.05
		target_sy = 1.0 - run_wave * 0.07
		lerp_speed = 20.0
	elif state == "walk":
		next_anim = "walk"
		var w_phase := (float(player_sprite.frame) + player_sprite.frame_progress) * (PI / 3.0)
		var walk_wave := absf(sin(w_phase))
		target_sx = 1.0 + walk_wave * 0.03
		target_sy = 1.0 - walk_wave * 0.04
		lerp_speed = 18.0
	else:
		next_anim = "idle"
		target_sx = 1.0
		target_sy = 1.0
		lerp_speed = 12.0

	if player_sprite.animation != next_anim:
		player_sprite.play(next_anim)

	anim_scale_x = lerpf(anim_scale_x, target_sx, clampf(dt * lerp_speed, 0.0, 1.0))
	anim_scale_y = lerpf(anim_scale_y, target_sy, clampf(dt * lerp_speed, 0.0, 1.0))
	player_visual_pivot.scale = Vector2(anim_scale_x, anim_scale_y)
	player_visual_pivot.rotation = 0.0
	player_visual_pivot.position.y = lerpf(player_visual_pivot.position.y, target_y_offset, clampf(dt * 14.0, 0.0, 1.0))

# ---------------------------------------------------------------------
# SPIKE DAMAGE & RESPAWN
# ---------------------------------------------------------------------
func _on_spike_entered(body: Node2D) -> void:
	if body != player_body or invuln_timer > 0.0:
		return

	var fall_bonus := 0
	if last_impact_vy > 400.0:
		fall_bonus = int(roundf(clampf((last_impact_vy - 400.0) / (SUPER_STOMP_SPEED - 400.0), 0.0, 1.0) * 75.0))

	var total_damage := SPIKE_DAMAGE + fall_bonus
	hp = maxi(hp - total_damage, 0)

	var knock_dir := -1.0 if player_body.position.x <= spikes_area.position.x else 1.0
	vx = SPIKE_KNOCKBACK.x * knock_dir
	vy = SPIKE_KNOCKBACK.y
	grounded = false

	if hp <= 0:
		game_state = "dead"
		death_overlay.visible = true
		vx = 0.0
		vy = 0.0

	hp_bar_fill.size.x = 206.0 * (float(hp) / float(MAX_HP))
	hp_text.text = "%d / %d" % [hp, MAX_HP]


# ---------------------------------------------------------------------
# HELPERS & PLACEHOLDER GEOMETRY TEXTURE GENERATORS
# ---------------------------------------------------------------------
func _approach(current: float, target: float, amount: float) -> float:
	if current < target:
		return minf(current + amount, target)
	return maxf(current - amount, target)


func _damp(current: float, target: float, smoothing: float, dt: float) -> float:
	return current + (target - current) * (1.0 - exp(-smoothing * dt))


func _create_rect_texture(w: int, h: int, col: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(col)
	return ImageTexture.create_from_image(img)


func _create_pill_texture(w: int, h: int, col: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var r := w * 0.5
	for y in h:
		for x in w:
			var dx := (x + 0.5) - r
			var dy := 0.0
			if y < r:
				dy = (y + 0.5) - r
			elif y > h - r:
				dy = (y + 0.5) - (h - r)
			if dx * dx + dy * dy <= r * r:
				img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)


func _create_spikes_texture(w: int, h: int, count: int, col: Color) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var spike_w := float(w) / float(count)
	for i in count:
		var center := i * spike_w + spike_w * 0.5
		for y in h:
			var half_span := (float(y) / float(h)) * (spike_w * 0.5)
			for x in range(int(center - half_span), int(center + half_span)):
				if x >= 0 and x < w:
					img.set_pixel(x, y, col)
	return ImageTexture.create_from_image(img)
