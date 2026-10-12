extends RefCounted
## Deterministic real-time economy. UI and native notifications only read this state.
const TEST_BUILD = true
const OFFLINE_CAP = 8 * 3600
const MONEY_CAP = 900000000000000
const PRODUCTS = [
	{"name":"Wasser","cost":55,"price":170,"level":1,"color":"52c8ef","icon":"water"},
	{"name":"Limonade","cost":95,"price":280,"level":2,"color":"ffba45","icon":"soda"},
	{"name":"Chips","cost":110,"price":340,"level":3,"color":"ff7557","icon":"chips"},
	{"name":"Kaffee","cost":145,"price":490,"level":5,"color":"b9855a","icon":"coffee"},
	{"name":"Sandwich","cost":190,"price":650,"level":8,"color":"8bcb65","icon":"sandwich"},
	{"name":"Vapes · 18+","cost":480,"price":1390,"level":12,"color":"bb8ee6","icon":"vape"},
	{"name":"Snus · 18+","cost":330,"price":990,"level":15,"color":"78a7a0","icon":"snus"}
]
const LOCATIONS = [
	{"name":"Echo Park","landmark":"Der Anfang am See","cost":0,"rent":0,"traffic":1.0},
	{"name":"Venice Beach","landmark":"Palmen am Boardwalk","cost":12000,"rent":1400,"traffic":1.7},
	{"name":"Downtown LA","landmark":"Skyline & Grand Central","cost":85000,"rent":6900,"traffic":3.0},
	{"name":"Santa Monica","landmark":"Pier & Pacific Park","cost":380000,"rent":23000,"traffic":5.5},
	{"name":"Hollywood","landmark":"Hügel & Griffith Observatory","cost":1450000,"rent":49000,"traffic":9.0},
	{"name":"Beverly Hills","landmark":"Luxus am Rodeo Drive","cost":6500000,"rent":140000,"traffic":16.0}
]
const PACKS = [
	{"name":"Handvoll Juwelen","gems":100,"price":"0,99 €"},
	{"name":"Kiosk-Koffer","gems":550,"price":"4,99 €"},
	{"name":"Tycoon-Tresor","gems":1250,"price":"9,99 €"}
]
var s: Dictionary
var revision = 0

func _init():
	reset()

func reset():
	s = {"version":3,"cash":0,"gems":0,"admin":false,"round":1,"active":0,
		"elapsed":0.0,"last_wall":int(Time.get_unix_time_from_system()),"stores":[],"tasks":[],"next_task":1,
		"sales":0,"revenue":0,"purchases":0,"rent_paid":0,"wages":0,"fines":0,"theft":0,
		"hour_clock":0.0,"crime_clock":0.0,"heat":0.0,"policy":"check","suspended_until":0.0,
		"reputation":50.0,"notifications":false,"sound":true,"reduced_motion":false,
		"events":[],"ledger":[],"quests":[],"franchise_income":0.0,"income_fraction":0.0}
	new_stores()
	event("Willkommen in LA! 24 Wasserflaschen sind dein Startkapital.")

func new_stores():
	s.stores = []
	for i in range(LOCATIONS.size()):
		var stock = []
		var prices = []
		var unlocked = []
		for p in range(PRODUCTS.size()):
			stock.append(24 if i == 0 and p == 0 else 0)
			prices.append(scaled(PRODUCTS[p].price))
			unlocked.append(p == 0)
		s.stores.append({"owned":i == 0,"open":true,"level":1,"staff":0,"manager":false,
			"security":0,"stock":stock,"prices":prices,"unlocked":unlocked,"sale_clock":0.0,"cursor":0})

static func money(cents: int) -> String:
	var value = absf(float(cents))/100.0
	var prefix = "−" if cents < 0 else ""
	for unit in [[1e12," Bio."],[1e9," Mrd."],[1e6," Mio."],[1e3," Tsd."]]:
		if value >= unit[0]: return prefix + "$%.2f%s" % [value/unit[0],unit[1]]
	return prefix + "$%.2f" % value

static func duration(seconds: float) -> String:
	var n = maxi(0,int(ceil(seconds)))
	if n >= 3600: return "%dh %02dm" % [n/3600,(n%3600)/60]
	if n >= 60: return "%dm %02ds" % [n/60,n%60]
	return "%ds" % n

func scaled(value: float) -> int:
	return mini(MONEY_CAP,maxi(1,int(value * pow(4.0,minf(18.0,s.round-1)))))

func event(message: String):
	s.events.push_front(message)
	if s.events.size() > 30: s.events.resize(30)

