extends Node3D

const SAVE_PATH := "user://nightclub_empire_save.json"
const STARTING_CASH := 500.0

var cash: float = STARTING_CASH
var reputation: int = 1
var satisfaction: int = 75
var dance_level: int = 1
var bar_level: int = 1
var vip_level: int = 0
var club_open := true
var income_timer := 0.0
var animation_time := 0.0
var visitor_count := 8
var customers: Array[Node3D] = []
var hud: CanvasLayer
var cash_label: Label
var stats_label: Label
var status_label: Label
var message_label: Label
var buttons: Dictionary = {}

func _ready() -> void:
	_load_game()
	_build_world()
	_build_hud()
	_update_hud()
	set_process(true)

func _process(delta: float) -> void:
	animation_time += delta
	if club_open:
		income_timer += delta
		if income_timer >= 1.0:
			income_timer = 0.0
			var visitors := maxi(2, visitor_count + reputation)
			cash += float(visitors) * (0.7 + float(bar_level) * 0.55 + float(vip_level) * 0.8)
			if satisfaction < 98:
				satisfaction += 1
			_update_hud()
	for i in range(customers.size()):
		var person := customers[i]
		if is_instance_valid(person):
			var phase := animation_time * (2.4 + float(i % 3) * 0.25) + float(i) * 1.7
			person.position.y = 0.52 + absf(sin(phase)) * 0.15
			person.rotation.y = sin(phase * 0.35) * 0.25

func _build_world() -> void:
	var world_env := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.035, 0.025, 0.09)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.72, 0.68, 0.95)
	env.ambient_light_energy = 0.9
	world_env.environment = env
	add_child(world_env)

	var camera := Camera3D.new()
	camera.position = Vector3(11, 13, 15)
	camera.look_at(Vector3(0, 0.4, 0))
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.5
	add_child(camera)
	camera.current = true

	_add_box("ClubFloor", Vector3(0, -0.22, 0), Vector3(12, 0.4, 10), Color(0.12, 0.09, 0.22))
	_add_box("BackWall", Vector3(0, 1.5, -5), Vector3(12, 3.2, 0.25), Color(0.15, 0.08, 0.3))
	_add_box("LeftWall", Vector3(-6, 1.5, 0), Vector3(0.25, 3.2, 10), Color(0.12, 0.07, 0.25))
	_add_box("DanceFloor", Vector3(-1.2, 0.02, 0.2), Vector3(5.5, 0.12, 4.8), Color(0.12, 0.28, 0.55))
	# Coloured floor tiles make the dance floor read clearly from the isometric camera.
	for x in range(4):
		for z in range(3):
			var tile_color := Color(0.12, 0.55, 0.95) if (x + z) % 2 == 0 else Color(0.55, 0.16, 0.78)
			_add_box("DanceTile_%d_%d" % [x, z], Vector3(-3.05 + float(x) * 1.25, 0.105, -1.25 + float(z) * 1.35), Vector3(1.12, 0.035, 1.2), tile_color, true)
	_add_box("DJStage", Vector3(-1.2, 0.48, -3.2), Vector3(3.7, 0.9, 1.1), Color(0.35, 0.08, 0.48))
	_add_box("DJConsole", Vector3(-1.2, 1.1, -3.0), Vector3(2.4, 0.35, 0.55), Color(0.08, 0.08, 0.16))
	_add_box("BarCounter", Vector3(3.5, 0.55, -2.2), Vector3(3.4, 1.1, 1.1), Color(0.42, 0.16, 0.22))
	_add_box("BarTop", Vector3(3.5, 1.15, -2.2), Vector3(3.6, 0.16, 1.25), Color(0.95, 0.42, 0.7), true)
	_add_box("VIPPlatform", Vector3(3.2, 0.18, 2.8), Vector3(4.3, 0.35, 2.5), Color(0.28, 0.13, 0.38))
	_add_box("VIPSofa", Vector3(3.2, 0.65, 2.8), Vector3(2.8, 0.65, 0.75), Color(0.65, 0.2, 0.38))
	_add_box("EmpireSign", Vector3(0, 2.8, -4.78), Vector3(4.2, 0.65, 0.12), Color(0.95, 0.18, 0.62), true)
	for x in [-4.0, -2.0, 0.0, 2.0, 4.0]:
		_add_box("NeonStrip", Vector3(x, 0.12, -4.65), Vector3(0.08, 0.06, 0.35), Color(0.1, 0.9, 1.0), true)
	for i in range(8):
		var row := int(i / 4)
		_spawn_customer(Vector3(-3.2 + float(i % 4) * 1.3, 0.55, -0.8 + float(row) * 1.5))
	_add_light(Vector3(-1, 4, -2), Color(0.3, 0.25, 1.0), 5.0)
	_add_light(Vector3(3, 3, 1), Color(1.0, 0.15, 0.55), 4.0)
	_add_light(Vector3(-4, 3, 2), Color(0.1, 0.75, 1.0), 3.5)

