extends SceneTree
const Game = preload("res://tycoon/idle_game.gd")
var errors = []
var checks = 0
func ck(ok: bool, why: String):
	checks += 1
	if not ok:
		errors.append(why)
		printerr("FAIL: ",why)
func frame(count: int = 3):
	for i in range(count): await process_frame
func touch(pos: Vector2, pressed: bool):
	var event = InputEventScreenTouch.new()
	event.position = pos
	event.index = 0
	event.pressed = pressed
	Input.parse_input_event(event)
func drag(from: Vector2, to: Vector2):
	var event = InputEventScreenDrag.new()
	event.index = 0
	event.position = to
	event.relative = to-from
	event.velocity = (to-from)*10
	Input.parse_input_event(event)
func _initialize():
	call_deferred("run")
func run():
	root.size = Vector2i(420,900)
	var app = Game.new()
	app.testing = true
	root.add_child(app)
	await frame(5)
	ck(app.body.size.y > 500,"Main content has useful viewport height")
	ck(app.app.get_node("Header").size.y < 160,"Header never grows over the scrollable page")
	app.game.s.cash = app.Model.MONEY_CAP
	app.game.s.gems = 1000000
	app.refresh_values()
	await frame(5)
	ck(app.gems.get_global_rect().end.x <= app.app.get_global_rect().end.x,"Large premium balance stays inside phone header")
	ck(app.app.get_node("Header").size.y < 160,"Large balances do not cover the content")
	app.game.s.cash = 0
	app.game.s.gems = 0
	app.change_page("WAREN")
	await frame(5)
	var original = app.content.get_child(2)
	app.body.scroll_vertical = 240
	await frame()
	app._process(2)
	await frame()
	ck(is_instance_valid(original) and original == app.content.get_child(2),"Ticks never destroy touch targets")
	ck(app.body.scroll_vertical == 240,"Ticks preserve scroll offset")
	app.body.scroll_vertical = 0
	await frame()
	var start = app.body.global_position+Vector2(160,410)
	touch(start,true)
	await frame()
	var previous = start
	for i in range(10):
		var next = start-Vector2(0,20*(i+1))
		drag(previous,next)
		previous = next
		await frame(1)
	touch(previous,false)
	await frame(5)
	ck(app.body.scroll_vertical > 60,"Native finger swipe scrolls content")
	ck(not app.can_activate(),"Drag release blocks accidental purchase")
	app.change_page("SHOP")
	await frame(5)
	var code = app.content.find_child("RedeemCode",true,false)
	ck(code != null,"Shop code input exists")
	code.text = "Haya"
	code.grab_focus()
	app._process(2)
	await frame()
	ck(code.text == "Haya" and code.has_focus(),"Tick preserves text and keyboard focus")
	code.text = "Hayat"
	code.text_submitted.emit(code.text)
	await frame()
	ck(app.game.s.admin,"Code activates test access through actual UI")
	ck(code.text.is_empty(),"Successful code clears input")
	app.game.s.cash = 10000
	app.game.order(0)
	app.game.s.notifications = true
	var plan = app.notification_plan()
	ck(plan.enabled and plan.tasks.size() == 1,"Pending timer creates notification plan")
	ck(plan.tasks[0].due > Time.get_unix_time_from_system(),"Notification deadline is a future wall-clock time")
	app.game.s.gems = 50
	app.game.skip_task(app.game.s.tasks[0].id)
	ck(app.notification_plan().tasks.is_empty(),"Skipping cancels corresponding notification")
	app.paused = true
	var offline_plan = app.notification_plan()
	ck(offline_plan.tasks.size() == 1,"Pausing schedules an offline earnings limit reminder")
	if not offline_plan.tasks.is_empty():
		ck(absf(offline_plan.tasks[0].due-Time.get_unix_time_from_system()-app.Model.OFFLINE_CAP) < 2,"Offline reminder uses eight real hours")
	app.paused = false
	ck(app.notification_plan().tasks.is_empty(),"Resuming cancels offline limit reminder")
	for page in ["KIOSK","WAREN","STADT","TEAM","SHOP","KASSE","RISIKO","ZIELE","OPTIONEN"]:
		app.change_page(page)
		await frame(3)
		ck(app.content.get_child_count() > 1,"Page renders: "+page)
	app.queue_free()
	await frame()
	if errors.is_empty(): print("IDLE UI PASS: %d checks" % checks)
	quit(0 if errors.is_empty() else 1)