func book(message: String, amount: int, category: String):
	s.cash = clampi(int(s.cash)+amount,-MONEY_CAP,MONEY_CAP)
	s.ledger.push_front({"label":message,"amount":amount,"category":category})
	if s.ledger.size() > 50: s.ledger.resize(50)

func current() -> Dictionary:
	return s.stores[int(s.active)]

func capacity(site: int = -1) -> int:
	return 60 + mini(1000,int(s.stores[site if site >= 0 else int(s.active)].level))*12

func task_for(kind: String, site: int, product: int = -1) -> Dictionary:
	for task in s.tasks:
		if task.kind == kind and task.site == site and task.product == product: return task
	return {}

func remaining(task: Dictionary) -> float:
	return maxf(0,float(task.due)-float(s.elapsed)) if not task.is_empty() else 0.0

func skip_cost(task: Dictionary) -> int:
	return maxi(1,int(ceil(remaining(task)/60.0)))

func schedule(kind: String, site: int, seconds: float, product: int = -1, quantity: int = 0):
	s.tasks.append({"id":int(s.next_task),"kind":kind,"site":site,"product":product,"quantity":quantity,
		"due":s.elapsed+seconds,"duration":seconds})
	s.next_task += 1
	revision += 1

func order(product: int, cases: int = 1, site: int = -1) -> bool:
	var index = int(s.active) if site < 0 else site
	if index < 0 or index >= s.stores.size() or product < 0 or product >= PRODUCTS.size() or cases < 1 or cases > 10: return false
	var shop = s.stores[index]
	var count = 12*cases
	var cost = scaled(PRODUCTS[product].cost)*count
	if not shop.owned or not shop.unlocked[product] or shop.stock[product]+count > capacity(index) or s.cash < cost or not task_for("delivery",index,product).is_empty(): return false
	book("Einkauf · " + PRODUCTS[product].name,-cost,"purchase")
	s.purchases += cost
	schedule("delivery",index,20.0+product*10.0,product,count)
	return true

func upgrade_cost(site: int = -1) -> int:
	var shop = s.stores[int(s.active) if site < 0 else site]
	return scaled(1800.0 * pow(1.14,minf(200,shop.level-1)))

func upgrade() -> bool:
	var cost = upgrade_cost()
	if not current().owned or s.cash < cost or not task_for("upgrade",int(s.active)).is_empty(): return false
	book("Kiosk-Ausbau",-cost,"investment")
	schedule("upgrade",int(s.active),minf(7200,30.0+current().level*5.0))
	return true

func unlock_product(product: int) -> bool:
	if product < 0 or product >= PRODUCTS.size(): return false
	var shop = current()
	var cost = scaled(1000*product)
	if shop.unlocked[product] or shop.level < PRODUCTS[product].level or s.cash < cost: return false
	book("Sortiment · " + PRODUCTS[product].name,-cost,"investment")
	shop.unlocked[product] = true
	revision += 1
	return true

func set_price(product: int, delta: int) -> bool:
	if product < 0 or product >= PRODUCTS.size() or not current().unlocked[product]: return false
	var base = scaled(PRODUCTS[product].price)
	current().prices[product] = clampi(int(current().prices[product])+scaled(absi(delta))*(1 if delta >= 0 else -1),scaled(PRODUCTS[product].cost)+1,int(base*1.5))
	return true

func location_cost(site: int) -> int:
	return scaled(LOCATIONS[site].cost)

func buy_location(site: int) -> bool:
	if site <= 0 or site >= LOCATIONS.size() or s.stores[site].owned or not task_for("location",site).is_empty(): return false
	var cost = location_cost(site)
	if s.cash < cost: return false
	book("Filiale · " + LOCATIONS[site].name,-cost,"investment")
	schedule("location",site,60.0*site)
	return true

func choose(site: int) -> bool:
	if site < 0 or site >= s.stores.size() or not s.stores[site].owned: return false
	s.active = site
	revision += 1
	return true

func hire() -> bool:
	var cost = scaled(2000)
	if current().staff >= 5 or s.cash < cost: return false
	book("Personal einstellen",-cost,"investment")
	current().staff += 1
	revision += 1
	return true

func hire_manager() -> bool:
	if current().manager or s.cash < scaled(4500): return false
	book("Manager einstellen",-scaled(4500),"investment")
	current().manager = true
	revision += 1
	return true

func security_upgrade() -> bool:
	var cost = scaled(3000*(current().security+1))
	if current().security >= 3 or s.cash < cost: return false
	book("Sicherheitsausbau",-cost,"investment")
	current().security += 1
	revision += 1
	return true

