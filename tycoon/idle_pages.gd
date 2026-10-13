extends RefCounted
const Model = preload("res://tycoon/idle_economy.gd")
const W = preload("res://tycoon/idle_widgets.gd")
const MapArt = preload("res://tycoon/idle_map.gd")
var app
var w
var e
var root
func _init(owner):
	app = owner
	w = owner.ui
	e = owner.game
func show_page(page: String):
	root = app.content
	match page:
		"KIOSK": kiosk()
		"WAREN": goods()
		"STADT": city()
		"TEAM": team()
		"SHOP": shop()
		"KASSE": finance()
		"RISIKO": crime()
		"ZIELE": quests()
		"OPTIONEN": options()
	var space = Control.new()
	space.custom_minimum_size.y = 18
	space.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(space)

func task_control(parent: Node, kind: String, site: int, product: int, normal_title: Callable, operation: Callable, available: Callable):
	var progress = ProgressBar.new()
	progress.custom_minimum_size.y = 12
	progress.show_percentage = false
	progress.add_theme_stylebox_override("background",w.style(Color("dae5e2"),6))
	progress.add_theme_stylebox_override("fill",w.style(W.GOLD,6))
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(progress)
	app.bind(func():
		var task = e.task_for(kind,site,product)
		progress.visible = not task.is_empty()
		progress.value = 100*(1.0-e.remaining(task)/float(task.duration)) if not task.is_empty() else 0)
	w.live(parent,func():
		var task = e.task_for(kind,site,product)
		return "Noch %s · läuft auch offline" % Model.duration(e.remaining(task)) if not task.is_empty() else "Bereit",12,W.MUTED)
	w.live_button(parent,func():
		var task = e.task_for(kind,site,product)
		return "Sofort fertig · %d Juwelen" % e.skip_cost(task) if not task.is_empty() else normal_title.call(),func():
		var task = e.task_for(kind,site,product)
		if task.is_empty(): app.act(operation,"Gestartet. Dein Kiosk arbeitet weiter.")
		else: app.act(func(): return e.skip_task(int(task.id)),"Mit Juwelen fertiggestellt."),func():
		var task = e.task_for(kind,site,product)
		return e.s.gems >= e.skip_cost(task) if not task.is_empty() else available.call())

func kiosk():
	var heading = w.row(root)
	w.live(heading,func(): return Model.LOCATIONS[int(e.s.active)].name,25)
	w.live(heading,func(): return "LEVEL %d" % int(e.current().level),17,W.TEAL).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	app.scene_art = app.SceneArt.new()
	app.scene_art.model = e
	app.scene_art.custom_minimum_size.y = 264
	app.scene_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(app.scene_art)
	w.live(root,func(): return "Dein Start: Wasser verkaufen, Kartons nachbestellen, dann den Kiosk ausbauen." if e.s.sales < 10 else "Nächster Meilenstein: neues Sortiment, Manager und deine zweite Filiale.",13,W.MUTED)
	var income = w.card(root,Color("d8eee3"))
	w.label(income,"DEIN KIOSK-IMPERIUM",11,W.TEAL)
	w.live(income,func(): return "%s / Min." % Model.money(e.projected_income()),25)
	w.live(income,func(): return "Mögliche Marge bei Vorrat · %d Filialen · %d Verkäufe" % [e.owned_count(),int(e.s.sales)],12,W.MUTED)
	w.button(income,"Kunden bedienen",app.serve,W.GOLD)
	var level = w.card(root)
	w.live(level,func(): return "Kiosk ausbauen · Level %d → %d" % [int(e.current().level),int(e.current().level)+1],18)
	w.label(level,"Mehr Tempo, größere Regale und neue Produkte.",13,W.MUTED)
	task_control(level,"upgrade",int(e.s.active),-1,func(): return "Ausbauen · "+Model.money(e.upgrade_cost()),e.upgrade,func(): return e.s.cash >= e.upgrade_cost())
	var quick = w.row(root)
	w.button(quick,"Ware bestellen",func(): app.change_page("WAREN"))
	w.button(quick,"Aufträge",func(): app.change_page("ZIELE"),W.GOLD)
	var overview = w.card(root)
	w.live(overview,func():
		var count = 0
		for stock in e.current().stock: count += int(stock)
		return "%d Produkte im Regal · %s" % [count,"Manager aktiv" if e.current().manager else "Du führst den Laden"],16)
	w.live_button(overview,func(): return "Kiosk pausieren" if e.current().open else "Kiosk wieder öffnen",func(): app.act(func():
		e.current().open = not e.current().open
		return true),func(): return true,Color("d7e8df"))
	w.heading(root,"Neues aus deinem Viertel")
	for i in range(4):
		var index = i
		w.live(w.card(root),func(): return str(e.s.events[index]) if e.s.events.size() > index else "Dein nächstes Kapitel wartet.",14)

