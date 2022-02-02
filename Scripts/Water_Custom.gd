extends "res://Scripts/Water.gd"

const PLAYER_NODE_PATH = "res://Scripts/Player.gd"
onready var screenmat           = Global.screenmat
onready var water_rgb_mult_base = Vector3(0.5, 1.0, 2.0) #  get_tree().get_root().get_node("Mod/disk0s-map-addons/Init").WATER_RGB_MULT_BASE
onready var water_rgb_mult      = water_rgb_mult_base

func _ready():
	update_properties() 
	connect("area_exited",  self, "area_exited")

#region Collision Checks

# Check if node is noclip view by checking if node passed in is Water_Check (by checking for
# it's sibling Camera node)
func is_noclip_view(area: Area) -> bool:
	var children = area.get_parent().get_children()
	for child_idx in children.size():
		if children[child_idx] is Camera:
			return true
	return false

# Check if node is player camera
func is_player_node(node: Node) -> bool:
	if node.get_script():
		# print('[Water_Color] Node Script Path: <%s>' % [ node.get_script().get_path() ])
		# var spath = node.get_script().get_path()
		return node.get_script().get_path() == PLAYER_NODE_PATH
	return false

#endregion Collision Checks

#region Entity Properties

export (Dictionary) var properties = { }

const COLOR_SCALE_PROP = "color_scale"

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties():
	if COLOR_SCALE_PROP in properties:
		water_rgb_mult = properties[COLOR_SCALE_PROP]

func override_water_color() -> void:
	screenmat.set_shader_param("water_rgb_scale", water_rgb_mult)

func reset_water_color() -> void:
	screenmat.set_shader_param("water_rgb_scale", water_rgb_mult_base)

#endregion Entity Properties

#region Signal Handlers

func _on_Area_body_entered(body: Node) -> void:
	if is_player_node(body):
		override_water_color()

	._on_Area_body_entered(body)

func _on_Area_body_exited(body: Node) -> void:
	._on_Area_body_exited(body)

	if is_player_node(body):
		reset_water_color()

func area_entered(area: Area) -> void:
	if is_noclip_view(area):
		override_water_color()

	.area_entered(area)

func area_exited(area: Area) -> void:
	# (mimicking _on_Area_body_entered for now)
	if area.has_method("set_water"):
		area.set_water(false)

	if is_noclip_view(area):
		reset_water_color()


#endregion Signal Handlers
