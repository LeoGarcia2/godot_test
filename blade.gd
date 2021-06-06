extends Spatial

var isBladeOpened = false
var blade_speed = 8
	
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
	if !isBladeOpened:
		$CSGCombiner/manche/lame.radius = lerp($CSGCombiner/manche/lame.radius, 0.02, blade_speed * delta)
		$CSGCombiner/manche/lame/mask.height = lerp($CSGCombiner/manche/lame/mask.height, 5.1, blade_speed * delta)
	else:
		$CSGCombiner/manche/lame.radius = lerp($CSGCombiner/manche/lame.radius, 0.07, blade_speed * delta)
		$CSGCombiner/manche/lame/mask.height = lerp($CSGCombiner/manche/lame/mask.height, 0, blade_speed * delta)