func goods():
	w.heading(root,"Warenlager","Wähle dein Sortiment. Ein Karton enthält 12 Stück; Nachschub braucht echte Zeit.")
	w.live(root,func(): return "Lagerplatz je Produkt: %d · Manager: %s" % [e.capacity(),"bestellt automatisch" if e.current().manager else "noch keiner"],13,W.MUTED)
	var emergency = w.card(root,Color("fff0bf"))
	w.label(emergency,"Regale leer und kein Geld mehr?",16)
	w.label(emergency,"Dein Lieferant hilft im Notfall mit einer kostenlosen Wasserprobe. 60 Sekunden Lieferzeit, höchstens einmal in 5 Minuten.",12,W.MUTED)
	w.button(emergency,"Notfall-Lieferung anfragen",func(): app.act(e.emergency_order,"Dein Lieferant prüft die Notfall-Anfrage."),W.GOLD)
	for i in range(Model.PRODUCTS.size()):
		var p = i
		var product = Model.PRODUCTS[i]
		var card = w.card(root)
		var top = w.row(card)
		w.icon(top,product.icon,Color(product.color))
		var text = VBoxContainer.new()
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		text.mouse_filter = Control.MOUSE_FILTER_PASS
		top.add_child(text)
		w.label(text,product.name,19)
		w.live(text,func(): return "%d Stück · %s je Stück" % [int(e.current().stock[p]),Model.money(int(e.current().prices[p]))],13,W.MUTED)
		w.live(card,func(): return "Einkauf %s / Karton · benötigt Level %d" % [Model.money(e.scaled(product.cost)*12),int(product.level)],12,W.MUTED)
		w.live_button(card,func(): return "Sortiment freigeschaltet ✓" if e.current().unlocked[p] else "Freischalten · "+Model.money(e.scaled(1000*p)),func(): app.act(func(): return e.unlock_product(p),"Neues Produkt freigeschaltet."),func(): return not e.current().unlocked[p] and e.current().level >= product.level and e.s.cash >= e.scaled(1000*p),W.GOLD)
		task_control(card,"delivery",int(e.s.active),p,func(): return "12 bestellen · "+Model.money(e.scaled(product.cost)*12),func(): return e.order(p),func(): return e.current().unlocked[p] and e.s.cash >= e.scaled(product.cost)*12 and e.current().stock[p]+12 <= e.capacity())
		var prices = w.row(card)
		w.live_button(prices,func(): return "− Preis",func(): app.act(func(): return e.set_price(p,-10)),func(): return e.current().unlocked[p],Color("d7e8df"))
		w.live_button(prices,func(): return "+ Preis",func(): app.act(func(): return e.set_price(p,10)),func(): return e.current().unlocked[p],Color("d7e8df"))
	w.label(root,"Hohe Preise bremsen die Nachfrage. 18+ Waren bergen bei Verstößen ein hohes Polizeirisiko.",13,W.MUTED)

