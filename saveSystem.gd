extends Spatial

var save_file = "user://godotgame.json"
var default_data = {
	"player": {
		"position": {
			"x": -18.716,
			"y": 2.006,
			"z": -16.30
		}
	}
}
var data = {}
var quitting = false
onready var player = get_node("../Player")

func _input(event):
	if event is InputEventKey:		
		if event.as_text() == "Y":
			print_debug("game saved")
			get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
			save_game()
		elif event.as_text() == "R":
			quitting = true
			data = default_data
			print_debug("game resetted and saved")
			get_tree().notification(MainLoop.NOTIFICATION_WM_QUIT_REQUEST)
			save_game()
		
func _ready():
	get_tree().set_auto_accept_quit(false)
	load_game()
	
func load_game():
	var file = File.new()
	if not file.file_exists(save_file):
		reset_data()
		return
	file.open(save_file, file.READ)
	var text = file.get_as_text()
	data = parse_json(text)
	file.close()
	if !data:
		reset_data()
		return
		
	player.translation.x = data["player"]["position"]["x"]
	player.translation.y = data["player"]["position"]["y"]
	player.translation.z = data["player"]["position"]["z"]
	
func save_game():
	var file = File.new()
	file.open(save_file, file.WRITE)
	file.store_line(to_json(data))
	file.close()
	
func reset_data():
	data = default_data.duplicate(true)

func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		save_game()
		get_tree().quit()

func _physics_process(delta):
	if !quitting:
		data["player"]["position"]["x"] = player.translation.x
		data["player"]["position"]["y"] = player.translation.y
		data["player"]["position"]["z"] = player.translation.z