func complete(task: Dictionary):
	var shop = s.stores[int(task.site)]
	match task.kind:
		"delivery":
			shop.stock[int(task.product)] += int(task.quantity)
			event("Lieferung da: %s in %s." % [PRODUCTS[int(task.product)].name,LOCATIONS[int(task.site)].name])
		"upgrade":
			shop.level += 1
			event("%s ist jetzt Level %d!" % [LOCATIONS[int(task.site)].name,int(shop.level)])
		"location":
			shop.owned = true
			shop.stock[0] = 24
			event("Deine neue Filiale in %s ist eröffnet!" % LOCATIONS[int(task.site)].name)
	s.tasks.erase(task)
	revision += 1

func skip_task(id: int) -> bool:
	for task in s.tasks.duplicate():
		if task.id == id:
			var cost = skip_cost(task)
			if s.gems < cost: return false
			s.gems -= cost
			complete(task)
			return true
	return false

func redeem(code: String) -> bool:
	if not TEST_BUILD or code.strip_edges() != "Hayat": return false
	s.admin = true
	event("Testzugang aktiviert. Juwelenpakete sind jetzt kostenlos.")
	return true

func gem_pack(index: int) -> bool:
	if index < 0 or index >= PACKS.size() or not TEST_BUILD or not s.admin: return false
	s.gems = mini(1000000,int(s.gems)+int(PACKS[index].gems))
	return true

func sale_interval(site: int) -> float:
	var shop = s.stores[site]
	return maxf(0.12,2.5/(float(LOCATIONS[site].traffic)*(1.0+shop.level*0.12+shop.staff*0.3)))

func sell(site: int, product: int, minor: bool = false) -> String:
	if site < 0 or site >= s.stores.size() or product < 0 or product >= PRODUCTS.size(): return "invalid"
	var shop = s.stores[site]
	if not shop.owned or not shop.open: return "closed"
	if product >= 5 and s.elapsed < s.suspended_until: return "suspended"
	if not shop.unlocked[product] or shop.stock[product] <= 0: return "empty"
	if product >= 5 and minor and s.policy == "check": return "refused"
	shop.stock[product] -= 1
	var price = int(shop.prices[product])
	# High prices deterministically lower sales frequency, rather than random UI surprises.
	book("Verkauf · " + PRODUCTS[product].name,price,"sale")
	s.sales += 1
	s.revenue = mini(MONEY_CAP,int(s.revenue)+price)
	s.reputation = minf(100,s.reputation+0.02)
	if product >= 5 and minor: s.heat = minf(100,s.heat+18)
	return "sold"

func serve() -> bool:
	var shop = current()
	for p in range(PRODUCTS.size()):
		if shop.stock[p] > 0 and sell(int(s.active),p) == "sold": return true
	return false

func police_check(force: bool = false) -> bool:
	if s.heat <= 0 or (not force and s.heat < 50): return false
	var fine = scaled(250000+int(s.heat)*3500)
	book("Polizeistrafe",-fine,"fine")
	s.fines = mini(MONEY_CAP,int(s.fines)+fine)
	s.heat = 0.0
	s.suspended_until = s.elapsed+1800
	s.reputation = maxf(0,s.reputation-15)
	event("POLIZEI: %s Strafe. 18+ Sortiment für 30 Minuten gesperrt." % money(fine))
	revision += 1
	return true

func shady_deal() -> bool:
	if current().stock[5]+12 > capacity() or not current().unlocked[5]: return false
	current().stock[5] += 12
	s.heat = minf(100,s.heat+35)
	event("Zwielichtige Lieferung angenommen. Das Polizeirisiko steigt.")
	return true

func hourly_costs():
	for i in range(s.stores.size()):
		var shop = s.stores[i]
		if not shop.owned: continue
		var rent = scaled(LOCATIONS[i].rent) if i > 0 else 0
		var wage = scaled(2200)*(int(shop.staff)+(1 if shop.manager else 0))
		if rent > 0:
			book("Miete · " + LOCATIONS[i].name,-rent,"rent")
			s.rent_paid = mini(MONEY_CAP,int(s.rent_paid)+rent)
		if wage > 0:
			book("Gehälter · " + LOCATIONS[i].name,-wage,"wage")
			s.wages = mini(MONEY_CAP,int(s.wages)+wage)