func city():
	w.heading(root,"Los Angeles","Vom ersten Kiosk am Echo Park zu deiner eigenen Kette am Pazifik.")
	var map = MapArt.new()
	map.model = e
	map.custom_minimum_size.y = 280
	root.add_child(map)
	for i in range(Model.LOCATIONS.size()):
		var site = i
		var location = Model.LOCATIONS[i]
		var card = w.card(root)
		w.label(card,"%d  %s" % [i+1,location.name],20)
		w.label(card,location.landmark,13,W.MUTED)
		w.live(card,func(): return "Kundschaft ×%.1f · Miete %s / Std." % [float(location.traffic),Model.money(e.scaled(location.rent) if site > 0 else 0)],13,W.MUTED)
		w.live_button(card,func(): return "Hier bist du ✓" if e.s.active == site else "Filiale besuchen",func():
			app.act(func(): return e.choose(site))
			app.page_scroll["KIOSK"] = 0
			app.change_page("KIOSK"),func(): return e.s.stores[site].owned and e.s.active != site,W.GOLD)
		if i > 0:
			task_control(card,"location",site,-1,func(): return "Bereits eröffnet" if e.s.stores[site].owned else "Eröffnen · "+Model.money(e.location_cost(site)),func(): return e.buy_location(site),func(): return not e.s.stores[site].owned and e.s.cash >= e.location_cost(site))
	var next = w.card(root,Color("fff0bf"))
	w.label(next,"Dein nächster Franchise-Bezirk",20)
	w.label(next,"Alle 6 Filialen auf Level 10 bringen. Danach bleibt deine alte Kette als Lizenzgeschäft erhalten und du baust den nächsten, teureren Bezirk auf. Immer weiter.",14,W.MUTED)
	w.button(next,"Nächsten Bezirk eröffnen",func(): app.act(e.expand_city,"Willkommen im nächsten Franchise-Bezirk!"))

func team():
	w.heading(root,"Dein Team","Personal erhöht dein Verkaufstempo. Manager halten deine Regale automatisch gefüllt, solange du den Einkauf bezahlen kannst.")
	var card = w.card(root)
	var top = w.row(card)
	w.icon(top,"team")
	w.live(top,func(): return "%s\n%d / 5 Mitarbeiter" % [Model.LOCATIONS[int(e.s.active)].name,int(e.current().staff)],18)
	w.label(card,"Eine Arbeitskraft: $22 × Bezirksfaktor / Std. Die Einstellgebühr wird sofort bezahlt.",13,W.MUTED)
	w.live_button(card,func(): return "Einstellen · "+Model.money(e.scaled(2000)),func(): app.act(e.hire,"Dein Team wächst."),func(): return e.current().staff < 5 and e.s.cash >= e.scaled(2000))
	var manager = w.card(root,Color("fff0bf"))
	w.label(manager,"Dein automatischer Nachschub",19)
	w.label(manager,"Der Manager hält eine passende Reserve deiner freigeschalteten Produkte. Lieferung und Einkauf bleiben kostenpflichtig. Schließe den Laden, um Bestellungen zu pausieren.",14,W.MUTED)
	w.live_button(manager,func(): return "Manager eingestellt ✓" if e.current().manager else "Manager holen · "+Model.money(e.scaled(4500)),func(): app.act(e.hire_manager,"Manager aktiv. Auch offline läuft der Nachschub."),func(): return not e.current().manager and e.s.cash >= e.scaled(4500))
	w.button(root,"Sicherheit & Unterwelt",func(): app.change_page("RISIKO"),W.CORAL)
	w.button(root,"Kasse & Buchungen",func(): app.change_page("KASSE"))
	w.button(root,"Aufträge & Fortschritt",func(): app.change_page("ZIELE"),W.GOLD)
	w.heading(root,"Deine laufenden Kosten")
	w.live(w.card(root),func(): return "Nächste Abrechnung in %s. Mieten und Gehälter laufen auch offline, bis zur 8-Stunden-Grenze." % Model.duration(3600-e.s.hour_clock),14,W.MUTED)

