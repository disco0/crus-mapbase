extends Node

const MOD_ID   = "mapbase"
const MODS_DIR = "res://MOD_CONTENT"
const MOD_BASE = MODS_DIR + "/" + MOD_ID
const MOD_ENT_BASE = MOD_BASE + "/Maps/entities"

func _init():
	dprint('Loading mod resources')
	# print_fs_tree(MOD_BASE)
	init_ents()
	load_shader()

#region Loader Subfunctions

var fgd: Resource

const ENTITIES := [
	"d_elevator_ext.tres",
	"e_pig.tres",
	"e_pig2.tres",
	"env_water_custom.tres",
	"light_dyn.tres",
	"o_pizza_full.tres",
	"o_forklift.tres",
	"o_copcar.tres",
	"obj_cult_leader.tres",
]

func init_ents() -> bool:
	if OS.has_feature("debug"):
		dprint('Entities should already be loaded in godot.', 'init_ents')
		return true
	if not is_instance_valid(fgd):
		fgd = load("res://addons/qodot/game-definitions/fgd/qodot_fgd.tres")
		if not is_instance_valid(fgd):
			dprint('ERROR: Failed to load qodot fgd file.', 'init_ents')
			return false
		
	var ent_path: String
	var ent_count = ENTITIES.size()
	var idx_fmt = '[%2d/%2d]'

	for ent_idx in ent_count:
		ent_path = ENTITIES[ent_idx]
		if not ent_path or ent_path.empty():
			dprint("%s - FAILED: Empty entity element at index %2d/%2d" % [
					idx_fmt %  [ ent_idx + 1, ent_count ],
					ent_idx, ent_count - 1
				], 'init_ents')

		if ent_path.is_rel_path():
			ent_path = MOD_ENT_BASE.plus_file(ent_path)

		dprint("%s - Loading: <%s>" % [
				idx_fmt %  [ ent_idx + 1, ent_count ],
				ent_path
			], 'init_ents')
		var ent_res = load(ent_path)

		if is_instance_valid(ent_res):
			fgd.entity_definitions.append(ent_res)
			dprint("%s   - Added: <%s>" % [
					idx_fmt %  [ ent_idx + 1, ent_count ],
					ent_res
				], 'init_ents')
			ent_path = ""
		else:
			dprint("%s  - FAILED: <%s>" % [
					idx_fmt %  [ ent_idx + 1, ent_count ],
					ent_res
				], 'init_ents')
			return false

	return true

func load_shader() -> bool:
	dprint(' -> Injecting PaletteLimiter shader:')

	var screenmat = Global.screenmat
	if not is_instance_valid(screenmat):
		dprint('  - ❌ Failed to access screenmat resource on Global')
		return false

	screenmat.shader.set_code(PALETTELIMITER_NEW_SRC)
	screenmat.set_shader_param("water_rgb_scale",  WATER_RGB_MULT_BASE)

	dprint('  - ✅ Injecting PaletteLimiter shader successful.')
	return true

# Base shader color for submerged water effect
const WATER_RGB_MULT_BASE = Vector3(0.5, 1.0, 2.0)

