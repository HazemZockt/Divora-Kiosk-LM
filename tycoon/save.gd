extends RefCounted
const Model = preload("res://tycoon/economy.gd")
var folder = "user://"

func path() -> String:
	return folder.path_join("divora_tycoon_v2.json")

func valid(data) -> bool:
	if not data is Dictionary or data.get("version") != 2:
		return false
	for key in ["cash","day","minute","last_wall","active","stores","sales","revenue","costs","wages","rent_paid","fines","taxes","reputation","heat","policy","suspended_until","events","ledger","next_customer","total_stock_cost","daily_operating"]:
		if not data.has(key):
			return false
	if not data.stores is Array or data.stores.size() != Model.LOCATIONS.size():
		return false
	if not data.events is Array or not data.ledger is Array or data.policy not in ["check","risk"]:
		return false
	if not number(data.cash) or not number(data.day) or not number(data.minute) or not number(data.active):
		return false
	if data.day < 1 or data.minute < 0 or data.minute >= 1440 or data.active < 0 or data.active >= Model.LOCATIONS.size():
		return false
	for store in data.stores:
		if not store is Dictionary or not store.has_all(["owned","open","staff","level","prices","stock","expiry"]):
			return false
		if not store.prices is Array or not store.stock is Array or not store.expiry is Array:
			return false
		if store.prices.size() != Model.PRODUCTS.size() or store.stock.size() != Model.PRODUCTS.size() or store.expiry.size() != Model.PRODUCTS.size():
			return false
		if not number(store.staff) or not number(store.level) or store.staff < 0 or store.staff > 5 or store.level < 0 or store.level > 4:
			return false
		for i in range(Model.PRODUCTS.size()):
			if not number(store.stock[i]) or not number(store.prices[i]) or not number(store.expiry[i]):
				return false
			if store.stock[i] < 0 or store.stock[i] > 204 or store.prices[i] < 10:
				return false
	return bool(data.stores[int(data.active)].owned)

func number(value) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func read(candidate: String) -> Dictionary:
	if not FileAccess.file_exists(candidate):
		return {}
	var f = FileAccess.open(candidate,FileAccess.READ)
	if f == null or f.get_length() > 2000000:
		return {}
	var parsed = JSON.new()
	if parsed.parse(f.get_as_text()) != OK or not parsed.data is Dictionary:
		return {}
	var envelope = parsed.data
	if not envelope.has_all(["payload","sha256"]) or not envelope.payload is String:
		return {}
	if envelope.payload.sha256_text() != envelope.sha256:
		return {}
	var data = JSON.parse_string(envelope.payload)
	return data if valid(data) else {}

func load_game() -> Dictionary:
	var data = read(path())
	return read(path()+".bak") if data.is_empty() else data

func save_game(state: Dictionary) -> bool:
	if not valid(state):
		return false
	var payload = JSON.stringify(state)
	var f = FileAccess.open(path()+".tmp",FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify({"payload":payload,"sha256":payload.sha256_text()}))
	f.flush()
	f.close()
	if read(path()+".tmp").is_empty():
		return false
	if not read(path()).is_empty() and DirAccess.copy_absolute(path(),path()+".bak") != OK:
		return false
	return DirAccess.rename_absolute(path()+".tmp",path()) == OK
