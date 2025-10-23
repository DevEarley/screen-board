extends SubViewportContainer
class_name Controller;
var BRUSH_IS_RESET = true
var STARTING_POINT_SET = false
var VIRTUAL_STARTING_POINT_SET = false
var ENDING_POINT
var UNDO_HISTORY:Array[ImageTexture]
var RECENT_FILE_PREFAB = preload("res://RECENT_FILE.tscn")
var CURRENT_FILE_WAS_SAVED_OUTSIDE = false
var OPENED_RECENT:Recent = null;
var OPENED_FROM_RECENT = false
var PASSTHROUGH_MODE_ON = false #MAC AND LINUX ONLY
var MAKING_STRAIGHT_LINE = false
var clicks = 0
var save_timer:Timer

func _ready() -> void:

	get_tree().get_root().set_transparent_background(true)
	save_timer = Timer.new()
	add_child(save_timer)
	save_timer.wait_time = 0.2
	save_timer.one_shot = true
	save_timer.connect("timeout",on_save_timer_timeout)
	UNDO_HISTORY = []
	$TextureRect.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.new()
	add_to_history()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if(CURRENT_FILE_WAS_SAVED_OUTSIDE == false):
			save_current_to_recents()
		else:
			DATA.save_everything()
		get_tree().quit() # default behavior

func clear_screen():
	CURRENT_FILE_WAS_SAVED_OUTSIDE = false
	OPENED_FROM_RECENT = false
	OPENED_RECENT = null
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
	if(CURRENT_FILE_WAS_SAVED_OUTSIDE == false):
		save_current_to_recents()
	else:
		DATA.save_everything()
	get_tree().quit()


func _on_save_pressed() -> void:
	$Control/FileDialog.show()

func _on_paste_pressed() -> void:
	var clipboard_image:Image = DisplayServer.clipboard_get_image()
	$TextureRect.texture = ImageTexture.create_from_image(clipboard_image)


func _on_undo_pressed() -> void:
	undo();

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
	$Control/MENU_CONTROL/MENU.hide()
	$BG.show()





func _on_control_mouse_exited() -> void:
	$BG.hide()
	$Control/Control.hide()
	$Control/MENU_CONTROL/MENU.show()


func _on_passthrough_pressed() -> void:
	#ONLY WORKS ON MAC AND LINUX
	PASSTHROUGH_MODE_ON = !PASSTHROUGH_MODE_ON

	if(PASSTHROUGH_MODE_ON == false):
		$Control/Control/HBoxContainer/PASSTHROUGH.text = "PASSTHROUGH MODE OFF"
		DisplayServer.window_set_mouse_passthrough([],0)
		DisplayServer.window_set_mouse_passthrough([],1)
	elif(PASSTHROUGH_MODE_ON == true):

		var texture_corners: PackedVector2Array = 	[Vector2(0,0),Vector2(0,100),Vector2(1920,100),Vector2(1920,0)]
		DisplayServer.window_set_mouse_passthrough(texture_corners,0)
		DisplayServer.window_set_mouse_passthrough(texture_corners,1)
		$Control/Control/HBoxContainer/PASSTHROUGH.text = "PASSTHROUGH MODE ON"

	$BG.hide()
	$Control/Control.hide()
	$Control/MENU_CONTROL/MENU.show()


func _on_recents_pressed() -> void:
	$RECENTS.show()
	DATA.CALLBACK = build_recents_list
	DATA.load_data()

func _on_recents_close_requested() -> void:
	$RECENTS.hide()


func _on_cancel_load_from_recents_pressed() -> void:
		$RECENTS.hide()

func try_to_load_texture_from_path(path):
	var image = Image.new()
	var err = image.load(path)
	if err != OK:
		print("File not loaded:",err)
	return image

func _on_clear_recents_pressed() -> void:
	DATA.RECENTS = []
	build_recents_list()

func on_load_from_recents(recent:Recent):
		OPENED_FROM_RECENT = true
		OPENED_RECENT = recent
		$RECENTS.hide()
		var image_from_path:Image = try_to_load_texture_from_path(recent.Path)

		$TextureRect.texture = ImageTexture.create_from_image(image_from_path)

func on_delete_from_recents(recent:Recent):
		OPENED_FROM_RECENT = true
		OPENED_RECENT = recent
		var index = 0
		var index_to_delete = -1
		for recent_ in DATA.RECENTS:
			if recent_.Path == recent.Path:
				index_to_delete = index;
			index += 1;
		DATA.RECENTS.remove_at(index_to_delete)
		DATA.CALLBACK = build_recents_list
		DATA.save_everything()

