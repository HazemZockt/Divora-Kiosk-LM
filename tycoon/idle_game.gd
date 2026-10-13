extends Control
const Model = preload("res://tycoon/idle_economy.gd")
const Storage = preload("res://tycoon/idle_save.gd")
const Widgets = preload("res://tycoon/idle_widgets.gd")
const SceneArt = preload("res://tycoon/idle_scene.gd")
const Pages = preload("res://tycoon/idle_pages.gd")
var game = Model.new()
var saves = Storage.new()
var ui = Widgets.new()
var pages
var app: Control
var body: ScrollContainer
var content: VBoxContainer
var nav: HBoxContainer
var funds: Label
var gems: Button
var location_label: Label
var toast_label: Label
var toast_panel: PanelContainer
var scene_art
var bindings: Array[Callable] = []
var page = "KIOSK"
var page_scroll = {}
var testing = false
var paused = false
var skip_frame = false
var clock_accumulator = 0.0
var save_accumulator = 0.0
var update_accumulator = 0.0
var toast_left = 0.0
var last_sales = 0
var last_revenue = 0
var pointer_origin = Vector2.ZERO
var pointer_down = false
var pointer_dragged = false
var block_until = 0
var tap_cooldown = 0.0
var chime: AudioStreamPlayer

func _ready():
	ui.app = self
	pages = Pages.new(self)
	var away_result = {}
	if not testing and not capture_mode():
		var stored = saves.load_game()
		if not stored.is_empty():
			game.s = stored
			away_result = game.offline(maxf(0,Time.get_unix_time_from_system()-game.s.last_wall))
	build_shell()
	build_sound()
	get_viewport().size_changed.connect(layout)
	layout()
	change_page("KIOSK")
	call_deferred("layout")
	last_sales = int(game.s.sales)
	last_revenue = int(game.s.revenue)
	if not away_result.is_empty() and away_result.seconds > 20:
		toast("Willkommen zurück! %d Verkäufe · %s netto in %s." % [away_result.sales,Model.money(away_result.cash),Model.duration(away_result.seconds)],8)
	elif saves.migrated: toast("Dein bisheriger Spielstand wurde nach Los Angeles übernommen.",8)
	elif saves.recovered: toast("Dein Spielstand wurde aus der Sicherung wiederhergestellt.",8)
	if capture_mode(): call_deferred("capture_preview")
	# Persist recovered/offline progress and cancel the previous absence reminder on launch.
	call_deferred("persist")

func capture_mode() -> bool:
	return "--capture-idle" in OS.get_cmdline_user_args()

func build_shell():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var backdrop = ColorRect.new()
	backdrop.color = Color("174859")
	backdrop.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(backdrop)
	app = Control.new()
	add_child(app)
	var surface = ColorRect.new()
	surface.name = "Surface"
	surface.color = Color("eef4e7")
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.add_child(surface)
	var header = PanelContainer.new()
	header.name = "Header"
	header.add_theme_stylebox_override("panel",ui.style(Widgets.INK,0))
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	app.add_child(header)
	var hv = VBoxContainer.new()
	hv.add_theme_constant_override("separation",2)
	header.add_child(hv)
	var title_row = ui.row(hv)
	ui.label(title_row,"DIVORA KIOSK LM",17,Widgets.CREAM)
	var options = ui.button(title_row,"☰",func(): change_page("OPTIONEN"),Widgets.GOLD)
	options.custom_minimum_size = Vector2(48,32)
	options.size_flags_horizontal = Control.SIZE_SHRINK_END
	var cash_row = ui.row(hv)
	funds = ui.label(cash_row,"$0.00",27,Color("ffdd7a"))
	gems = ui.button(cash_row,"0 Juwelen +",func(): change_page("SHOP"),Color("e7d5ff"))
	gems.custom_minimum_size.y = 38
	gems.size_flags_horizontal = Control.SIZE_SHRINK_END
	location_label = ui.label(hv,"LOS ANGELES · ECHO PARK",11,Color("acdadb"))
	body = ScrollContainer.new()
	body.name = "PageScroll"
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	body.scroll_deadzone = 12
	body.follow_focus = true
	body.mouse_filter = Control.MOUSE_FILTER_STOP
	app.add_child(body)
	content = VBoxContainer.new()
	content.name = "PageContent"
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation",12)
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	body.add_child(content)
	nav = HBoxContainer.new()
	nav.name = "Navigation"
	nav.add_theme_constant_override("separation",4)
	app.add_child(nav)
	for title in ["KIOSK","WAREN","STADT","TEAM","SHOP"]:
		var target = title
		var b = ui.button(nav,title,func(): change_page(target),Widgets.GOLD)
		b.custom_minimum_size.y = 60
		b.add_theme_font_size_override("font_size",12)
		b.set_meta("page",title)
	toast_panel = PanelContainer.new()
	toast_panel.add_theme_stylebox_override("panel",ui.style(Widgets.INK,12,true))
	toast_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.add_child(toast_panel)
	toast_label = ui.label(toast_panel,"",14,Widgets.CREAM)
	toast_panel.hide()

