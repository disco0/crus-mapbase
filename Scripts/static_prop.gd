extends QodotEntity

export (float) var PROP_SCALE = 0#  6.66
export (float) var TILT_DEG = 0 # 13.0
export (float) var ROT_DEG = 0 # -45.0

const PROP_MAP = {
	scale  = 'PROP_SCALE',
	tilt   = 'TILT_DEG',
	angle  = 'ROT_DEG',
}

func set_properties(new_properties : Dictionary) -> void:
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties() -> void:
	# print('[prop_logo:update_properties] Checking properties:')
	var retransform_required = false
	for prop_name in properties.keys():
		if PROP_MAP.has(prop_name):
			print('[prop_static:update_properties] - %s' % [ prop_name ])

			if self[PROP_MAP[prop_name]] != properties[prop_name]:
				print('[prop_static:update_properties]  %s -> %s' % [ self[PROP_MAP[prop_name]], properties[prop_name] ])
				self[PROP_MAP[prop_name]] = properties[prop_name]
				retransform_required = true
		else:
			pass
			# print('[prop_logo:update_properties] - %s [Unknown Key]' % [ prop_name ])

	if retransform_required:
		update_transform()

func _init() -> void:
	print('[staic_prop:on:init]')
	update_properties()

func _ready():
	# print('[prop_logo:on:ready]')
	update_properties()

func update_transform() -> void:
	print('[staic_prop:update_transform] Updating prop transformation.')
	transform.basis = Basis()
	scale_object_local(Vector3(PROP_SCALE, PROP_SCALE, PROP_SCALE))

	translate(Vector3(0, 0, 0))
	# global_translate(Vector3(18, 13, 0))
	rotate_object_local(Vector3(0, 1, 0), deg2rad(ROT_DEG))
	rotate_object_local(Vector3(1, 0, 0), deg2rad(TILT_DEG))

#region Damage Handling

# @TODO: Finish
func initialize_collision() -> void:
	var children = get_children()
	print('[staic_prop:initialize_collision] Checking %s child nodes for CollisionShape' % [ children.size() ])
	print_tree_pretty()
	for child in children:
		if child is CollisionShape:
			child.set_collision_mask_bit(0, 0)
			child.set_collision_mask_bit(1, 1)


#endregion Damage Handling