# New shader
# @TODO: Get loading via the actual .shader file smh
const PALETTELIMITER_NEW_SRC = """
shader_type canvas_item;
uniform bool  water            = false;
uniform bool  drugs            = false;
uniform bool  nightmare_vision = false;
uniform bool  rain             = false;
uniform bool  holy_mode        = false;
uniform bool  intro            = false;
uniform bool  scope            = false;
uniform float hit_red         = 0;
uniform float health_green    = 0;
uniform float amplitude       = 1;
uniform float gamma           = 1.0;
uniform float size_x          = 0.001;
uniform float size_y          = 0.001;
uniform vec3  water_rgb_scale;

uniform float u_amount = 1.0;

float get_noise(vec2 uv)
{
	return fract(sin(dot(uv, vec2(5.0, 0.0))) * 43758.5453);
}

void fragment()
{
	if (water || drugs)
	{
		vec2 uv = SCREEN_UV;
		uv.x = cos(SCREEN_UV.y * 2.0 + TIME) * 0.02;
		uv.y = sin(SCREEN_UV.x * 4.0 + TIME) * 0.03;
		COLOR = texture(SCREEN_TEXTURE, SCREEN_UV + uv);
		if (water)
		{
			COLOR.r = floor(COLOR.r * 255.0 / 16.0) / 255.0 * 16.0 * water_rgb_scale.x + hit_red - health_green;
			COLOR.g = floor(COLOR.g * 255.0 / 16.0) / 255.0 * 16.0 * water_rgb_scale.y + health_green;
			COLOR.b = floor(COLOR.b * 255.0 / 16.0) / 255.0 * 16.0 * water_rgb_scale.z - hit_red;
		}
		else
		{
			float old_r = COLOR.r;
			float old_g = COLOR.g;
			float old_b = COLOR.b;
			COLOR.r = old_g;
			COLOR.g = old_r;
		}
	}
	else if (intro)
	{
		vec2 uv = SCREEN_UV;
		uv.x = cos(SCREEN_UV.y + TIME + 5.0) * amplitude;
		uv.y = sin(SCREEN_UV.x + TIME) * amplitude;
		COLOR = texture(SCREEN_TEXTURE, SCREEN_UV + uv);
		COLOR.r *= 1.0 - amplitude;
		COLOR.g *= 1.0 - amplitude;
		COLOR.b *= 1.0 - amplitude;
	}
	else
	{
		COLOR = texture(SCREEN_TEXTURE, SCREEN_UV);
		COLOR.r = floor(COLOR.r * 255.0 / 16.0) / 255.0 * 16.0 + hit_red - health_green;
		COLOR.g = floor(COLOR.g * 255.0 / 16.0) / 255.0 * 16.0           + health_green;
		COLOR.b = floor(COLOR.b * 255.0 / 16.0) / 255.0 * 16.0 - hit_red;
	}

	if (scope == true)
	{
		COLOR.r = COLOR.r * 1.5;
		COLOR.g = COLOR.r;
		COLOR.b = COLOR.r;
	}
	if (holy_mode == true)
	{
		vec2 uv = SCREEN_UV;
		uv -= mod(uv, vec2(0.002, 0.002));
		COLOR.rgb = textureLod(SCREEN_TEXTURE, uv, 0.0).rgb;
		COLOR.r = 1.0 - step(COLOR.r - 0.5, 0.01);
		COLOR.g = 1.0 - step(COLOR.g - 0.5, 0.01);
		COLOR.b = 1.0 - step(COLOR.b - 0.5, 0.01);
	}
	if (nightmare_vision == true)
	{
		COLOR.r = step(COLOR.r + COLOR.b + COLOR.g, 0.5);
		COLOR.b = 0.0;
		COLOR.g = 0.0;
	}
	if (gamma != 1.0)
	{
		float gamma_correction = 1.0 / gamma;
		COLOR.r = clamp(COLOR.r, 0.0, 1.0);
		COLOR.b = clamp(COLOR.b, 0.0, 1.0);
		COLOR.g = clamp(COLOR.g, 0.0, 1.0);
		COLOR.r = 1.0 * pow((COLOR.r / 1.0), gamma_correction);
		COLOR.g = 1.0 * pow((COLOR.g / 1.0), gamma_correction);
		COLOR.b = 1.0 * pow((COLOR.b / 1.0), gamma_correction);
	}
	float n = 2.0 * get_noise(UV + vec2(TIME * 5.0, 0.0)) - 1.0;
	float alph = COLOR.a;
	COLOR = COLOR + n * u_amount;
	COLOR.a = alph;
}"""

#endregion Loader Subfunctions - PaletteLimiter.shader

#endregion Loader Subfunctions

#region Utils

func dprint(msg: String, ctx: String = "") -> void:
	# print(msg, MOD_ID + (":" + ctx if len(ctx) > 0 else ""))
	Mod.mod_log(msg, MOD_ID + (":" + ctx if len(ctx) > 0 else ""))

# (Because this isn't added in current upstream ModBase)
static func path_wrap(path_frag: String = "EMPTY") -> String:
	return "<%s>" % [ path_frag ]

func print_fs_tree(dirpath: String):
	print_fs_tree_rec(dirpath, dirpath)

func print_fs_tree_rec(dirpath: String, base: String, level := 0):
	var dir = Directory.new()
	if dir.open(dirpath) == OK:
		if level == 0:
			dprint('[tree]%s %s' % [ " ".repeat(level * 4), dirpath ])
		else:
			dprint('[tree]%s - %s' % [ " ".repeat(level * 4), dirpath.get_file() + "/" ])

		dir.list_dir_begin(true, true)
		var fname = dir.get_next()
		while fname != "":
			if dir.current_is_dir():
				print_fs_tree_rec("%s/%s" % [ dirpath, fname ], base, level + 1)
			else:
				dprint('[tree]%s - %s' % [ " ".repeat((level + 1) * 4), fname ])
			fname = dir.get_next()
		dir.list_dir_end()
	else:
		if level == 0:
			dprint('[tree] ERROR: Failed to get base directory <%s>' % [ base ])

#endregion Utils