func layout():
	if app == null: return
	var viewport_size = get_viewport_rect().size
	var safe_top = 0.0
	var safe_bottom = 0.0
	if OS.get_name() == "iOS":
		var safe = DisplayServer.get_display_safe_area()
		var screen = DisplayServer.window_get_size()
		if screen.y > 0:
			safe_top = safe.position.y*viewport_size.y/screen.y
			safe_bottom = maxf(0,(screen.y-safe.end.y)*viewport_size.y/screen.y)
	var w = minf(500,viewport_size.x)
	var h = viewport_size.y-safe_top-safe_bottom
	app.position = Vector2((viewport_size.x-w)*0.5,safe_top)
	app.size = Vector2(w,h)
	app.get_node("Surface").size = Vector2(w,h)
	var header = app.get_node("Header")
	header.position = Vector2.ZERO
	header.size = Vector2(w,120)
	body.position = Vector2(12,130)
	body.size = Vector2(w-24,maxf(100,h-206))
	nav.position = Vector2(8,h-68)
	nav.size = Vector2(w-16,60)
	toast_panel.position = Vector2(20,h-145)
	toast_panel.size = Vector2(w-40,64)
	if is_instance_valid(scene_art): scene_art.custom_minimum_size.y = (w-24)*2.0/3.0

func bind(update: Callable):
	bindings.append(update)
	update.call()

func refresh_values():
	funds.text = Model.money(int(game.s.cash))
	gems.text = "%d Juwelen +" % int(game.s.gems)
	location_label.text = "LOS ANGELES · %s · BEZIRK %d" % [Model.LOCATIONS[int(game.s.active)].name.to_upper(),int(game.s.round)]
	for update in bindings: update.call()

func change_page(target: String):
	if content == null: return
	page_scroll[page] = body.scroll_vertical
	page = target
	bindings.clear()
	scene_art = null
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	pages.show_page(page)
	# Deferred restoration waits for the new minimum content height, avoiding scroll jumps.
	body.set_deferred("scroll_vertical",int(page_scroll.get(page,0)))
	for b in nav.get_children():
		b.add_theme_stylebox_override("normal",ui.style(Widgets.GOLD if b.get_meta("page") == page else Color("d5e8de"),10,true))
	refresh_values()
	layout()

func can_activate() -> bool:
	return Time.get_ticks_msec() >= block_until and not (pointer_down and pointer_dragged)

func _input(event):
	# Native ScrollContainer cancels button presses on drag; this guard also covers
	# release-order edge cases and gestures starting on a shop purchase button.
	if event is InputEventScreenTouch:
		if event.index != 0: return
		if event.pressed:
			pointer_origin = event.position
			pointer_down = true
			pointer_dragged = false
		else:
			if pointer_dragged: block_until = Time.get_ticks_msec()+180
			pointer_down = false
	elif event is InputEventScreenDrag and event.index == 0 and pointer_down:
		if event.position.distance_to(pointer_origin) > 10: pointer_dragged = true

func act(operation: Callable, message: String = ""):
	var result = operation.call()
	if result is bool and not result:
		toast("Noch nicht möglich. Prüfe Guthaben, Level und laufende Aufgaben.")
	elif message != "": toast(message)
	persist()
	refresh_values()

func serve():
	if tap_cooldown > 0: return
	tap_cooldown = 0.3
	if not game.serve(): toast("Keine verkäufliche Ware. Bestelle im Warenlager nach.")
	sale_feedback()
	refresh_values()

func build_sound():
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	var bytes = PackedByteArray()
	bytes.resize(6000)
	for i in range(3000):
		var t = float(i)/22050.0
		var sample = int(sin(TAU*(880*t+1600*t*t))*exp(-t*35)*8000)
		bytes[i*2] = sample & 255
		bytes[i*2+1] = (sample >> 8) & 255
	sound.data = bytes
	chime = AudioStreamPlayer.new()
	chime.stream = sound
	chime.volume_db = -15
	add_child(chime)

func sale_feedback():
	if game.s.sales > last_sales:
		if is_instance_valid(scene_art): scene_art.sold(int(game.s.revenue)-last_revenue)
		if game.s.sound and chime != null and not chime.playing: chime.play()
	last_sales = int(game.s.sales)
	last_revenue = int(game.s.revenue)

