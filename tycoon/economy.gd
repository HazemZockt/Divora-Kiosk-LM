extends RefCounted
## Fictional kiosk economy. Money is stored as integer cents.
const PRODUCTS = [
	{"name":"Wasser", "cost":55, "base":170, "life":30, "regulated":false, "color":"69b9c3"},
	{"name":"Limonade", "cost":95, "base":260, "life":30, "regulated":false, "color":"edaf52"},
	{"name":"Chips", "cost":110, "base":290, "life":25, "regulated":false, "color":"d8825a"},
	{"name":"Kaffee", "cost":145, "base":390, "life":14, "regulated":false, "color":"957258"},
	{"name":"Sandwich", "cost":190, "base":480, "life":3, "regulated":false, "color":"9ac184"},
	{"name":"Vapes", "cost":480, "base":990, "life":90, "regulated":true, "color":"988dd0"},
	{"name":"Snus", "cost":330, "base":780, "life":60, "regulated":true, "color":"7e9aa0"}
]
const LOCATIONS = [
	{"name":"Straßenkiosk", "area":"Wohnviertel", "unlock":0, "rent":0, "traffic":24, "power":0},
	{"name":"Lindenplatz", "area":"Wohnviertel", "unlock":12000, "rent":1400, "traffic":26, "power":350},
	{"name":"Bahnhof", "area":"Bahnhofsviertel", "unlock":85000, "rent":6900, "traffic":53, "power":950},
	{"name":"Innenstadt", "area":"City", "unlock":380000, "rent":23000, "traffic":90, "power":2500},
	{"name":"Büroviertel", "area":"Business District", "unlock":1450000, "rent":49000, "traffic":128, "power":4800},
	{"name":"Hafenpromenade", "area":"Premiumlage", "unlock":6500000, "rent":140000, "traffic":225, "power":9500}
]
const WAGE = 2200
const RIVAL_WEALTH = [1000000000,200000000,40000000,8000000,800000]
var s: Dictionary
var rng = RandomNumberGenerator.new()

func _init(seed_value: int = 1977):
	rng.seed = seed_value
	reset()

func reset():
	s = {"version":2,"cash":0,"day":1,"minute":480.0,"last_wall":int(Time.get_unix_time_from_system()),
		"active":0,"stores":[],"sales":0,"revenue":0,"costs":0,"wages":0,"rent_paid":0,"fines":0,
		"taxes":0,"reputation":50.0,"heat":0.0,"policy":"check","suspended_until":0,
		"events":[],"ledger":[],"next_customer":0,"total_stock_cost":0,"daily_operating":0}
	for i in range(LOCATIONS.size()):
		var prices = []
		var stock = []
		var expiry = []
		for p in PRODUCTS:
			prices.append(int(p.base))
			stock.append(0)
			expiry.append(0)
		s.stores.append({"owned":i == 0,"open":i == 0,"staff":0,"level":0,"prices":prices,"stock":stock,"expiry":expiry})
	# A supplier's one-time starter sample allows play to begin at exactly €0.
	s.stores[0].stock[0] = 12
	s.stores[0].expiry[0] = 31
	event("12 Wasserflaschen als kostenloses Startpaket erhalten.")

static func euro(cents: int) -> String:
	var a = absi(cents)
	return ("−" if cents < 0 else "") + "%d,%02d €" % [a / 100,a % 100]

func event(message: String):
	s.events.push_front("Tag %d · %s" % [int(s.day),message])
	if s.events.size() > 24:
		s.events.resize(24)

func book(message: String, amount: int, group: String):
	s.cash += amount
	if group in ["sale","rent","power","wage"]:
		s.daily_operating += amount
	s.ledger.push_front({"day":s.day,"label":message,"amount":amount,"group":group})
	if s.ledger.size() > 100:
		s.ledger.resize(100)