func advance(seconds: float):
	if not is_finite(seconds) or seconds <= 0: return
	var left = minf(seconds,OFFLINE_CAP)
	while left > 0.00001:
		var step = minf(1.0,left)
		s.elapsed += step
		s.hour_clock += step
		s.crime_clock += step
		for task in s.tasks.duplicate():
			if task.due <= s.elapsed+0.00001: complete(task)
		for i in range(s.stores.size()):
			var shop = s.stores[i]
			if not shop.owned or not shop.open: continue
			shop.sale_clock += step
			var interval = sale_interval(i)
			while shop.sale_clock >= interval:
				shop.sale_clock -= interval
				for offset in range(PRODUCTS.size()):
					var p = (int(shop.cursor)+offset)%PRODUCTS.size()
					if shop.stock[p] <= 0: continue
					shop.cursor = (p+1)%PRODUCTS.size()
					# A predictable customer mix makes offline and online results identical.
					var minor = int(s.sales)%7 == 6
					var ratio = float(shop.prices[p])/scaled(PRODUCTS[p].price)
					if ratio <= 1.2 or int(s.sales+int(s.elapsed))%3 != 0: sell(i,p,minor)
					break
			if shop.manager:
				for p in range(PRODUCTS.size()):
					if shop.unlocked[p] and shop.stock[p] <= 4: order(p,1,i)
		var fractional = s.franchise_income*step+s.income_fraction
		var credit = int(fractional)
		s.income_fraction = fractional-credit
		if credit > 0:
			s.cash = mini(MONEY_CAP,int(s.cash)+credit)
			s.revenue = mini(MONEY_CAP,int(s.revenue)+credit)
		if s.hour_clock >= 3600:
			s.hour_clock -= 3600
			hourly_costs()
		if s.crime_clock >= 300:
			s.crime_clock -= 300
			police_check()
			# Fictional periodic petty theft; security level 3 prevents it entirely.
			for shop in s.stores:
				if shop.owned and shop.open and shop.security < 3 and shop.stock[0] > 2:
					shop.stock[0] -= 3-int(shop.security)
					s.theft += 3-int(shop.security)
					event("Ladendiebstahl. Sicherheit schützt deinen Vorrat.")
			s.heat = maxf(0,s.heat-3)
		left -= step

func offline(seconds: float) -> Dictionary:
	var before = int(s.cash)
	var sold = int(s.sales)
	advance(minf(maxf(0,seconds),OFFLINE_CAP))
	# Beyond the earning cap, construction still uses the full wall-clock interval.
	if seconds > OFFLINE_CAP:
		var cutoff = s.elapsed+seconds-OFFLINE_CAP
		for task in s.tasks.duplicate():
			if task.due <= cutoff: complete(task)
		for task in s.tasks: task.due -= seconds-OFFLINE_CAP
	return {"cash":int(s.cash)-before,"sales":int(s.sales)-sold,"seconds":mini(int(seconds),OFFLINE_CAP)}

func owned_count() -> int:
	var n = 0
	for shop in s.stores:
		if shop.owned: n += 1
	return n

func expand_city() -> bool:
	if owned_count() < 6 or not s.tasks.is_empty(): return false
	for shop in s.stores:
		if shop.level < 10: return false
	# Existing network becomes an abstract franchise earning royalties; repeat indefinitely.
	s.franchise_income += scaled(20.0)
	s.round += 1
	s.active = 0
	new_stores()
	event("Franchise-Bezirk %d eröffnet. Deine alte Kette zahlt dauerhaft Lizenzgebühren!" % int(s.round))
	revision += 1
	return true

func quest_progress(index: int) -> int:
	match index:
		0: return int(s.sales)
		1: return int(current().level)
		2: return owned_count()
		3: return int(s.revenue)
	return 0

func claim_quest(index: int) -> bool:
	var targets = [10,3,2,100000]
	var rewards = [1000,2500,10000,25000]
	if index < 0 or index >= targets.size() or index in s.quests or quest_progress(index) < targets[index]: return false
	s.quests.append(index)
	book("Auftragsbelohnung",rewards[index],"reward")
	return true

func projected_income() -> int:
	var total = float(s.franchise_income)*60
	for i in range(s.stores.size()):
		var shop = s.stores[i]
		if not shop.owned or not shop.open: continue
		var sum_margin = 0.0
		var count = 0
		for p in range(PRODUCTS.size()):
			if shop.unlocked[p] and (shop.stock[p] > 0 or shop.manager):
				sum_margin += shop.prices[p]-scaled(PRODUCTS[p].cost)
				count += 1
		if count > 0: total += sum_margin/count*60.0/sale_interval(i)
	return int(total)
