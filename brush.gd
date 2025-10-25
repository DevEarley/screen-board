extends SubViewportContainer
class_name Controller;
var BRUSH_IS_RESET = true
var STARTING_POINT_SET = false
var VIRTUAL_STARTING_POINT_SET = false
var ENDING_POINT
var UNDO_HISTORY:Array[ImageTexture]
var RECENT_FILE_PREFAB = preload("res://RECENT_FILE.tscn")
var CURRENT_FILE_WAS_SAVED_OUTSIDE = false
var LAST_FILE_OPENED:Recent = null;
var OPENED_FROM_RECENT = false
var PASSTHROUGH_MODE_ON = false #MAC AND LINUX ONLY
var MAKING_STRAIGHT_LINE = false
var clicks = 0
var save_timer:Timer
var HISTORY_TIMER:Timer
var ERASER_MODE = false
var LAST_BRUSH:Color
@export var ERASER_VIEWPORT_Line2D:Line2D
@export var ERASER_VIEWPORT:Viewport
@export var ERASER_VIEWPORT_2:Viewport

@export var RED_COLOR:Color;
@export var BLUE_COLOR:Color;
@export var GREEN_COLOR:Color;
@export var YELLOW_COLOR:Color;
@export var BLACK_COLOR:Color;
@export var LIGHT_GREY_COLOR:Color;
@export var GREY_COLOR:Color;
@export var DARK_GREY_COLOR:Color;
@export var WHITE_COLOR:Color;

func _ready() -> void:
	LAST_BRUSH = GREEN_COLOR
	get_tree().get_root().set_transparent_background(true)
	save_timer = Timer.new()
	add_child(save_timer)
	save_timer.wait_time = 0.2
	save_timer.one_shot = true
	save_timer.connect("timeout",on_save_timer_timeout)

	HISTORY_TIMER = Timer.new()
	add_child(HISTORY_TIMER)
	HISTORY_TIMER.wait_time = 0.5
	HISTORY_TIMER.one_shot = true
	HISTORY_TIMER.connect("timeout",add_to_history)


	UNDO_HISTORY = []
	$TextureRect.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.texture = ImageTexture.new()
	add_to_history()
	await WAIT.for_seconds(0.1)
	_on_paste_pressed()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		if(CURRENT_FILE_WAS_SAVED_OUTSIDE == false):
			save_current_to_recents()
		else:
			DATA.save_everything()
		get_tree().quit() # default behavior

func clear_screen():
	add_to_history()
	$BRUSH_STROKES.texture= ImageTexture.new()
	CURRENT_FILE_WAS_SAVED_OUTSIDE = false
	OPENED_FROM_RECENT = false
	LAST_FILE_OPENED = null
	$SubViewport.render_target_clear_mode = 2
	$TextureRect.show()
	$TextureRect.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.show()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.texture = ImageTexture.new()
	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.new()
	_on_hide_bg_pressed()
	add_to_history()

func _input(event:InputEvent):
	handle_input(event)

func _process(delta):
	pass
	#copy_screen_to_input_window()

func on_save_timer_timeout():
	READY_TO_ADD_TO_HISTORY = true

var READY_TO_ADD_TO_HISTORY = true

func add_to_history():
	print("add_to_history")
	if(READY_TO_ADD_TO_HISTORY == true):
		READY_TO_ADD_TO_HISTORY = false
		save_timer.start()
		clicks +=1
		print(clicks)
		if(UNDO_HISTORY.size()>100):
				UNDO_HISTORY.pop_back()
		prep_for_eraser()
		var image:Image =$BRUSH_STROKES.texture.get_image()

		#var image= texture.get_image()
		if($TextureRect.texture != null):
			var bg = $TextureRect.texture.get_image()
			if(bg == null):
				UNDO_HISTORY.push_front(ImageTexture.create_from_image(image))
			else:
				image.resize(bg.get_width(),bg.get_height())
				var rect = Rect2i(Vector2i.ZERO, image.get_size())
				bg.blend_rect(image,rect,Vector2i.ZERO)
				UNDO_HISTORY.push_front( ImageTexture.create_from_image(bg))
		else:
			UNDO_HISTORY.push_front(ImageTexture.create_from_image(image))