func build_recents_list():
	var children_to_kill = $RECENTS/Control2/ScrollContainer/RECENTS_CONTAINER.get_children()

	for child:Node in children_to_kill:
		child.queue_free()

	for recent:Recent in DATA.RECENTS:
		var recent_control = RECENT_FILE_PREFAB.instantiate()
		var recent_load_button:Button = recent_control.get_node("Button");
		recent_load_button.connect("pressed",on_load_from_recents.bind(recent));
		if(recent.SavedOutsideUserDirectory):
			recent_control.get_node("Label").text = "%s" %  recent.Path
		else:
			recent_control.get_node("Label").text = "%s (DRAFT)" % recent.Path
			var recent_delete_button:Button = recent_control.get_node("DELETE");
			recent_delete_button.connect("pressed",on_delete_from_recents.bind(recent));
			recent_delete_button.show()
		var image_from_path:Image = try_to_load_texture_from_path(recent.ThumbnailPath)
		recent_control.get_node("TextureRect").texture = ImageTexture.create_from_image(image_from_path)
		$RECENTS/Control2/ScrollContainer/RECENTS_CONTAINER.add_child(recent_control)

func save_current_to_recents():
	var recent

	if(OPENED_FROM_RECENT == true):
		recent = OPENED_RECENT
	else:
		recent = Recent.new()

	var bg = $TextureRect.texture.get_image()
	var image:Image = $SubViewport.get_texture().get_image()
	var rect = Rect2i(Vector2i.ZERO, image.get_size())
	var image_to_save;
	if(bg != null):
		bg.blend_rect(image,rect,Vector2i.ZERO)
		image_to_save = bg;
	else:
		image_to_save = image

	var ImageToSave :Image =image_to_save

	var Thumb :Image = ImageToSave.duplicate(true)
	if(ImageToSave == null):return;
	Thumb.resize(160,90,Image.INTERPOLATE_TRILINEAR)
	var dateTime = "%s" % Time.get_datetime_string_from_system(true,false)
	dateTime=dateTime.replacen(":","_")
	var path = "user://%s.png"%dateTime
	var thumb_path = "user://thumb-%s.png"%dateTime

	recent.DateTime = dateTime;
	recent.Path = path;
	recent.ThumbnailPath = thumb_path;
	recent.SavedOutsideUserDirectory = false
	Thumb.save_png(thumb_path)
	ImageToSave.save_png(path)
	DATA.RECENTS.push_front(recent)
	DATA.save_everything()


func _on_file_dialog_file_selected(path: String) -> void:
	$Control/FileDialog.hide()
	var bg = $TextureRect.texture.get_image()
	var image:Image = $SubViewport.get_texture().get_image()
	var rect = Rect2i(Vector2i.ZERO, image.get_size())
	var image_to_save;
	if(bg != null):
		bg.blend_rect(image,rect,Vector2i.ZERO)
		image_to_save = bg;
	else:
		image_to_save = image
	var Thumb :Image = image_to_save.duplicate(true)
	Thumb.resize(160,90,Image.INTERPOLATE_TRILINEAR)
	var dateTime = "%s" % Time.get_datetime_string_from_system(true,false)
	dateTime=dateTime.replacen(":","_")
	var recent:Recent;
	var thumb_path

	if(CURRENT_FILE_WAS_SAVED_OUTSIDE == true):
		recent = OPENED_RECENT
		recent.DateTime= dateTime
		thumb_path = recent.ThumbnailPath;
		for recent_ in DATA.RECENTS:
			if(recent_.Path == recent.Path):
				recent_.DateTime = dateTime
				recent.SavedOutsideUserDirectory = true

	elif(CURRENT_FILE_WAS_SAVED_OUTSIDE == false):
		thumb_path = "user://thumb-%s.png"%dateTime
		recent = Recent.new()
		recent.DateTime = dateTime;

		recent.Path = path;
		recent.ThumbnailPath = thumb_path;
		recent.SavedOutsideUserDirectory = false
		DATA.RECENTS.push_front(recent)

	image_to_save.save_png(path)
	Thumb.save_png(thumb_path)
	CURRENT_FILE_WAS_SAVED_OUTSIDE = true