func toast(message: String, seconds: float = 4.0):
	toast_label.text = message
	toast_left = seconds
	toast_panel.show()

func _process(delta):
	if paused: return
	if skip_frame:
		skip_frame = false
		return
	tap_cooldown = maxf(0,tap_cooldown-delta)
	toast_left = maxf(0,toast_left-delta)
	if toast_left <= 0 and toast_panel != null: toast_panel.hide()
	clock_accumulator += delta
	save_accumulator += delta
	update_accumulator += delta
	if clock_accumulator >= 1.0:
		var steps = floor(clock_accumulator)
		clock_accumulator -= steps
		var revision = game.revision
		game.advance(steps)
		if game.revision != revision:
			toast(str(game.s.events[0]))
			write_notification_plan()
		sale_feedback()
	if update_accumulator >= 0.25:
		update_accumulator = 0
		refresh_values()
	if save_accumulator >= 15:
		save_accumulator = 0
		persist()

func persist() -> bool:
	if testing or capture_mode(): return true
	game.s.last_wall = int(Time.get_unix_time_from_system())
	if not saves.save_game(game.s):
		toast("Speichern fehlgeschlagen. Bitte die App geöffnet lassen.",10)
		return false
	write_notification_plan()
	return true

func notification_status_text() -> String:
	if OS.get_name() != "iOS": return "Native Fertigmeldungen sind in diesem Build für iPhone/iPad vorgesehen."
	if not game.s.notifications: return "Ausgeschaltet. Es werden keine Fertigmeldungen geplant."
	var path = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS).path_join("divora_notification_status.json")
	if FileAccess.file_exists(path):
		var f = FileAccess.open(path,FileAccess.READ)
		if f != null and f.get_length() < 1000:
			var parser = JSON.new()
			if parser.parse(f.get_as_text()) == OK and parser.data is Dictionary:
				if parser.data.get("status") == "denied": return "iOS-Erlaubnis fehlt. Bitte unter Einstellungen → Mitteilungen → Divora erlauben."
				if parser.data.get("status") == "allowed": return "iOS-Erlaubnis erteilt. Lieferungen und Ausbauten melden sich, wenn sie fertig sind."
	return "iOS fragt nach deiner Erlaubnis. Bitte den Systemdialog bestätigen."

func notification_plan() -> Dictionary:
	var tasks = []
	var now = Time.get_unix_time_from_system()
	for task in game.s.tasks:
		var name_value = "Lieferung" if task.kind == "delivery" else ("Ausbau" if task.kind == "upgrade" else "Filiale")
		tasks.append({"id":"divora-%d" % int(task.id),"due":now+game.remaining(task),"title":"Divora Kiosk LM",
			"body":"%s in %s fertig. Dein Kiosk wartet auf dich!" % [name_value,Model.LOCATIONS[int(task.site)].name]})
	if paused and game.s.notifications:
		var earns_offline = game.s.franchise_income > 0
		for shop in game.s.stores:
			if shop.owned and shop.open: earns_offline = true
		if earns_offline:
			tasks.append({"id":"divora-offline-limit","due":now+Model.OFFLINE_CAP,"title":"Deine Offline-Schicht ist vorbei",
				"body":"Die 8-Stunden-Grenze ist erreicht. Öffne Divora Kiosk LM für deine nächste Schicht."})
	return {"enabled":bool(game.s.notifications),"tasks":tasks}

func write_notification_plan():
	if testing or capture_mode(): return
	var directory = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS) if OS.get_name() == "iOS" else "user://"
	var file = FileAccess.open(directory.path_join("divora_notifications.json.tmp"),FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify(notification_plan()))
	file.close()
	DirAccess.rename_absolute(directory.path_join("divora_notifications.json.tmp"),directory.path_join("divora_notifications.json"))

func _notification(what):
	if not is_node_ready(): return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		paused = true
		persist()
	elif what == NOTIFICATION_APPLICATION_RESUMED and paused:
		paused = false
		var result = game.offline(maxf(0,Time.get_unix_time_from_system()-game.s.last_wall))
		clock_accumulator = 0
		skip_frame = true
		toast("Zurück im Kiosk: %s netto · %d Verkäufe." % [Model.money(result.cash),result.sales],6)
		persist()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST: persist()

func capture_preview():
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--page="): change_page(arg.trim_prefix("--page="))
	await get_tree().create_timer(2).timeout
	get_viewport().get_texture().get_image().save_png("res://build/idle-%s-%dx%d.png" % [page.to_lower(),int(get_viewport_rect().size.x),int(get_viewport_rect().size.y)])
	get_tree().quit()