func shop():
	w.heading(root,"Juwelen-Shop","Juwelen überspringen Liefer- und Bauzeiten. Echte Käufe sind in dieser Testversion ausgeschaltet.")
	var banner = w.card(root,Color("eee0ff"))
	var top = w.row(banner)
	w.icon(top,"gem",W.TEAL,64)
	w.live(top,func(): return "%d Juwelen\n%s" % [int(e.s.gems),"Testzugang aktiv" if e.s.admin else "Keine echten Zahlungen"],20)
	for i in range(Model.PACKS.size()):
		var index = i
		var pack = Model.PACKS[i]
		var card = w.card(root,Color("fff5d7") if i == 1 else Color.WHITE)
		var line = w.row(card)
		w.icon(line,"gem",W.TEAL,60)
		w.label(line,"%s\n%d Juwelen" % [pack.name,int(pack.gems)],19)
		w.live_button(card,func(): return "Kostenlos holen · TEST" if e.s.admin else pack.price+" · Kauf deaktiviert",func(): app.act(func(): return e.gem_pack(index),"Test-Juwelen gutgeschrieben."),func(): return e.s.admin,W.GOLD)
	var code_card = w.card(root)
	w.label(code_card,"Code einlösen",19)
	w.label(code_card,"Dein Testcode schaltet kostenlose Juwelenpakete frei.",13,W.MUTED)
	var code = LineEdit.new()
	code.name = "RedeemCode"
	code.placeholder_text = "Code eingeben"
	code.custom_minimum_size.y = 52
	code.max_length = 32
	code.add_theme_font_size_override("font_size",18)
	code.add_theme_color_override("font_color",W.INK)
	code.add_theme_color_override("font_placeholder_color",W.MUTED)
	code.add_theme_color_override("caret_color",W.INK)
	code.add_theme_color_override("font_selected_color",W.CREAM)
	code.add_theme_color_override("selection_color",W.TEAL)
	code.add_theme_stylebox_override("normal",w.style(Color("eff5ef"),8,true))
	code_card.add_child(code)
	var redeem = func():
		if e.redeem(code.text):
			code.text = ""
			code.release_focus()
			app.toast("Testzugang aktiv. Wähle oben dein kostenloses Paket.",6)
		else: app.toast("Dieser Code ist nicht gültig.")
		app.persist()
		app.refresh_values()
	w.button(code_card,"Einlösen",redeem)
	code.text_submitted.connect(func(_value): redeem.call())
	w.label(root,"Testbuild 0.3 · Angezeigte Europreise sind Vorschauwerte. Es werden weder Apple-Zahlungen noch Abbuchungen ausgelöst. Juwelen werden außerhalb des Testzugangs nicht im Spiel verdient.",12,W.MUTED)

func finance():
	w.heading(root,"Deine Kasse","Alle Beträge sind Spielgeld in US-Dollar. Juwelen bleiben eine getrennte Währung.")
	for pair in [["Verfügbares Geld","cash"],["Gesamtumsatz","revenue"],["Wareneinkäufe","purchases"],["Bezahlte Miete","rent_paid"],["Gehälter","wages"],["Polizeistrafen","fines"]]:
		var key = pair[1]
		var row = w.row(w.card(root))
		w.label(row,pair[0],15,W.MUTED)
		w.live(row,func(): return Model.money(int(e.s[key])),18).horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	w.heading(root,"Letzte Buchungen")
	for i in range(15):
		var index = i
		w.live(w.card(root),func():
			if index >= e.s.ledger.size(): return "—"
			var entry = e.s.ledger[index]
			return "%s\n%s" % [entry.label,Model.money(int(entry.amount))],14)

func crime():
	w.heading(root,"Sicherheit & Unterwelt","Die Entscheidungen und Strafen hier sind fiktive Spielregeln.")
	var heat = w.card(root,Color("ffeadb"))
	var line = w.row(heat)
	w.icon(line,"shield")
	w.live(line,func(): return "Polizeirisiko %d / 100\nRuf %d / 100" % [int(e.s.heat),int(e.s.reputation)],18)
	w.live(heat,func(): return "18+ Sortiment gesperrt: "+Model.duration(e.s.suspended_until-e.s.elapsed) if e.s.suspended_until > e.s.elapsed else "Keine Verkaufssperre",14,W.MUTED)
	var policy = w.card(root)
	w.label(policy,"Alterskontrollen",19)
	w.label(policy,"Prüfen schützt dich vor Verstößen. Riskante Verkäufe an Minderjährige steigern das Polizeirisiko; ab 50 Risiko droht bei der nächsten Kontrolle eine massive Strafe.",14,W.MUTED)
	w.live_button(policy,func(): return "Ausweis prüfen ✓" if e.s.policy == "check" else "Ausweisprüfung aktivieren",func(): app.act(func():
		e.s.policy = "check"
		return true),func(): return e.s.policy != "check")
	w.live_button(policy,func(): return "Riskanter Verkauf aktiv" if e.s.policy == "risk" else "Riskante Verkäufe zulassen",func(): app.act(func():
		e.s.policy = "risk"
		return true,"Polizeirisiko steigt bei Verstößen."),func(): return e.s.policy != "risk",W.CORAL)
	var deal = w.card(root)
	w.label(deal,"Zwielichtiger Lieferant",19)
	w.label(deal,"12 Vapes ohne Einkaufspreis, dafür +35 Polizeirisiko. Benötigt freigeschaltetes Vape-Sortiment. Hohe Strafen können dich tief ins Minus bringen.",14,W.MUTED)
	w.live_button(deal,func(): return "Riskante Lieferung annehmen",func(): app.act(e.shady_deal,"Lieferung angenommen. Die Polizei wird aufmerksam."),func(): return e.current().unlocked[5] and e.free_capacity(5) >= 12,W.CORAL)
	var security = w.card(root)
	w.live(security,func(): return "Ladensicherheit · Stufe %d / 3" % int(e.current().security),19)
	w.label(security,"Kamera, Alarmanlage und Sicherheitsdienst reduzieren Ladendiebstähle. Stufe 3 verhindert sie.",14,W.MUTED)
	w.live_button(security,func(): return "Sicherheit ausbauen · "+Model.money(e.scaled(3000*(e.current().security+1))),func(): app.act(e.security_upgrade,"Sicherheit verbessert."),func(): return e.current().security < 3 and e.s.cash >= e.scaled(3000*(e.current().security+1)))

