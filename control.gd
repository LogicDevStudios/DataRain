extends Control

func _ready() -> void:
	RenderingServer.set_default_clear_color(Color.BLACK)
	var screen_size := Vector2(1152.0, 648.0)

	var bg := ColorRect.new()
	bg.size = screen_size
	bg.color = Color.BLACK
	add_child(bg)

	var game_title := Label.new()
	game_title.text = "D A T A R A I N"
	game_title.position = Vector2(screen_size.x * 0.5 - 155.0, screen_size.y * 0.30)
	game_title.add_theme_font_size_override("font_size", 38)
	add_child(game_title)

	var play_btn := Button.new()
	play_btn.text = "PLAY"
	play_btn.position = Vector2(screen_size.x * 0.5 - 85.0, screen_size.y * 0.46)
	play_btn.size = Vector2(170.0, 46.0)
	play_btn.pressed.connect(_on_play_pressed)
	add_child(play_btn)

	var controls_lbl := Label.new()
	controls_lbl.text = "A/D Move  |  Ctrl Sprint  |  Shift Crouch  |  Space Jump  |  Q Dash  |  S Stomp"
	controls_lbl.position = Vector2(screen_size.x * 0.5 - 295.0, screen_size.y * 0.62)
	controls_lbl.add_theme_font_size_override("font_size", 14)
	controls_lbl.modulate = Color(0.7, 0.78, 0.88, 0.75)
	add_child(controls_lbl)


func _process(_dt: float) -> void:
	if Input.is_physical_key_pressed(KEY_ENTER) or Input.is_physical_key_pressed(KEY_SPACE):
		_on_play_pressed()


func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://main.tscn")