func handle_input(event:InputEvent):

	var offset = Vector2(-15,-3)

	if(event is InputEventMouse && MAKING_STRAIGHT_LINE == true):
		if($CURSOR_VIEWPORT/Line2D.points[0 ] == Vector2.ZERO):
			$CURSOR_VIEWPORT/Line2D.points[0] = event.position+offset

		$CURSOR_VIEWPORT/Line2D.points[1] = event.position+offset
		print(event.position)
	if(event is InputEventMouse && MAKING_STRAIGHT_LINE == false):
		if event is InputEventMouseMotion:
			$CURSOR_VIEWPORT/BRUSH.position =event.position - 	$CURSOR_VIEWPORT/BRUSH.size / 2.0
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
	if(event.is_action_released("paste")):
		_on_paste_pressed()
	if(Input.is_action_just_released("mouse_click")):

		HISTORY_TIMER.start()
	if(Input.is_action_just_released("White")):
		_on_white_pressed()
	if(Input.is_action_just_released("Black")):
		_on_black_pressed()
	if(Input.is_action_just_released("D_Grey")):
		_on_dark_grey_pressed()
	if(Input.is_action_just_released("L_Grey")):
		_on_light_grey_pressed()
	if(Input.is_action_just_released("Grey")):
		_on_grey_pressed()
	if(Input.is_action_just_released("Green")):
		_on_green_pressed()
	if(Input.is_action_just_released("Red")):
		_on_red_pressed()
	if(Input.is_action_just_released("Yellow")):
		_on_yellow_pressed()
	if(Input.is_action_just_released("Blue")):
		_on_blue_pressed()
	if(Input.is_action_just_released("Eraser")):
		ERASER_MODE = true
		$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (ON)"
		prep_for_eraser()
	if(Input.is_action_just_released("Brush")):
		$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"
		ERASER_MODE = false
		$CURSOR_VIEWPORT/Line2D.default_color = LAST_BRUSH;
		$SubViewport/Line2D.default_color = LAST_BRUSH;
		$CURSOR_VIEWPORT/BRUSH.modulate = LAST_BRUSH;
	if(Input.is_action_pressed("Increase_Size")):
		var og = $CURSOR_VIEWPORT/BRUSH.size
		$CURSOR_VIEWPORT/Line2D.width =	 clamp($CURSOR_VIEWPORT/Line2D.width *1.1, 0.5, 100)
		$SubViewport/Line2D.width = $CURSOR_VIEWPORT/Line2D.width
		$CURSOR_VIEWPORT/BRUSH.size = Vector2.ONE * $CURSOR_VIEWPORT/Line2D.width
		$CURSOR_VIEWPORT/BRUSH.position-=($CURSOR_VIEWPORT/BRUSH.size - og)/2.0
	if(Input.is_action_pressed("Decrease_Size")):
		var og = $CURSOR_VIEWPORT/BRUSH.size

		$CURSOR_VIEWPORT/Line2D.width =	 clamp($CURSOR_VIEWPORT/Line2D.width *0.9, 0.5, 100)
		$SubViewport/Line2D.width = $CURSOR_VIEWPORT/Line2D.width
		$CURSOR_VIEWPORT/BRUSH.size = Vector2.ONE * $CURSOR_VIEWPORT/Line2D.width
		$CURSOR_VIEWPORT/BRUSH.position-=($CURSOR_VIEWPORT/BRUSH.size - og)/2.0


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

		else:
				BRUSH_IS_RESET = true
				STARTING_POINT_SET = false

				if(ERASER_MODE == true):
					ERASER_VIEWPORT_Line2D.points[0] = Vector2.ZERO
					ERASER_VIEWPORT_Line2D.points[1] = Vector2.ZERO

					var eraser_mask:Image= ERASER_VIEWPORT_2.get_texture().get_image()
					var drawing_layer:Image = $SubViewport.get_texture().get_image()
					var rect = Rect2i(Vector2i.ZERO, Vector2(1920,1080))
					if($BRUSH_STROKES.texture!=null):
						var old_mix:Image = $BRUSH_STROKES.texture.get_image()
						if(old_mix!=null):
							old_mix.blend_rect(drawing_layer,rect,Vector2i.ZERO)
							drawing_layer.blit_rect_mask(old_mix,eraser_mask,rect,Vector2i.ZERO)
						else:
							drawing_layer.blit_rect_mask(drawing_layer,eraser_mask,rect,Vector2i.ZERO)

					else:
						drawing_layer.blit_rect_mask(drawing_layer,eraser_mask,rect,Vector2i.ZERO)

					$BRUSH_STROKES.texture = ImageTexture.create_from_image(drawing_layer)

					if($CONTROL.visible == true):
						$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE3.texture  =$BRUSH_STROKES.texture
					ERASER_VIEWPORT.render_target_clear_mode = 2
					$SubViewport.render_target_clear_mode = 2
				else:
					$SubViewport/Line2D.points[0] = Vector2.ZERO
					$SubViewport/Line2D.points[1] = Vector2.ZERO
	elif event is InputEventMouseMotion:
		if(Input.is_action_pressed("mouse_click")):

			var point_0;
			var point_1;
			if(ERASER_MODE == true):
				point_0 = ERASER_VIEWPORT_Line2D.points[0]
				point_1 = ERASER_VIEWPORT_Line2D.points[1]
			else:
				point_0 = $SubViewport/Line2D.points[0]
				point_1 = $SubViewport/Line2D.points[1]
			if(STARTING_POINT_SET == true && BRUSH_IS_RESET == false ):
				STARTING_POINT_SET = false
				point_1 = event.position+offset
			elif(STARTING_POINT_SET == false && BRUSH_IS_RESET == false ):
				STARTING_POINT_SET = true
				point_0 = event.position+offset
			elif(STARTING_POINT_SET == true && BRUSH_IS_RESET == true ):
				BRUSH_IS_RESET = false
				STARTING_POINT_SET = false
				point_0 = event.position+offset
				point_1= event.position+offset
			elif(STARTING_POINT_SET == false && BRUSH_IS_RESET == true ):
				BRUSH_IS_RESET = false
				STARTING_POINT_SET = true
				point_0 = event.position+offset
				point_1= event.position+offset
			if(ERASER_MODE == true):
				ERASER_VIEWPORT_Line2D.points[0] =point_0
				ERASER_VIEWPORT_Line2D.points[1] =point_1
			else:
				$SubViewport/Line2D.points[0] = point_0
				$SubViewport/Line2D.points[1] = point_1
	copy_screen_to_input_window()