func quests():
	w.heading(root,"Dein Weg zum Tycoon","Erfülle Aufträge für Spielgeld. Juwelen bleiben ausschließlich im Shop.")
	var titles = ["Die ersten 10 Verkäufe","Kiosk auf Level 3","Zweite Filiale eröffnen","$1.000 Gesamtumsatz"]
	var targets = [10,3,2,100000]
	var rewards = [1000,2500,10000,25000]
	for i in range(4):
		var index = i
		var card = w.card(root)
		var line = w.row(card)
		w.icon(line,"star")
		w.label(line,titles[i],19)
		w.live(card,func(): return "Fortschritt %d / %d · Belohnung %s" % [mini(e.quest_progress(index),targets[index]),targets[index],Model.money(rewards[index])],13,W.MUTED)
		w.live_button(card,func(): return "Bereits abgeholt ✓" if index in e.s.quests else "Belohnung abholen",func(): app.act(func(): return e.claim_quest(index),"Belohnung gutgeschrieben."),func(): return index not in e.s.quests and e.quest_progress(index) >= targets[index],W.GOLD)

func options():
	w.heading(root,"Einstellungen")
	var card = w.card(root)
	w.live_button(card,func(): return "Fertigmeldungen: AN" if e.s.notifications else "Fertigmeldungen: AUS",func(): app.act(func():
		e.s.notifications = not e.s.notifications
		return true,"iOS fragt nach deiner Erlaubnis. Meldungen erinnern an fertige Aufgaben und das 8-Stunden-Offline-Limit."),func(): return true)
	w.label(card,"Lokale iPhone-/iPad-Mitteilungen funktionieren ohne Server. Du kannst die Erlaubnis auch in den iOS-Einstellungen ändern. Auf Windows und Android zeigt dieser Testbuild nur Hinweise im Spiel.",13,W.MUTED)
	w.live(card,app.notification_status_text,13,W.TEAL)
	w.live_button(card,func(): return "Verkaufsklang: AN" if e.s.sound else "Verkaufsklang: AUS",func(): app.act(func():
		e.s.sound = not e.s.sound
		return true),func(): return true,Color("d7e8df"))
	w.live_button(card,func(): return "Bewegung reduzieren: AN" if e.s.reduced_motion else "Bewegung reduzieren: AUS",func(): app.act(func():
		e.s.reduced_motion = not e.s.reduced_motion
		return true),func(): return true,Color("d7e8df"))
	w.button(card,"Jetzt speichern",func():
		if app.persist(): app.toast("Spielstand gespeichert."),W.GOLD)
	w.label(root,"Divora Kiosk LM · 0.3.0 · Los Angeles\nOffline-Einnahmen bis 8 Stunden. Bau- und Lieferzeiten laufen weiter. App-Daten beim Deinstallieren vorher sichern. Diese Version enthält keine echten Käufe.",13,W.MUTED)
	w.button(root,"Zurück zum Kiosk",func(): app.change_page("KIOSK"))
