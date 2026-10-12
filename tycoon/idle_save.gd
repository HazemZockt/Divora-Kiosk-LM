extends RefCounted
const Model = preload("res://tycoon/idle_economy.gd")
const LegacySave = preload("res://tycoon/save.gd")
var folder = "user://"
var recovered = false
var migrated = false

func path() -> String:
	return folder.path_join("divora_idle_v3.json")

func number(value, low: float = 0, high: float = Model.MONEY_CAP) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and value >= low and value <= high

func valid(data) -> bool:
	if not data is Dictionary or data.get("version") != 3: return false
	var defaults = Model.new().s
	for key in defaults:
		if not data.has(key): return false
	for key in ["cash","gems","round","active","elapsed","last_wall","next_task","sales","revenue","purchases","rent_paid","wages","fines","theft","hour_clock","crime_clock","heat","suspended_until","reputation","franchise_income","income_fraction"]:
		if not number(data[key],-Model.MONEY_CAP if key == "cash" else 0): return false
	if data.gems > 1000000 or data.round < 1 or data.active > 5 or data.active != int(data.active) or data.hour_clock >= 3600 or data.crime_clock >= 300 or data.heat > 100: return false
	for key in ["admin","notifications","sound","reduced_motion"]:
		if not data[key] is bool: return false
	if data.policy not in ["check","risk"] or not data.stores is Array or data.stores.size() != 6: return false
	if not data.tasks is Array or data.tasks.size() > 54 or not data.events is Array or data.events.size() > 30 or not data.ledger is Array or data.ledger.size() > 50 or not data.quests is Array: return false
	for text in data.events:
		if not text is String or text.length() > 1000: return false
	for entry in data.ledger:
		if not entry is Dictionary or not entry.has_all(["label","amount","category"]): return false
		if not entry.label is String or not entry.category is String or not number(entry.amount,-Model.MONEY_CAP): return false
	for quest in data.quests:
		if not number(quest,0,3) or quest != int(quest): return false
	for shop in data.stores:
		if not shop is Dictionary or not shop.has_all(["owned","open","level","staff","manager","security","stock","prices","unlocked","sale_clock","cursor"]): return false
		for key in ["owned","open","manager"]:
			if not shop[key] is bool: return false
		if not number(shop.level,1,1000000) or not number(shop.staff,0,5) or not number(shop.security,0,3) or not number(shop.sale_clock,0,10) or not number(shop.cursor,0,6): return false
		for key in ["stock","prices","unlocked"]:
			if not shop[key] is Array or shop[key].size() != 7: return false
		for i in range(7):
			if not number(shop.stock[i],0,12060) or shop.stock[i] != int(shop.stock[i]) or not number(shop.prices[i],1) or not shop.unlocked[i] is bool: return false
	var ids = []
	var slots = []
	for task in data.tasks:
		if not task is Dictionary or not task.has_all(["id","kind","site","product","quantity","due","duration"]): return false
		if task.kind not in ["delivery","upgrade","location"]: return false
		for key in ["id","site","product","quantity","due","duration"]:
			if not number(task[key],-1 if key == "product" else 0): return false
		if task.id < 1 or task.id >= data.next_task or task.id in ids or task.site > 5 or task.site != int(task.site) or task.product > 6 or task.product != int(task.product) or task.duration <= 0 or task.duration > 7200: return false
		if task.kind == "delivery" and (task.product < 0 or task.quantity < 12 or task.quantity > 120 or not data.stores[int(task.site)].owned): return false
		if task.kind != "delivery" and task.product != -1: return false
		var slot = "%s:%d:%d" % [task.kind,int(task.site),int(task.product)]
		if slot in slots: return false
		slots.append(slot)
		ids.append(task.id)
	return bool(data.stores[int(data.active)].owned)

func read(candidate: String) -> Dictionary:
	if not FileAccess.file_exists(candidate): return {}
	var file = FileAccess.open(candidate,FileAccess.READ)
	if file == null or file.get_length() > 2000000: return {}
	var parser = JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	var envelope = parser.data
	if not envelope is Dictionary or not envelope.get("payload") is String or not envelope.get("sha256") is String: return {}
	if envelope.payload.sha256_text() != envelope.sha256: return {}
	if parser.parse(envelope.payload) != OK: return {}
	var data = parser.data
	return data if valid(data) else {}

func load_game() -> Dictionary:
	var data = read(path())
	if not data.is_empty(): return data
	data = read(path()+".bak")
	if not data.is_empty():
		recovered = true
		return data
	# Keep the original v2 file intact, and only import after its original validator passes.
	var old = LegacySave.new()
	old.folder = folder
	data = old.load_game()
	if not data.is_empty():
		migrated = true
		return migrate_v2(data)
	return {}

func migrate_v2(old: Dictionary) -> Dictionary:
	var model = Model.new()
	model.s.cash = int(old.cash)
	for key in ["sales","revenue","rent_paid","wages","fines","reputation"]: model.s[key] = old[key]
	model.s.purchases = int(old.total_stock_cost)
	model.s.last_wall = int(Time.get_unix_time_from_system())
	model.s.active = int(old.active)
	for i in range(6):
		var shop = model.s.stores[i]
		shop.owned = bool(old.stores[i].owned)
		shop.open = bool(old.stores[i].open)
		shop.level = int(old.stores[i].level)+1
		shop.staff = int(old.stores[i].staff)
		for p in range(7):
			shop.stock[p] = int(old.stores[i].stock[p])
			shop.prices[p] = int(old.stores[i].prices[p])
			shop.unlocked[p] = p == 0 or shop.stock[p] > 0
	model.event("Dein bisheriges Geld, Personal und Inventar wurden nach Los Angeles übernommen.")
	return model.s

func save_game(state: Dictionary) -> bool:
	if not valid(state): return false
	var payload = JSON.stringify(state)
	var file = FileAccess.open(path()+".tmp",FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify({"payload":payload,"sha256":payload.sha256_text()}))
	file.flush()
	file.close()
	if read(path()+".tmp").is_empty(): return false
	if not read(path()).is_empty() and DirAccess.copy_absolute(path(),path()+".bak") != OK: return false
	return DirAccess.rename_absolute(path()+".tmp",path()) == OK