func copy_screen_to_input_window():
	if($CONTROL.visible == false):return;
	var image:Image = $SubViewport.get_texture().get_image()
	if( $TextureRect.texture!=null):
		var bg:Image = $TextureRect.texture.get_image()
		if(bg != null):
			var rect = Rect2i(Vector2i.ZERO, image.get_size())
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE.texture = ImageTexture.create_from_image(image)
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.show()
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.stretch_mode = $TextureRect.stretch_mode
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.texture = ImageTexture.create_from_image(bg)
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
	var fd: FileDialog = $Control/FileDialog
	if(LAST_FILE_OPENED !=null):
		fd.current_file = LAST_FILE_OPENED.Path
		fd.current_path = LAST_FILE_OPENED.Path
	else:
		var dateTime = "%s.png" % Time.get_datetime_string_from_system(true,false)
		dateTime=dateTime.replacen(":","_")
		fd.current_file = dateTime
	$Control/FileDialog.show()

func _on_paste_pressed() -> void:
	var clipboard_image:Image = DisplayServer.clipboard_get_image()
	if(clipboard_image != null):

		$TextureRect.show()
		if(clipboard_image.get_width() < 1920 && clipboard_image.get_height() < 1080):
			$TextureRect.stretch_mode =TextureRect.STRETCH_KEEP_CENTERED
		else:
			$TextureRect.stretch_mode =TextureRect.STRETCH_SCALE
		$TextureRect.texture = ImageTexture.create_from_image(clipboard_image)


func _on_undo_pressed() -> void:
	undo();

