extends SceneTree
const Model = preload("res://tycoon/economy.gd")
const SaveFile = preload("res://tycoon/save.gd")
var issues: Array = []
func check(ok: bool, message: String):
	if not ok:
		issues.append(message)
		printerr("FAIL: ",message)
func _initialize():
	var path_root = "user://tycoon_test_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(path_root)
	var io = SaveFile.new()
	io.folder = path_root
	var model = Model.new(23)
	check(io.save_game(model.s),"Initial save")
	check(io.load_game().cash == 0,"Initial load")
	model.s.cash = 52000
	model.s.stores[0].stock[0] = 7
	model.s.active = 0
	check(io.save_game(model.s),"Modified save")
	check(io.load_game().stores[0].stock[0] == 7,"Nested inventory roundtrip")
	var backup = io.path()+".bak"
	check(FileAccess.file_exists(backup),"Backup exists")
	var file = FileAccess.open(io.path(),FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	check(io.load_game().cash == 0,"Corrupt primary restores previous backup")
	check(not io.valid({"version":2}),"Incomplete data rejected")
	var wrong = model.s.duplicate(true)
	wrong.stores[0].stock.pop_back()
	check(not io.valid(wrong),"Corrupt stock schema rejected")
	var away = Model.new(2)
	for second in range(65): away.tick(1.0)
	check(away.s.day == 2,"Minute clock advances by one day per minute")
	check(away.s.cash > 0,"Starter kiosk earns during elapsed time")
	if issues.is_empty(): print("TYCOON SAVE/CLOCK PASS: 10 checks")
	quit(0 if issues.is_empty() else 1)