func _material(color: Color, glow := false) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	if glow:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 1.8
	return mat

func _add_box(label: String, pos: Vector3, size: Vector3, color: Color, glow := false) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = label
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _material(color, glow)
	add_child(instance)
	return instance

func _spawn_customer(pos: Vector3) -> void:
	var person := Node3D.new()
	person.position = pos
	add_child(person)
	var body := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = 0.22
	capsule.height = 0.8
	body.mesh = capsule
	var palette := [Color(1.0, 0.35, 0.55), Color(0.25, 0.8, 1.0), Color(1.0, 0.7, 0.2), Color(0.55, 0.9, 0.45)]
	body.material_override = _material(palette[customers.size() % palette.size()])
	person.add_child(body)
	var head := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	head.mesh = sphere
	head.position.y = 0.48
	head.material_override = _material(Color(1.0, 0.75, 0.58))
	person.add_child(head)
	customers.append(person)

func _add_light(pos: Vector3, color: Color, energy: float) -> void:
	var light := OmniLight3D.new()
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = 9.0
	add_child(light)

func _build_hud() -> void:
	hud = CanvasLayer.new()
	add_child(hud)
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	hud.add_child(root)

	var title := Label.new()
	title.text = "NIGHTCLUB EMPIRE"
	title.position = Vector2(22, 20)
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", Color(1.0, 0.55, 0.85))
	root.add_child(title)

	cash_label = Label.new()
	cash_label.position = Vector2(24, 62)
	cash_label.add_theme_font_size_override("font_size", 25)
	cash_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.35))
	root.add_child(cash_label)

	stats_label = Label.new()
	stats_label.position = Vector2(24, 101)
	stats_label.add_theme_font_size_override("font_size", 16)
	stats_label.add_theme_color_override("font_color", Color(0.8, 0.86, 1.0))
	root.add_child(stats_label)

	status_label = Label.new()
	status_label.position = Vector2(24, 137)
	status_label.add_theme_font_size_override("font_size", 15)
	status_label.add_theme_color_override("font_color", Color(0.5, 1.0, 0.75))
	root.add_child(status_label)

	message_label = Label.new()
	message_label.position = Vector2(24, 164)
	message_label.add_theme_font_size_override("font_size", 14)
	message_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.4))
	root.add_child(message_label)

	var panel := VBoxContainer.new()
	panel.anchor_left = 0.025
	panel.anchor_top = 0.69
	panel.anchor_right = 0.975
	panel.anchor_bottom = 0.985
	panel.add_theme_constant_override("separation", 7)
	root.add_child(panel)
	_add_button(panel, "dance", "DANCE FLOOR")
	_add_button(panel, "bar", "BAR")
	_add_button(panel, "vip", "VIP LOUNGE")
	_add_button(panel, "toggle", "OPEN / CLOSE CLUB")
	_add_button(panel, "save", "SAVE GAME")