func undo():
		$SubViewport.render_target_clear_mode = 2

		$TextureRect.show()
		if(UNDO_HISTORY.size()>0):
			var texture =UNDO_HISTORY.pop_front()
			var image = texture.get_image()
			$BRUSH_STROKES.texture = ImageTexture.create_from_image(image)


		else:
			$BRUSH_STROKES.texture = ImageTexture.new()
#


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
		print(" try_to_load_texture_from_path - File not loaded:",err,path)
	return image

func _on_clear_recents_pressed() -> void:
	DATA.RECENTS = []
	DATA.save_everything()
	DATA.CALLBACK = build_recents_list


func on_load_from_recents(recent:Recent):
		OPENED_FROM_RECENT = true
		LAST_FILE_OPENED = recent
		$RECENTS.hide()
		var image_from_path:Image = try_to_load_texture_from_path(recent.Path)

		$TextureRect.show()
		if(image_from_path.get_width() < 1920 && image_from_path.get_height() < 1080):
			$TextureRect.stretch_mode =TextureRect.STRETCH_KEEP_CENTERED
		else:
			$TextureRect.stretch_mode =TextureRect.STRETCH_SCALE
		$TextureRect.texture = ImageTexture.create_from_image(image_from_path)

func on_delete_from_recents(recent:Recent):
		OPENED_FROM_RECENT = true
		LAST_FILE_OPENED = recent
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
		var recent_delete_button:Button = recent_control.get_node("DELETE");
		if(recent.SavedOutsideUserDirectory):
			recent_control.get_node("Label").text = "%s" %  recent.Path
			recent_delete_button.hide()
		else:
			recent_control.get_node("Label").text = "%s (DRAFT)" % recent.Path
			recent_delete_button.connect("pressed",on_delete_from_recents.bind(recent));
			recent_delete_button.show()
		var image_from_path:Image = try_to_load_texture_from_path(recent.ThumbnailPath)
		recent_control.get_node("TextureRect").texture = ImageTexture.create_from_image(image_from_path)
		$RECENTS/Control2/ScrollContainer/RECENTS_CONTAINER.add_child(recent_control)


func blend_images_for_saving():
	prep_for_eraser()
	var image:Image =$BRUSH_STROKES.texture.get_image()

	var image_to_save:Image;
	var rect = Rect2i(Vector2i.ZERO, Vector2(1920,1080))
	if(BG_CANVAS != null):
		var bg_image = 	BG_CANVAS.texture.get_image()
		if($TextureRect.texture != null):
			var bg:Image = $TextureRect.texture.get_image()
			if(bg != null):
				var width_ = bg.get_width()
				var height_ = bg.get_height()
				if(width_ < 1920 || height_ < 1920):
					var x = 960 - (width_/2)
					var y = 540 - ( height_/2)
					bg_image.blend_rect(bg,rect,Vector2(abs(x),abs(y)))
				else:
					bg_image.blend_rect(bg,rect,Vector2i.ZERO)

		bg_image.blend_rect(image,rect,Vector2i.ZERO)
		image_to_save = bg_image;

	elif($TextureRect.texture != null):
		var bg:Image = $TextureRect.texture.get_image()
		if(bg != null):
			var width_ = bg.get_width()
			var height_ = bg.get_height()
			if(width_ < 1920 || height_ < 1920):
				var x = 960 - (width_/2)
				var y = 540 - ( height_/2)
				bg.blend_rect(image,rect,Vector2(abs(x),abs(y)))
			else:
				bg.blend_rect(image,rect,Vector2i.ZERO)
			image_to_save = bg
		else:
			image_to_save = image;
	else:
		image_to_save = image;
	return image_to_save

func save_current_to_recents():
	var recent

	if(OPENED_FROM_RECENT == true):
		recent = LAST_FILE_OPENED

	else:
		recent = Recent.new()



	var ImageToSave :Image =blend_images_for_saving()

	var Thumb :Image = ImageToSave.duplicate(true)
	if(ImageToSave == null):return;
	Thumb.resize(160,90,Image.INTERPOLATE_NEAREST)
	var dateTime = "%s" % Time.get_datetime_string_from_system(true,false)
	dateTime=dateTime.replacen(":","_")
	var path = "user://%s.png"%dateTime
	var thumb_path = "user://thumb-%s.png"%dateTime

	recent.DateTime = dateTime;
	recent.Path = path;
	recent.ThumbnailPath = thumb_path;
	Thumb.save_png(thumb_path)
	ImageToSave.save_png(path)
	DATA.RECENTS.push_front(recent)
	DATA.save_everything()

