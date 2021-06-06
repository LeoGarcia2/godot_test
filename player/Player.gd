extends KinematicBody

var direction = Vector3.FORWARD

var movement_speed = 0
var walk_speed = 4
var run_speed = 7

var velocity = Vector3.ZERO
var acceleration = 6
var vertical_velocity = 0
var gravity = 20
var jump_force = 12
var angular_acceleration = 10

var strafe_dir = Vector3.ZERO
var strafe = Vector3.ZERO

var aim_turn = 0

var slide_cam_speed = 10
var slide_magnitude = 15
	
func _input(event):
	if event is InputEventMouseButton:
		if event.is_action_pressed("hit"):
			if !$Mesh/t_pose/AnimationTree.get("parameters/slide/active"):
				$Mesh/t_pose/AnimationTree.set("parameters/hit/active", true)
	
	if event is InputEventMouseMotion:
		aim_turn = -event.relative.x * 0.015
	
	if event is InputEventKey:		
		if event.as_text() == "Z" || event.as_text() == "S" || event.as_text() == "Q" || event.as_text() == "D" || event.as_text() == "Space" || event.as_text() == "Shift" || event.as_text() == "Alt":
			if event.pressed:
				get_node("Status/" + event.as_text()).color = Color("ff6666")
			else:
				get_node("Status/" + event.as_text()).color = Color("ffffff")
		
		if !$Mesh/t_pose/AnimationTree.get("parameters/slide/active"):
			if event.is_action_pressed("slide") && movement_speed == run_speed:
				if $slide_window.is_stopped():
					$slide_window.start()
			if event.is_action_released("slide") && movement_speed == run_speed:
				if !$slide_window.is_stopped():
					velocity = direction * slide_magnitude
					$slide_window.stop()
					$slide_duration.start()
					$Mesh/t_pose/AnimationTree.set("parameters/slide/active", true)
					$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 1)
		
func _physics_process(delta):
	$is_grounded.text = "Is grounded ? : " + str(is_on_floor())
	if $slide_duration.is_stopped():
		$Camroot/h/v.translation = Vector3(0, lerp($Camroot/h/v.translation.y, 2.4, slide_cam_speed * delta), 0)
		$CollisionShape.shape.height = 1.4
		$CollisionShape.translation = Vector3(0, 1.1, 0)
	else:
		$Camroot/h/v.translation = Vector3(0, lerp($Camroot/h/v.translation.y, 0.4, slide_cam_speed * delta), 0)
		$CollisionShape.shape.height = 0.4
		$CollisionShape.translation = Vector3(0, 0.6, 0)
	
	var h_rot = $Camroot/h.global_transform.basis.get_euler().y
	
	if !$Mesh/t_pose/AnimationTree.get("parameters/slide/active"):
		acceleration = 11
	else:
		acceleration = 6
	
	if Input.is_action_pressed("aim"):		
		if !$Mesh/t_pose/AnimationTree.get("parameters/slide/active") && is_on_floor():
			$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 0)
	else:
		$Mesh/t_pose/AnimationTree.set("parameters/aim_transition/current", 1)
	if $touch_floor.is_colliding():
		if Input.is_action_just_pressed("jump"):
			vertical_velocity = -jump_force
			
	if Input.is_action_pressed("forward") || Input.is_action_pressed("backward") || Input.is_action_pressed("right") || Input.is_action_pressed("left"):		
		direction = Vector3(
			Input.get_action_strength("left") - Input.get_action_strength("right"), 
			0,
			Input.get_action_strength("forward") - Input.get_action_strength("backward")
		)
		
		strafe_dir = direction
		
		direction = direction.rotated(Vector3.UP, h_rot).normalized()
	
		if Input.is_action_pressed("sprint") && $Mesh/t_pose/AnimationTree.get("parameters/aim_transition/current") == 1:
			movement_speed = run_speed
			$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($Mesh/t_pose/AnimationTree.get("parameters/iwr_blend/blend_amount"), 1, delta * acceleration))
		else:
			movement_speed = walk_speed
			$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($Mesh/t_pose/AnimationTree.get("parameters/iwr_blend/blend_amount"), 0, delta * acceleration))
	else:
		movement_speed = 0
		$Mesh/t_pose/AnimationTree.set("parameters/iwr_blend/blend_amount", lerp($Mesh/t_pose/AnimationTree.get("parameters/iwr_blend/blend_amount"), -1, delta * acceleration))
		strafe_dir = Vector3.ZERO
		
		if $Mesh/t_pose/AnimationTree.get("parameters/aim_transition/current") == 0:
			direction = $Camroot/h.global_transform.basis.z
			
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
