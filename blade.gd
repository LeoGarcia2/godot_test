extends Spatial

var isBladeOpened = false
var blade_speed = 8
var isHitting = false
	
func _input(event):
	if event is InputEventKey:
		if event.is_action_pressed("sabre"):
			isBladeOpened = !isBladeOpened
			if isBladeOpened:
				$CSGCombiner/manche/lame/Particles.emitting = true
				$openSound.play()
				$idleSound.play()
			else:
				$CSGCombiner/manche/lame/Particles.emitting = false
				$idleSound.stop()
				$closeSound.play()

func _physics_process(delta):
	$hit.enabled = isBladeOpened
	
	if $hit.is_colliding():
		if $hit.get_collider():
			if isHitting:				
				if $hit_duration.is_stopped():
					$hitSound.play()
					$CSGCombiner/manche/lame/Particles.amount = 32
					$hit_duration.start()
					var colliding_object = $hit.get_collider()
					colliding_object = colliding_object.get_parent()
					var material = colliding_object.get_surface_material(0)
					material.albedo_color = Color(randf(), randf(), randf())
					colliding_object.set_surface_material(0, material)
	if $hit_duration.is_stopped():
		if $CSGCombiner/manche/lame/Particles.amount > 8:			
			$CSGCombiner/manche/lame/Particles.amount = 8
	if !isBladeOpened:
		$CSGCombiner/manche/lame.radius = lerp($CSGCombiner/manche/lame.radius, 0.02, blade_speed * delta)
		$CSGCombiner/manche/lame/mask.height = lerp($CSGCombiner/manche/lame/mask.height, 5.1, blade_speed * delta)
	else:
		$CSGCombiner/manche/lame.radius = lerp($CSGCombiner/manche/lame.radius, 0.07, blade_speed * delta)
		$CSGCombiner/manche/lame/mask.height = lerp($CSGCombiner/manche/lame/mask.height, 0, blade_speed * delta)