var BG_CANVAS:TextureRect = null

func _on_file_dialog_file_selected(path: String) -> void:
	$Control/FileDialog.hide()

	var ImageToSave :Image =blend_images_for_saving()

	var Thumb :Image = ImageToSave.duplicate(true)
	Thumb.resize(160,90,Image.INTERPOLATE_NEAREST)
	var dateTime = "%s" % Time.get_datetime_string_from_system(true,false)
	dateTime=dateTime.replacen(":","_")
	var recent:Recent;
	var thumb_path = "user://thumb-%s.png"%dateTime
	recent = Recent.new()
	recent.DateTime = dateTime;

	recent.Path = path;
	recent.ThumbnailPath = thumb_path;
	recent.SavedOutsideUserDirectory = true
	LAST_FILE_OPENED = recent;

	DATA.RECENTS.push_front(recent)
	DATA.CALLBACK = build_recents_list
	ImageToSave.save_png(path)
	Thumb.save_png(thumb_path)
	DATA.save_everything()
	CURRENT_FILE_WAS_SAVED_OUTSIDE = true


func _on_open_pressed() -> void:
	$Control/OpenDialog.show();


func _on_open_dialog_file_selected(path: String) -> void:
	#try to find matching recent and load that.
	#load file and create recent
	var image_from_path:Image = try_to_load_texture_from_path(path)
	var Thumb :Image = image_from_path.duplicate(true)
	Thumb.resize(160,90,Image.INTERPOLATE_NEAREST)
	var dateTime = "%s" % Time.get_datetime_string_from_system(true,false)
	dateTime=dateTime.replacen(":","_")
	var thumb_path = "user://thumb-%s.png"%dateTime
	var recent:Recent = Recent.new();
	recent.ThumbnailPath = thumb_path;
	recent.DateTime = dateTime;
	recent.Path = path
	Thumb.save_png(thumb_path)
	recent.SavedOutsideUserDirectory = true;
	DATA.RECENTS.push_front(recent)
	DATA.save_everything()
	LAST_FILE_OPENED = recent;
	var width = image_from_path.get_width()
	var height = image_from_path.get_height()
	#_on_hide_bg_pressed()
	$TextureRect.show()

	if(width< 1920 && height < 1080):

		$TextureRect.stretch_mode =TextureRect.STRETCH_KEEP_CENTERED
	else:
		$TextureRect.stretch_mode =TextureRect.STRETCH_SCALE
	$TextureRect.texture = ImageTexture.create_from_image(image_from_path)


func _on_save_draft_pressed() -> void:
		save_current_to_recents()
		await WAIT.for_seconds(0.1)
		clear_screen()


func _on_light_bg_2_pressed() -> void:
	_on_hide_bg_pressed()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_5.show()
	$CANVAS_5.show()
	BG_CANVAS = $CANVAS_5


func _on_light_bg_1_pressed() -> void:
	_on_hide_bg_pressed()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_4.show()
	$CANVAS_4.show()
	BG_CANVAS = $CANVAS_4



func _on_dark_bg_3_pressed() -> void:
	_on_hide_bg_pressed()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_3.show()
	$CANVAS_3.show()
	BG_CANVAS = $CANVAS_3



func _on_dark_bg_2_pressed() -> void:
	_on_hide_bg_pressed()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_2.show()
	$CANVAS_2.show()
	BG_CANVAS = $CANVAS_2



func _on_dark_bg_1_pressed() -> void:
	_on_hide_bg_pressed()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_1.show()
	$CANVAS_1.show()
	BG_CANVAS = $CANVAS_1


func _on_yellow_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = YELLOW_COLOR;
	$SubViewport/Line2D.default_color = YELLOW_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = YELLOW_COLOR;
	LAST_BRUSH = YELLOW_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"


