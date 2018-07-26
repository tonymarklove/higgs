extends Camera2D

func calculate_bounds(level):
	set_limit(0, level.bounds_left())
	set_limit(1, level.bounds_top())
	set_limit(2, level.bounds_right())
	set_limit(3, level.bounds_bottom())
