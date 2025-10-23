extends Node

var RECENTS = []
var CALLBACK:Callable
var LAST_ID = 0

func _input(event:InputEvent):
	if(event.is_action_released("Refresh")):
		load_data()

func load_data() -> void:
	load_user_recent_files()
	#RECENTS.sort_custom(func(recent_file_a:Recent,recent_file_b:Recent):return recent_file_a.DateTime < recent_file_b.DateTime)

func save_everything():
	save_recent_files_to_user_data()



func reset_recent_files():
	RECENTS = []
	save_everything()


func load_user_recent_files():
	RECENTS = []
	var user_data = ConfigFile.new()
	var resource_data = ConfigFile.new()
	var user_data_err = user_data.load("user://recent_files.cfg")
	if(user_data_err != 7 ):
		var NUMBER_OF_RECENTS = user_data.get_value("META","NUMBER_OF_RECENTS")
		LAST_ID = NUMBER_OF_RECENTS
		var sections =user_data.get_sections()
		for section in sections:
			if(section != "META"):
				var recent_file = Recent.new();
				recent_file.DateTime = user_data.get_value(section,"DATE_TIME")
				recent_file.ThumbnailPath = user_data.get_value(section,"THUMBNAIL_PATH")
				recent_file.Path = user_data.get_value(section,"PATH")
				recent_file.SavedOutsideUserDirectory = user_data.get_value(section,"SAVED_OUTSIDE")
				RECENTS.push_front(recent_file)

	if(CALLBACK.is_valid()):
		CALLBACK.call()

func save_recent_files_to_user_data():
	var user_data = ConfigFile.new()

	var index = 0;
	var NUMBER_OF_RECENTS = RECENTS.size()
	LAST_ID = NUMBER_OF_RECENTS

	user_data.set_value("META","NUMBER_OF_RECENTS",NUMBER_OF_RECENTS)
	for recent_file:Recent in RECENTS:
		var section = "%s" % index
		user_data.set_value(section,"DATE_TIME",recent_file.DateTime)
		user_data.set_value(section,"PATH",recent_file.Path)
		user_data.set_value(section,"THUMBNAIL_PATH",recent_file.ThumbnailPath)
		user_data.set_value(section,"SAVED_OUTSIDE",recent_file.SavedOutsideUserDirectory)

		index+=1;
	var err = await user_data.save("user://recent_files.cfg")
	if err != OK:
		print(err)
	if(CALLBACK.is_valid()):
		CALLBACK.call()
