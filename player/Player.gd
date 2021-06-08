extends KinematicBody

enum {
	STANDING,
	WALKING,
	RUNNING,
	AIMING
	SLIDING,
	GRAPPLING
}

var state = STANDING

var direction = Vector3.FORWARD
var velocity = Vector3.ZERO
var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var movement_speed = 0
var walk_speed = 4
var run_speed = 7
var grapple_speed = 15
var jump_magnitude = 12

var acceleration = 6
var angular_acceleration = 10
var vertical_velocity = 0
var gravity = 20

var aim_turn = 0

var slide_cam_speed = 10
var slide_magnitude = 15

var grapple_hook = null
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("grapple") && $Camroot/h/v/grappling.is_colliding():
			grapple_hook = $Camroot/h/v/grappling.get_collision_point()
		if event.is_action_released("grapple"):
			grapple_hook = null
			
		if event.is_action_pressed("hit"):
			if state != SLIDING && state != GRAPPLING:
				$Mesh/t_pose/AnimationTree.set("parameters/hit/active", true)
	
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015
	
	if event is InputEventKey:		
	# AFFICHAGE DES INPUTS
	
		if event.as_text() == "Z" || event.as_text() == "S" || event.as_text() == "Q" || event.as_text() == "D" || event.as_text() == "Space" || event.as_text() == "Shift" || event.as_text() == "Alt":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")
				
	# FIN DE L'AFFICHAGE DES INPUTS

		if !$Mesh/t_pose/AnimationTree.get("parameters/slide/active"):
			if event.is_action_pressed("slide") && state == RUNNING:
				if $slide_window.is_stopped():
					$slide_window.start()
			if event.is_action_released("slide") && state == RUNNING:
				if !$slide_window.is_stopped():
					velocity = direction * slide_magnitude
					$slide_window.stop()
					$slide_duration.start()
					$Mesh/t_pose/AnimationTree.set("parameters/slide/active", true)
					$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 1)
		
func _physics_process(delta):
	# AFFICHAGE DU DEBUG
	$is_grounded.text = "Is grounded ? : " + str(is_on_floor())
	$is_grappling.text = "Target : " + str(grapple_hook)
	# FIN DE L'AFFICHAGE DU DEBUG
	
	# INITIALISATION DU STATE	
	# STANDING STATE
	if $slide_duration.is_stopped():
		state = STANDING
	# SLIDING STATE
	else:
		state = SLIDING
	
	# AIMING STATE
	if Input.is_action_pressed("aim"):		
		if state != SLIDING && $touch_floor.is_colliding():
			state = AIMING

	# WALKING STATE
	if Input.is_action_pressed("forward") || Input.is_action_pressed("backward") || Input.is_action_pressed("right") || Input.is_action_pressed("left"):
		if state != SLIDING && state != AIMING:
			state = WALKING

	# RUNNING STATE
	if Input.is_action_pressed("sprint") && state == WALKING:
		state = RUNNING
	
	# GRAPPLING STATE
	if grapple_hook != null:
		state = GRAPPLING

	#BEGIN
	movement_speed = walk_speed
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if !$Mesh/t_pose/AnimationTree.get("parameters/hit/active"):
		$Mesh/t_pose/Armature/Skeleton/BoneAttachment/blade.isHitting = false
	else:
		$Mesh/t_pose/Armature/Skeleton/BoneAttachment/blade.isHitting = true

	if $touch_floor.is_colliding():
		if Input.is_action_just_pressed("jump"):
			vertical_velocity = -jump_magnitude

	#STATE CHECK
	if state == SLIDING || state == WALKING || state == RUNNING:
		direction = Vector3(
			Input.get_action_strength("left") - Input.get_action_strength("right"), 
			0,
			Input.get_action_strength("forward") - Input.get_action_strength("backward")
		)	
		strafe_dir = direction		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()	

	
	if state == RUNNING || state == SLIDING:
		movement_speed = run_speed
		
	if state == SLIDING:
		acceleration = 6
		$Camroot/h/v.translation = Vector3(0, lerp($Camroot/h/v.translation.y, 0.4, slide_cam_speed * delta), 0)
		$CollisionShape.shape.height = 0.4
		$CollisionShape.translation = Vector3(0, 0.6, 0)
	else:
		acceleration = 11
		$Camroot/h/v.translation = Vector3(0, lerp($Camroot/h/v.translation.y, 2.4, slide_cam_speed * delta), 0)
		$CollisionShape.shape.height = 1.4
		$CollisionShape.translation = Vector3(0, 1.1, 0)

	if state == STANDING:
		movement_speed = 0
		$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($Mesh/t_pose/AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		strafe_dir = Vector3.ZERO

	if state == AIMING:
		$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 0)

		if movement_speed == 0:
			direction = $Camroot/h.global_transform.basis.z
	else:
		$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 1)

	if state == WALKING:
		$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($Mesh/t_pose/AnimationTree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
	
	if state == RUNNING:
		$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($Mesh/t_pose/AnimationTree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))

	if state == GRAPPLING:
		movement_speed = grapple_speed
		direction = grapple_hook - translation
		direction = direction.normalized()
		var grapple_base = $Mesh/t_pose/Armature/Skeleton/grapple.translation
		$Mesh/t_pose/Armature/Skeleton/grapple/Spatial/MeshInstance.look_at(grapple_hook, Vector3.UP)
		var distance = grapple_base.distance_to(grapple_hook)
		$Mesh/t_pose/Armature/Skeleton/grapple/Spatial/MeshInstance.scale = Vector3(1, 1, distance)
		$Mesh/t_pose/Armature/Skeleton/grapple/Spatial/MeshInstance.translation = Vector3(0, 0, distance/2)
	# END STATE CHECK	

	# ALWAYS	
	velocity = lerp(velocity, direction * movement_speed, delta * acceleration)
	
	var iw_blend = (velocity.length() - walk_speed) / walk_speed
	var wr_blend = (velocity.length() - walk_speed) / (run_speed - walk_speed)
	
	if velocity.length() <= walk_speed:
		$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", iw_blend)
	else:
		$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", wr_blend)
	
	move_and_slide(velocity + Vector3.DOWN * vertical_velocity, Vector3.UP)

	if !is_on_floor():
		vertical_velocity += delta * gravity
			
		if !$touch_floor.is_colliding():
			$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 2)
	else:
		if $slide_duration.is_stopped():
			vertical_velocity = 0.1
		else:
			vertical_velocity = 4
		
	if $Mesh/t_pose/AnimationTree.get("parameters/aim_transition/current") == 1:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, atan2(direction.x, direction.z), delta * angular_acceleration)
	else:
		$Mesh.rotation.y = lerp_angle($Mesh.rotation.y, h_rot, delta * angular_acceleration)

	strafe = lerp(strafe, strafe_dir + Vector3.RIGHT * aim_turn, delta * acceleration)
	$Mesh/t_pose/AnimationTree.set("parameters/strafing/blend_position", Vector2(-strafe.x, strafe.z))

	aim_turn = 0	
	$is_grappling.text = "DIR : " + str(direction)