func _add_button(parent: VBoxContainer, action: String, caption: String) -> void:
	var button := Button.new()
	button.name = action
	button.custom_minimum_size = Vector2(0, 48)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.add_theme_font_size_override("font_size", 17)
	button.add_theme_color_override("font_color", Color.WHITE)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.28, 0.1, 0.43)
	style.set_corner_radius_all(12)
	style.content_margin_left = 14
	style.content_margin_right = 14
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate()
	hover.bg_color = Color(0.48, 0.14, 0.56)
	button.add_theme_stylebox_override("hover", hover)
	button.pressed.connect(_on_action.bind(action))
	parent.add_child(button)
	buttons[action] = button

func _on_action(action: String) -> void:
	message_label.text = ""
	match action:
		"dance":
			var cost := _dance_cost()
			if _spend(cost):
				dance_level += 1
				reputation += 1
				satisfaction = mini(100, satisfaction + 3)
				_add_box("DanceUpgrade_%d" % dance_level, Vector3(-1.2, 0.17, 0.2), Vector3(5.5, 0.08, 4.8), Color(0.25, 0.42, 0.95), true)
		"bar":
			var cost := _bar_cost()
			if _spend(cost):
				bar_level += 1
				satisfaction = mini(100, satisfaction + 5)
				_add_box("BarUpgrade_%d" % bar_level, Vector3(3.5, 1.25 + float(bar_level) * 0.05, -2.2), Vector3(3.6, 0.12, 1.25), Color(0.95, 0.35, 0.65), true)
		"vip":
			var cost := _vip_cost()
			if _spend(cost):
				vip_level += 1
				reputation += 2
				_add_box("VIPUpgrade_%d" % vip_level, Vector3(3.2, 0.95 + float(vip_level) * 0.08, 2.8), Vector3(2.8, 0.18, 0.75), Color(0.85, 0.55, 0.25), true)
		"toggle":
			club_open = not club_open
			message_label.text = "The club is now %s." % ("open" if club_open else "closed")
		"save":
			_save_game()
	_update_hud()

func _dance_cost() -> int:
	return 100 + dance_level * 125

func _bar_cost() -> int:
	return 150 + bar_level * 175

func _vip_cost() -> int:
	return 500 + vip_level * 400

func _spend(amount: int) -> bool:
	if cash < float(amount):
		message_label.text = "Not enough cash. You need $%d." % amount
		return false
	cash -= float(amount)
	message_label.text = "Upgrade purchased!"
	return true

func _update_hud() -> void:
	if not is_instance_valid(cash_label):
		return
	cash_label.text = "CASH  $%s" % _format_cash(cash)
	stats_label.text = "REP %d   HAPPINESS %d%%   GUESTS %d" % [reputation, satisfaction, visitor_count]
	status_label.text = ("● CLUB OPEN  •  EARNING MONEY" if club_open else "● CLUB CLOSED  •  INCOME PAUSED")
	if buttons.has("dance"):
		buttons["dance"].text = "DANCE FLOOR  •  $%d  •  LVL %d" % [_dance_cost(), dance_level]
		buttons["bar"].text = "UPGRADE BAR  •  $%d  •  LVL %d" % [_bar_cost(), bar_level]
		buttons["vip"].text = "VIP LOUNGE  •  $%d  •  LVL %d" % [_vip_cost(), vip_level]
		buttons["toggle"].text = "CLOSE CLUB" if club_open else "OPEN CLUB"

func _format_cash(value: float) -> String:
	return str(int(value))

func _save_game() -> void:
	var data := {
		"cash": cash, "reputation": reputation, "satisfaction": satisfaction,
		"dance_level": dance_level, "bar_level": bar_level, "vip_level": vip_level,
		"club_open": club_open
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		message_label.text = "GAME SAVED SUCCESSFULLY"
	else:
		message_label.text = "Could not save game."

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	var parsed = JSON.parse_string(file.get_as_text())
	if typeof(parsed) == TYPE_DICTIONARY:
		cash = float(parsed.get("cash", cash))
		reputation = int(parsed.get("reputation", reputation))
		satisfaction = int(parsed.get("satisfaction", satisfaction))
		dance_level = int(parsed.get("dance_level", dance_level))
		bar_level = int(parsed.get("bar_level", bar_level))
		vip_level = int(parsed.get("vip_level", vip_level))
		club_open = bool(parsed.get("club_open", club_open))
