extends SubViewportContainer
class_name Controller;
var BRUSH_IS_RESET = true
var STARTING_POINT_SET = false
var VIRTUAL_STARTING_POINT_SET = false
var ENDING_POINT
var UNDO_HISTORY:Array[ImageTexture]

func _ready() -> void:
	save_timer = Timer.new()
	add_child(save_timer)
	save_timer.wait_time = 0.2
	save_timer.one_shot = true
	save_timer.connect("timeout",on_save_timer_timeout)
	UNDO_HISTORY = []
	$TextureRect.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.new()
	add_to_history()

func clear_screen():

	$SubViewport.render_target_clear_mode = 2
	$TextureRect.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.new()
	add_to_history()

func _input(event:InputEvent):
	handle_input(event)

func _process(delta):
	pass
	copy_screen_to_input_window()

func on_save_timer_timeout():
	READY_TO_ADD_TO_HISTORY = true

var READY_TO_ADD_TO_HISTORY = true

func add_to_history():
	if(READY_TO_ADD_TO_HISTORY == true):
		READY_TO_ADD_TO_HISTORY = false
		save_timer.start()
		clicks +=1
		print(clicks)
		if(UNDO_HISTORY.size()>100):
				UNDO_HISTORY.pop_back()
		var texture = $SubViewport.get_texture()
		var image= texture.get_image()
		if($TextureRect.texture != null):
			var bg = $TextureRect.texture.get_image()
			if(bg == null):
				UNDO_HISTORY.push_front(ImageTexture.create_from_image(image))
			else:
				var rect = Rect2i(Vector2i.ZERO, image.get_size())
				bg.blend_rect(image,rect,Vector2i.ZERO)
				UNDO_HISTORY.push_front( ImageTexture.create_from_image(bg))
		else:
			UNDO_HISTORY.push_front(ImageTexture.create_from_image(image))

func make_straight_lines(event,offset):
		if( STARTING_POINT_SET == false):
			STARTING_POINT_SET = true
			MAKING_STRAIGHT_LINE = true
			$SubViewport/Line2D.points[0] = event.position + offset
			$CURSOR_VIEWPORT/Line2D.points[0] = event.position+offset
			$SubViewport/Line2D.points[1] = event.position + offset
			#$SubViewport/BRUSH.position = event.position
			BRUSH_IS_RESET = false
			#add_to_history()

		elif( STARTING_POINT_SET == true):
			STARTING_POINT_SET = false
			MAKING_STRAIGHT_LINE = false
			$SubViewport/Line2D.points[1] =event.position + offset
			#$SubViewport/BRUSH.position = event.position
			BRUSH_IS_RESET = true



