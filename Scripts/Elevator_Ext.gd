extends QodotEntity
#tool
var toolctx := Engine.editor_hint

# Alternate elevator implementation with additional control over speed/initial
# direction

# smh
class KinematicBodyInteractable extends KinematicBody:
	func use():
		self.get_parent().use()

	func stop():
		self.get_parent().stop()

# Have to instance now that class extends QodotSpatial
onready var kinematic := KinematicBodyInteractable.new()

var stopped := true
var initpos := true
var col     := false
var mesh_instance:    MeshInstance
var collision_area:   Area
var collision_object: CollisionShape
var bell_audio:       AudioStreamPlayer3D
var move_audio:       AudioStreamPlayer3D
var last_pos:         Vector3
var type = 1
func get_type() -> int:
	return type

# Replaces speed in original
onready var velocity: float = speed

#region logging/debugging
var debug: bool = false

func dprint(msg: String, ctx: String = "") -> void:
	if not debug: return
	Mod.mod_log('%s' % [ msg ],
			"Elevator_Ext" + ':' + ctx if len(ctx) > 0 else "Elevator_Ext")

var travel_start_time := -1

#endregion logging/debugging

#region Entity Properties

export (float) var speed = 0
export (int)   var init_up = 1
export (float) var move_pitch_scale = 1.0

const PROP_MAP = {
	speed  = 'speed',
	init_up   = 'init_up',
	move_pitch_scale = 'move_pitch_scale',
}

func set_properties(new_properties : Dictionary) -> void:
	# dprint('%s' % [ JSON.print(new_properties) ], 'set_properties')
	if(properties != new_properties):
		properties = new_properties
		update_properties()

func update_properties() -> void:
	# dprint('Checking properties for %s' % [ self.name ], 'update_properties')
	for prop_name in properties.keys():
		if PROP_MAP.has(prop_name):
			if self[PROP_MAP[prop_name]] != properties[prop_name]:
				dprint('- %s' % [ prop_name ], 'update_properties')
				dprint('%s -> %s' % [ self[PROP_MAP[prop_name]], properties[prop_name] ], 'update_properties')
				self[PROP_MAP[prop_name]] = properties[prop_name]
		else:
			pass

#endregion Entity Properties

#region Base Values

var SOUND_BASE = {
	MOVE = {
		DB = 2,
	},
	BELL = {
		DB = 3,
		UNIT_SIZE = 10,
	},
}

#endregion Base Values

# Just for debugging bug w/ offset initial positions
func _init() -> void:
	dprint('Updating properties', 'on:init')
	update_properties()

func _ready():
	dprint('Updating properties', 'on:ready')
	update_properties()
	
	# Immediately reparent mesh and collision nodes our replacement KinematicBody member (kinematic)
	# now that the script no longer directly extends KinematicBody, and then add kinematic back
	# itself as a child
	for child in self.get_children():
		self.remove_child(child)
		kinematic.add_child(child)

	self.add_child(kinematic)

	if init_up != 0:
		dprint('@%s Setting initial vertical velocity to upward direction (%s)' % [ self.name, init_up ], 'on:ready')
		velocity *= -1
	else:
		pass
		dprint('@%s Setting initial vertical velocity to downward direction (%s)' % [ self.name, init_up ], 'on:ready')

	# dprint('@%s Initial elevator speed: %s (Prop: %s)' % [ self.name, velocity, speed ], 'on:ready')

	for child in kinematic.get_children():
		if child is MeshInstance:
			dprint('Matched new mesh_instance member value (@%s)' % [ child.name ], 'on:ready')
			mesh_instance = child
			break

	kinematic.set_collision_mask_bit(9, 1)
	kinematic.set_collision_mask_bit(8, 1)
	kinematic.set_collision_layer_bit(8, 1)
	kinematic.set_collision_mask_bit(0, 0)

	bell_audio = AudioStreamPlayer3D.new()
	add_child(bell_audio)
	bell_audio.unit_size = SOUND_BASE.BELL.UNIT_SIZE
	bell_audio.unit_db   = SOUND_BASE.BELL.DB
	bell_audio.global_transform.origin = global_transform.origin

	move_audio = bell_audio.duplicate()
	add_child(move_audio)
	move_audio.unit_db      = SOUND_BASE.MOVE.DB
	move_audio.pitch_scale *= move_pitch_scale

	bell_audio.stream = load("res://Sfx/Environment/Elevator_Bell.wav")
	move_audio.stream = load("res://Sfx/Environment/Elevator_Move.wav")

	dprint('End of _ready global position for %s -> %s' % [ self.name, global_transform.origin ], 'on:ready')
	return
	
func _process(delta: float) -> void:
	last_pos = global_transform.origin
	if not stopped:
		if not move_audio.playing:
			move_audio.play()
		translate(Vector3(0, velocity * delta, 0))

func stop():
#	dump_stopper_check('stop')
	stopped = true
	initpos = not initpos

	velocity *= -1

	bell_audio.play()
	move_audio.stop()

	if debug:
		dprint('Elevator stopped after %sms of travel at postition [%s], new speed value: %s' % [
			 (OS.get_ticks_msec() - travel_start_time if travel_start_time != -1
					else "??"),
			global_transform.origin,
			velocity
		], 'stop')

	travel_start_time = -1

func use():
	travel_start_time = OS.get_ticks_msec()
	stopped = false
	dprint('Elevator activated with set speed %s' % [ velocity ], 'use')