func _on_white_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = WHITE_COLOR;
	$SubViewport/Line2D.default_color = WHITE_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = WHITE_COLOR;
	LAST_BRUSH = WHITE_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"


func _on_black_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = BLACK_COLOR;
	$SubViewport/Line2D.default_color = BLACK_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = BLACK_COLOR;
	LAST_BRUSH = BLACK_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"

func _on_light_grey_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = LIGHT_GREY_COLOR;
	$SubViewport/Line2D.default_color = LIGHT_GREY_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = LIGHT_GREY_COLOR;
	LAST_BRUSH = LIGHT_GREY_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"


func _on_grey_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = GREY_COLOR;
	$SubViewport/Line2D.default_color = GREY_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = GREY_COLOR;
	LAST_BRUSH = GREY_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"

func _on_dark_grey_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = DARK_GREY_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = DARK_GREY_COLOR;
	$SubViewport/Line2D.default_color = DARK_GREY_COLOR;
	LAST_BRUSH = DARK_GREY_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"


func _on_red_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = RED_COLOR;
	$SubViewport/Line2D.default_color = RED_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = RED_COLOR;
	LAST_BRUSH = RED_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"

func _on_green_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = GREEN_COLOR;
	$SubViewport/Line2D.default_color = GREEN_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = GREEN_COLOR;
	LAST_BRUSH = GREEN_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"

func _on_blue_pressed() -> void:
	ERASER_MODE = false
	$CURSOR_VIEWPORT/Line2D.default_color = BLUE_COLOR;
	$SubViewport/Line2D.default_color = BLUE_COLOR;
	$CURSOR_VIEWPORT/BRUSH.modulate = BLUE_COLOR;
	LAST_BRUSH = BLUE_COLOR
	$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"


func _on_hide_bg_pressed() -> void:
	$TextureRect.hide()
	BG_CANVAS = null;
	$CANVAS_1.hide()
	$CANVAS_2.hide()
	$CANVAS_3.hide()
	$CANVAS_4.hide()
	$CANVAS_5.hide()

	$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE2.hide()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_1.hide()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_2.hide()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_3.hide()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_4.hide()
	$CONTROL/SubViewportContainer/SubViewport/CANVAS_5.hide()



func _on_eraser_pressed() -> void:
	ERASER_MODE = !ERASER_MODE
	if(ERASER_MODE):
		$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (ON)"
		prep_for_eraser()
	else:
		$Control/Control/HBoxContainer/VBoxContainer/HBoxContainer2/ERASER.text = "[E]RASER (OFF)"

		$CURSOR_VIEWPORT/Line2D.default_color = LAST_BRUSH;
		$SubViewport/Line2D.default_color = LAST_BRUSH;
		$CURSOR_VIEWPORT/BRUSH.modulate = LAST_BRUSH;

func prep_for_eraser():

		var drawing_layer:Image = $SubViewport.get_texture().get_image()
		var rect = Rect2i(Vector2i.ZERO, Vector2(1920,1080))
		if($BRUSH_STROKES.texture!=null):
			var old_mix:Image = $BRUSH_STROKES.texture.get_image()
			if(old_mix!=null):
				old_mix.blend_rect(drawing_layer,rect,Vector2i.ZERO)
				$BRUSH_STROKES.texture = ImageTexture.create_from_image(old_mix)
			else:
				$BRUSH_STROKES.texture = ImageTexture.create_from_image(drawing_layer)
		else:
			$BRUSH_STROKES.texture = ImageTexture.create_from_image(drawing_layer)
		if($CONTROL.visible == true):
			$CONTROL/SubViewportContainer/SubViewport/TextureRect_CLONE3.texture  =$BRUSH_STROKES.texture
		$SubViewport.render_target_clear_mode = 2


func _on_dual_screen_pressed() -> void:
	if($CONTROL.visible == true):
		$Control/Control/HBoxContainer/DUAL_SCREEN.text = "DUAL SCREEN (OFF)"
		$CONTROL.hide()
	else:
		$Control/Control/HBoxContainer/DUAL_SCREEN.text = "DUAL SCREEN (ON)"
		$CONTROL.show()