var MAKING_STRAIGHT_LINE = false
var clicks = 0
var save_timer:Timer
func handle_input(event:InputEvent):

	var offset = Vector2(-15,-3)

	if(event is InputEventMouse && MAKING_STRAIGHT_LINE == true):
		if($CURSOR_VIEWPORT/Line2D.points[0 ] == Vector2.ZERO):
			$CURSOR_VIEWPORT/Line2D.points[0] = event.position+offset

		$CURSOR_VIEWPORT/Line2D.points[1] = event.position+offset
		print(event.position)
	if(event is InputEventMouse && MAKING_STRAIGHT_LINE == false):
		if event is InputEventMouseMotion:
			$CURSOR_VIEWPORT/BRUSH.position =event.position
			if(VIRTUAL_STARTING_POINT_SET == true ):
				VIRTUAL_STARTING_POINT_SET = false
				$CURSOR_VIEWPORT/Line2D.points[1] = event.position+offset
			elif(VIRTUAL_STARTING_POINT_SET == false ):
				VIRTUAL_STARTING_POINT_SET = true

		if($CURSOR_VIEWPORT/Line2D.points[1] == Vector2.ZERO):
			$CURSOR_VIEWPORT/Line2D.points[1] = event.position+offset
		$CURSOR_VIEWPORT/Line2D.points[0] = event.position+offset


	if(event.is_action_released("undo")&& Input.is_action_pressed("control")):
		_on_undo_pressed()
	if(event.is_action_released("save_doodle")&& Input.is_action_pressed("control")):
		_on_save_pressed()
	if(event.is_action_released("paste")&& Input.is_action_pressed("control")):
		_on_paste_pressed()
	if(Input.is_action_just_pressed("mouse_click")):

		add_to_history()


	if( event is InputEventMouse && Input.is_action_just_pressed("right_mouse_click")):
			STARTING_POINT_SET = true
			MAKING_STRAIGHT_LINE = true
			$SubViewport/Line2D.points[0] = event.position + offset
			$CURSOR_VIEWPORT/Line2D.points[0] = event.position+offset
			$SubViewport/Line2D.points[1] = event.position + offset
			#$SubViewport/BRUSH.position = event.position
			BRUSH_IS_RESET = false
			add_to_history()

	elif( event is InputEventMouse && Input.is_action_just_released("right_mouse_click")):
			STARTING_POINT_SET = false
			MAKING_STRAIGHT_LINE = false
			$SubViewport/Line2D.points[1] =event.position + offset
			#$SubViewport/BRUSH.position = event.position
			BRUSH_IS_RESET = true


	elif( event is InputEventMouse && Input.is_action_just_released("mouse_click")):
		if(Input.is_action_pressed("shift")):
			make_straight_lines(event,offset)
		else:
				BRUSH_IS_RESET = true
				STARTING_POINT_SET = false
				$SubViewport/Line2D.points[0] = Vector2.ZERO
				$SubViewport/Line2D.points[1] = Vector2.ZERO

	elif event is InputEventMouseMotion:
		if(Input.is_action_pressed("mouse_click")):

			if(STARTING_POINT_SET == true && BRUSH_IS_RESET == false ):
				STARTING_POINT_SET = false
				$SubViewport/Line2D.points[1] = event.position+offset
			elif(STARTING_POINT_SET == false && BRUSH_IS_RESET == false ):
				STARTING_POINT_SET = true
				$SubViewport/Line2D.points[0] = event.position+offset
			elif(STARTING_POINT_SET == true && BRUSH_IS_RESET == true ):
				BRUSH_IS_RESET = false
				STARTING_POINT_SET = false
				$SubViewport/Line2D.points[0] = event.position+offset
				$SubViewport/Line2D.points[1] = event.position+offset
			elif(STARTING_POINT_SET == false && BRUSH_IS_RESET == true ):
				BRUSH_IS_RESET = false
				STARTING_POINT_SET = true
				$SubViewport/Line2D.points[0] = event.position+offset
				$SubViewport/Line2D.points[1] = event.position+offset

func copy_screen_to_input_window():
	var image:Image = $SubViewport.get_texture().get_image()
	if( $TextureRect.texture!=null):
		var bg = $TextureRect.texture.get_image()
		if(bg != null):
			var rect = Rect2i(Vector2i.ZERO, image.get_size())
			bg.blend_rect(image,rect,Vector2i.ZERO)
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.create_from_image(bg)
		else:
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.create_from_image(image);

	else:
		$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.create_from_image(image);

func _on_button_pressed() -> void:
	BRUSH_IS_RESET = true
	$CURSOR_VIEWPORT/BRUSH.position = Vector2(-40,-40)
	#$SubViewport/BRUSH.position = Vector2(-40,-40)
	clear_screen()


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_save_pressed() -> void:
	$Control/FileDialog.show()



func _on_paste_pressed() -> void:
	var clipboard_image:Image = DisplayServer.clipboard_get_image()
	$TextureRect.texture = ImageTexture.create_from_image(clipboard_image)


func _on_file_dialog_file_selected(path: String) -> void:
	$Control/FileDialog.hide()
	var bg = $TextureRect.texture.get_image()
	var image:Image = $SubViewport.get_texture().get_image()
	var rect = Rect2i(Vector2i.ZERO, image.get_size())
	bg.blend_rect(image,rect,Vector2i.ZERO)
	bg.save_png(path)

func _on_undo_pressed() -> void:
	undo();
	#undo();
func undo():
		$SubViewport.render_target_clear_mode = 2
		if(UNDO_HISTORY.size()>0):
			var texture =UNDO_HISTORY.pop_front()
			var image = texture.get_image()
			$TextureRect.texture = ImageTexture.create_from_image(image)
			$TextureRect.show()
			#ImageTexture.create_from_image(texture)
			#var bg = $TextureRect.texture.get_image()
			#var image = texture.get_image()
			#if(bg == null):
			#else:
				#var rect = Rect2i(Vector2i.ZERO, image.get_size())
				#bg.blend_rect(image,rect,Vector2i.ZERO)
				#$TextureRect.texture = ImageTexture.create_from_image(bg)
		else:
			$TextureRect.texture = ImageTexture.new()
#		else:
			#$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.new()


func _on_menu_mouse_entered() -> void:
	$Control/Control.show()
	$Control/MENU.hide()
	$BG.show()





func _on_control_mouse_exited() -> void:
	$BG.hide()
	$Control/Control.hide()
	$Control/MENU.show()