func buy_stock(product: int, cases: int = 1) -> bool:
	if product < 0 or product >= PRODUCTS.size() or cases < 1 or cases > 10:
		return false
	var store = s.stores[int(s.active)]
	if not store.owned:
		return false
	var count = 12 * cases
	var price = int(PRODUCTS[product].cost * count)
	if s.cash < price or store.stock[product] + count > 60 + store.level * 36:
		return false
	book("%d × %s eingekauft" % [count,PRODUCTS[product].name],-price,"purchase")
	s.total_stock_cost += price
	store.stock[product] += count
	store.expiry[product] = int(s.day) + int(PRODUCTS[product].life)
	event("%d × %s geliefert." % [count,PRODUCTS[product].name])
	return true

func set_price(product: int, change: int) -> bool:
	if product < 0 or product >= PRODUCTS.size():
		return false
	var store = s.stores[int(s.active)]
	store.prices[product] = clampi(int(store.prices[product]) + change,10,50000)
	return true

func buy_location(index: int) -> bool:
	if index <= 0 or index >= LOCATIONS.size():
		return false
	var store = s.stores[index]
	var cost = int(LOCATIONS[index].unlock)
	if store.owned or s.cash < cost:
		return false
	book("Standort %s übernommen" % LOCATIONS[index].name,-cost,"investment")
	store.owned = true
	store.open = true
	s.active = index
	event("Neuer Standort: %s. Miete fällt täglich an." % LOCATIONS[index].name)
	return true

func choose_location(index: int) -> bool:
	if index < 0 or index >= LOCATIONS.size() or not s.stores[index].owned:
		return false
	s.active = index
	return true

func hire() -> bool:
	var store = s.stores[int(s.active)]
	if not store.owned or store.staff >= 5 or s.cash < WAGE:
		return false
	store.staff += 1
	event("Eine Arbeitskraft in %s eingestellt. Tageslohn %s." % [LOCATIONS[int(s.active)].name,euro(WAGE)])
	return true

func dismiss() -> bool:
	var store = s.stores[int(s.active)]
	if store.staff < 1:
		return false
	store.staff -= 1
	event("Schichtplan in %s angepasst." % LOCATIONS[int(s.active)].name)
	return true

func upgrade() -> bool:
	var store = s.stores[int(s.active)]
	var price = 18000 * (int(store.level) + 1)
	if store.level >= 4 or s.cash < price or not store.owned:
		return false
	book("Kiosk ausgebaut",-price,"investment")
	store.level += 1
	event("Der Kiosk sieht besser aus und bietet mehr Regalplatz.")
	return true

func set_policy(value: String) -> bool:
	if value not in ["check","risk"]:
		return false
	s.policy = value
	event("Altersregel im Unternehmen geändert.")
	return true

func customer_visit(site: int, product: int, minor: bool = false) -> String:
	if site < 0 or site >= LOCATIONS.size() or product < 0 or product >= PRODUCTS.size():
		return "invalid"
	var store = s.stores[site]
	if not store.owned or not store.open or (site != int(s.active) and store.staff == 0):
		return "closed"
	if int(s.day) < int(s.suspended_until) and PRODUCTS[product].regulated:
		return "suspended"
	if store.stock[product] < 1:
		return "empty"
	if PRODUCTS[product].regulated and minor and s.policy == "check":
		event("Altersprüfung: Verkauf von %s verweigert." % PRODUCTS[product].name)
		return "refused"
	var base = float(PRODUCTS[product].base)
	var ratio = float(store.prices[product]) / base
	if ratio > 1.6 or (ratio > 1.2 and rng.randf() < (ratio - 1.1) * 0.7):
		return "price"
	store.stock[product] -= 1
	book("Verkauf · %s · %s" % [LOCATIONS[site].name,PRODUCTS[product].name],int(store.prices[product]),"sale")
	s.daily_operating -= int(PRODUCTS[product].cost)
	s.costs += int(PRODUCTS[product].cost)
	s.revenue += int(store.prices[product])
	s.sales += 1
	s.reputation = minf(100,s.reputation+0.08)
	if PRODUCTS[product].regulated and minor:
		s.heat += 24
		event("Risikoverkauf: %s an minderjährige Person." % PRODUCTS[product].name)
		return "risky_sale"
	return "sold"

