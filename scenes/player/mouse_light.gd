extends PointLight2D

func _process(_delta):
	if enabled:
		global_position = get_global_mouse_position()
