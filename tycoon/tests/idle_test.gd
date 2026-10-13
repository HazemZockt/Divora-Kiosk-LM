extends SceneTree
const Model = preload("res://tycoon/idle_economy.gd")
const Storage = preload("res://tycoon/idle_save.gd")
var failures = []
var checks = 0
func ck(ok: bool, message: String):
	checks += 1
	if not ok:
		failures.append(message)
		printerr("FAIL: ",message)
func _initialize():
	create_timer(30).timeout.connect(func():
		printerr("FAIL: Economy test did not finish within 30 seconds")
		quit(1))
	var e = Model.new()
	ck(e.s.cash == 0 and e.s.gems == 0,"No free premium currency or cash at start")
	ck(e.s.stores[0].stock[0] == 24,"Starter sample enables zero-money start")
	ck(not e.order(0),"Cannot order without cash")
	ck(e.serve() and e.s.cash > 0,"Serve sells existing stock")
	e.s.cash = 100000
	var before = e.s.stores[0].stock[0]
	ck(e.order(0),"Paid order starts delivery")
	ck(e.s.stores[0].stock[0] == before,"Stock never appears before timer")
	ck(not e.order(0),"Duplicate delivery blocked")
	e.s.stores[0].open = false
	e.advance(10)
	ck(e.s.stores[0].stock[0] == before,"Delivery still waiting")
	ck(not e.skip_task(e.s.tasks[0].id),"Skip requires premium gems")
	e.s.gems = 2
	ck(e.skip_task(e.s.tasks[0].id),"Gems can skip delivery")
	ck(e.s.stores[0].stock[0] == before+12 and e.s.gems == 1,"Skip charges once and delivers once")
	ck(not e.skip_task(999),"Missing task cannot charge gems")
	var level = e.s.stores[0].level
	ck(e.upgrade(),"Upgrade starts")
	ck(e.s.stores[0].level == level,"Level unchanged while building")
	e.advance(40)
	ck(e.s.stores[0].level == level+1,"Level rises when wait ends")
	ck(not e.redeem("wrong"),"Invalid code rejected")
	ck(not e.gem_pack(0),"Real purchases unavailable in test")
	ck(e.redeem("Hayat") and e.gem_pack(0),"Test owner can claim free gem pack")
	ck(e.s.gems > 1,"Test pack credits currency")
	ck(not e.gem_pack(-1) and not e.order(-1) and not e.choose(99),"Invalid indices rejected")
	var m = Model.new()
	m.s.cash = 100000
	ck(m.hire_manager(),"Manager hired")
	m.s.stores[0].stock[0] = 0
	m.advance(1)
	ck(m.s.tasks.size() == 1,"Manager orders stock automatically")
	m.advance(60)
	ck(m.s.sales > 0,"Automated shop resumes sales")
	var rescue = Model.new()
	rescue.s.stores[0].stock[0] = 0
	ck(rescue.emergency_order(),"Empty penniless player can recover")
	ck(not rescue.emergency_order(),"Emergency supply cannot be spammed")
	rescue.s.stores[0].open = false
	rescue.advance(60)
	ck(rescue.s.stores[0].stock[0] == 12,"Emergency sample arrives after real wait")
	var away = Model.new()
	away.s.cash = 100000
	away.order(0)
	away.s.stores[0].open = false
	away.offline(100000)
	ck(away.s.tasks.is_empty(),"Long absence completes pending tasks")
	ck(away.s.elapsed <= Model.OFFLINE_CAP,"Offline sales simulation bounded")
	var online = Model.new()
	var chunked = Model.new()
	online.advance(59)
	for i in range(59): chunked.advance(1)
	ck(online.s.cash == chunked.s.cash and online.s.sales == chunked.s.sales,"Chunked and continuous time agree")
	var crime = Model.new()
	crime.s.cash = 100000
	crime.s.stores[0].unlocked[5] = true
	crime.s.stores[0].stock[5] = 2
	ck(crime.sell(0,5,true) == "refused","Age checking refuses minor")
	crime.s.policy = "risk"
	ck(crime.sell(0,5,true) == "sold" and crime.s.heat > 0,"Risk sale creates police heat")
	ck(crime.police_check(true) and crime.s.fines > 0,"Police charges substantial penalty")
	ck(crime.sell(0,5,false) == "suspended","Police restriction applies")
	var reserved = Model.new()
	reserved.s.cash = 100000
	reserved.current().unlocked[5] = true
	reserved.current().stock[5] = reserved.capacity()-12
	reserved.order(5)
	ck(not reserved.shady_deal(),"Risky supplier cannot use space reserved for a paid delivery")
	reserved.current().open = false
	reserved.advance(70)
	ck(reserved.current().stock[5] == reserved.capacity(),"Paid delivery respects reserved storage capacity")
	var franchise = Model.new()
	franchise.s.cash = 1000000000
	for shop in franchise.s.stores: shop.owned = true; shop.level = 10
	var first_cost = franchise.location_cost(1)
	ck(franchise.expand_city(),"New franchise district opens")
	ck(franchise.s.round == 2 and franchise.location_cost(1) > first_cost,"New district increases prices")
	ck(franchise.s.stores[0].owned and franchise.s.stores[0].stock[0] > 0,"Expansion remains playable")
	var io = Storage.new()
	io.folder = "user://idle_test_%d" % Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(io.folder)
	ck(io.save_game(e.s),"Save accepts current state")
	var loaded = io.load_game()
	ck(not loaded.is_empty() and loaded.gems == e.s.gems,"Premium currency survives reload")
	var bad = e.s.duplicate(true)
	bad.tasks = [{"id":1}]
	ck(not io.valid(bad),"Malformed timer rejected")
	bad = e.s.duplicate(true)
	bad.stores[0].stock[0] = -5
	ck(not io.valid(bad),"Negative inventory rejected")
	bad = e.s.duplicate(true)
	bad.stores[0].staff = 1.5
	ck(not io.valid(bad),"Fractional staff count rejected")
	bad = e.s.duplicate(true)
	bad.round = 1.5
	ck(not io.valid(bad),"Fractional franchise round rejected")
	reserved.order(0)
	bad = reserved.s.duplicate(true)
	bad.tasks[0].quantity = 12.5
	ck(not io.valid(bad),"Fractional delivery quantity rejected")
	io.save_game(e.s)
	var file = FileAccess.open(io.path(),FileAccess.WRITE)
	file.store_string("broken")
	file.close()
	ck(not io.load_game().is_empty(),"Corrupt primary restores backup")
	var legacy = preload("res://tycoon/economy.gd").new()
	legacy.s.cash = 6700
	var migrated = io.migrate_v2(legacy.s)
	ck(migrated.cash == 6700 and migrated.stores[0].stock[0] == 12,"v2 money and inventory preserved")
	ck(migrated.version == 3 and migrated.gems == 0,"Migration grants no premium currency")
	if failures.is_empty(): print("IDLE PASS: %d checks" % checks)
	quit(0 if failures.is_empty() else 1)