func police_check(force: bool = false) -> bool:
	if not force and s.heat < 35 and rng.randf() > 0.03:
		return false
	if s.heat < 1:
		event("Kontrolle ohne Beanstandung.")
		return false
	var penalty = 250000 + int(s.heat) * 3500
	book("Behördliche Geldstrafe",-penalty,"fine")
	s.fines += penalty
	s.suspended_until = int(s.day) + 3
	s.reputation = maxf(0,s.reputation-12)
	s.heat = 0
	event("POLIZEIKONTROLLE: %s Strafe. Regulierte Waren 3 Tage gesperrt." % euro(penalty))
	return true

func daily_close():
	for i in range(LOCATIONS.size()):
		var store = s.stores[i]
		if not store.owned:
			continue
		if i > 0:
			var rent = int(LOCATIONS[i].rent)
			book("Miete · " + LOCATIONS[i].name,-rent,"rent")
			s.rent_paid += rent
			var power = int(LOCATIONS[i].power) + store.level * 180
			book("Strom · " + LOCATIONS[i].name,-power,"power")
		if store.staff > 0:
			var pay = int(store.staff) * WAGE
			book("Gehälter · " + LOCATIONS[i].name,-pay,"wage")
			s.wages += pay
		for p in range(PRODUCTS.size()):
			if int(store.expiry[p]) <= int(s.day) and store.stock[p] > 0:
				event("Verderb: %d × %s in %s." % [store.stock[p],PRODUCTS[p].name,LOCATIONS[i].name])
				store.stock[p] = 0
	# Taxes are a simplified game rule on positive operating cashflow.
	var operational = int(s.daily_operating)
	if operational > 0:
		var tax = int(operational * 0.20)
		if tax > 0:
			book("Steuerrücklage",-tax,"tax")
			s.taxes += tax
	s.day += 1
	s.minute = 480.0
	s.daily_operating = 0
	s.heat = maxf(0,s.heat-5)
	police_check()

func tick(seconds: float):
	# One active game day per 60 real seconds. Visitors depend on location and staff.
	var remaining = maxf(0.0,seconds)
	while remaining > 0.0:
		var step = minf(remaining,(1440.0-float(s.minute))/16.0)
		if step <= 0.0:
			daily_close()
			continue
		s.minute += step * 16.0
		for site in range(LOCATIONS.size()):
			var store = s.stores[site]
			if not store.owned or not store.open or (site != int(s.active) and store.staff == 0):
				continue
			var expected = float(LOCATIONS[site].traffic) * (1.0+store.level*0.15) * step / 60.0
			var n = int(expected)
			if rng.randf() < expected - n:
				n += 1
			for j in range(n):
				var available = []
				for p in range(PRODUCTS.size()):
					if int(store.stock[p]) > 0:
						available.append(p)
				var product = rng.randi_range(0,PRODUCTS.size()-1)
				if not available.is_empty() and rng.randf() < 0.85:
					product = available[rng.randi_range(0,available.size()-1)]
				customer_visit(site,product,rng.randf() < 0.18)
		remaining -= step
		if s.minute >= 1440.0:
			daily_close()

func wealth() -> int:
	var total = int(s.cash)
	for i in range(LOCATIONS.size()):
		if s.stores[i].owned:
			total += int(LOCATIONS[i].unlock)
			total += int(s.stores[i].level)*18000
			for p in range(PRODUCTS.size()):
				total += int(s.stores[i].stock[p]) * int(PRODUCTS[p].cost)
	return total

func rank() -> int:
	var place = 1
	for rival in RIVAL_WEALTH:
		if wealth() < rival:
			place += 1
	return place

func next_rival() -> int:
	var target = -1
	for rival in RIVAL_WEALTH:
		if wealth() < rival:
			target = rival
	return target
