extends Spatial

var camrot_h = 0
var camrot_v = 0

var min_cam_v = -55
var max_cam_v = 75

var h_sensitivity = 0.1
var v_sensitivity = 0.1

var h_acceleration = 10
var v_acceleration = 10

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	$h/v/Camera.add_exception(get_parent())
	
func _input(event):
	if event is InputEventMouseMotion:
		$mouse_control_stay_delay.start()
		camrot_h += -event.relative.x * h_sensitivity
		camrot_v += event.relative.y * v_sensitivity

func _physics_process(delta):
	camrot_v = clamp(camrot_v, min_cam_v, max_cam_v)
	
	var mesh_front = get_node("../Mesh").global_transform.basis.z
	var rot_speed_multiplier = 0.15
	var auto_rotate_speed= (PI - mesh_front.angle_to($h.global_transform.basis.z)) * get_parent().velocity.length() * rot_speed_multiplier
	
	if $mouse_control_stay_delay.is_stopped():
		$h.rotation.y = lerp_angle($h.rotation.y, get_node("../Mesh").global_transform.basis.get_euler().y, delta * auto_rotate_speed)
		camrot_h = $h.rotation_degrees.y
	else:
		$h.rotation_degrees.y = lerp($h.rotation_degrees.y, camrot_h, delta * h_acceleration)
	
	$h/v.rotation_degrees.x = lerp($h/v.rotation_degrees.x, camrot_v, delta * v_acceleration)
