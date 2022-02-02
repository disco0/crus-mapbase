class_name QodotLightDyn
extends QodotEntity
tool 

var light_node: Light
var base_energy: float
var base_indirect_energy: float
var normalized_brightness: float
var light_brightness: float = DEFAULTS.LIGHT

# https://github.com/id-Software/Quake/blob/bf4ac424ce754894ac8f1dae6a3981954bc9852d/QW/client/bothdefs.h
const MAX_LIGHTSTYLES := 64
const DEFAULTS := { 
	LIGHT = 300.0,
	LIGHTSTYLE_STR = 'mmamammmmammamamaaamammma',
	INTERVAL       = 4,
	COLOR          = Color(1, 1, 1),
}
# Configured light style string (@TODO: Move to property)
var lightstyle: String = DEFAULTS.LIGHTSTYLE_STR
# Computed from lightstyle
var lightstyle_arr := PoolRealArray([])

var phys_idx  := 0
var style_idx := 0
var interval: int = DEFAULTS.INTERVAL

func _physics_process(delta: float) -> void:
	phys_idx = (phys_idx + 1) % interval
	if phys_idx != 0:
		return
		
	style_idx = (style_idx + 1) % len(lightstyle_arr)
	var curr_style: float = lightstyle_arr[style_idx]
	
	light_node.set_param(Light.PARAM_INDIRECT_ENERGY, base_indirect_energy * curr_style)
	light_node.set_param(Light.PARAM_ENERGY,          base_energy          * curr_style)

func _build_lightstyle_arr() -> void:
	# Reinit
	lightstyle_arr = PoolRealArray([])
	
	var j: int = 0
	var k: int
	
	# Emulate c-style char-int casts	
	var char_a: float = 'a'.to_ascii()[0]
	var char_m: float = 'm'.to_ascii()[0]
	var div:    float = char_m - char_a 
	
	# Build scales
	while j < MAX_LIGHTSTYLES:
		if j >= lightstyle.length():
			break
			
		k = lightstyle[j].to_ascii()[0] - char_a
		# Push new scaled value divided by base brightness letter ('m')
		lightstyle_arr.push_back(k / div)
		
		j += 1
	
	print('[light_dyn:_build_lightstyle_arr] Computed lightstyle: %s' % [ JSON.print(lightstyle_arr) ])

func _enter_tree() -> void:
	print('[light_dyn] enter_tree')
	set_physics_process(true)

func _ready() -> void:
	update_properties()
	_build_lightstyle_arr()
	
func update_properties():
	print('[light_dyn] update_properties')
	for child in get_children():
		remove_child(child)
		child.queue_free()
		
	interval = DEFAULTS.INTERVAL
	if 'interval' in properties:
		if typeof(properties["interval"]) == TYPE_INT:
			if properties["interval"] > 0:
				interval = properties["interval"]
			else:
				push_warning('WARNING: interval defined in light_dyn entity must be integer greater than zero (passed value: %d)' % [ properties["interval"] ])
				# Set default
		
	lightstyle = DEFAULTS.LIGHTSTYLE_STR
	if 'style' in properties:
		var style: String = properties["style"]
		if typeof(style) == TYPE_STRING:
			if style.length() > 0:
				# Save style, but cap to max length
				lightstyle = style.substr(0, min(style.length(), MAX_LIGHTSTYLES))
			else:
				push_warning('Defined style property in light_dyn is empty string, using default.')

	if "mangle" in properties:
		light_node = SpotLight.new()

		var yaw = properties["mangle"].x
		var pitch = properties["mangle"].y
		light_node.rotate(Vector3.UP, deg2rad(180 + yaw))
		light_node.rotate(light_node.global_transform.basis.x, deg2rad(180 + pitch))

		if "angle" in properties:
			light_node.set_param(Light.PARAM_SPOT_ANGLE, properties["angle"])
	else:
		print('[light_dyn] creating OmniLight')
		light_node = OmniLight.new()
	
	if "light" in properties:
		light_brightness = properties["light"]
	
	base_energy = light_brightness / 100.0
	light_node.set_param(Light.PARAM_ENERGY, base_energy)
	base_indirect_energy = light_brightness / 100.0
	light_node.set_param(Light.PARAM_INDIRECT_ENERGY, base_indirect_energy)

	var light_range: = 1.0
	if "wait" in properties:
		light_range = properties["wait"]

	normalized_brightness = light_brightness / 300.0
	light_node.set_param(Light.PARAM_RANGE, 16.0 * light_range * (normalized_brightness * normalized_brightness))

	var light_attenuation = 0
	if "delay" in properties:
		light_attenuation = properties["delay"]

	var attenuation: float = 0
	match light_attenuation:
		0:
			attenuation = 1.0
		1:
			attenuation = 0.5
		2:
			attenuation = 0.25
		3:
			attenuation = 0.15
		4:
			attenuation = 0.0
		5:
			attenuation = 0.9
		_:
			attenuation = 1.0

	light_node.set_param(Light.PARAM_ATTENUATION, attenuation)
	light_node.set_shadow(false)
	light_node.set_bake_mode(Light.BAKE_ALL)
	light_node.set_cull_mask(4294967293)

	var light_color = Color.white
	if "_color" in properties:
		light_color = properties["_color"]

	light_node.set_color(light_color)

	add_child(light_node)

	if is_inside_tree():
		var tree = get_tree()
		if tree:
			var edited_scene_root = tree.get_edited_scene_root()
			if edited_scene_root:
				light_node.set_owner(edited_scene_root)
