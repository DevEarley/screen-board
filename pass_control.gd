extends Window
@export var CONTROLLER:Controller

func _input(event):
	CONTROLLER.handle_input(event)
