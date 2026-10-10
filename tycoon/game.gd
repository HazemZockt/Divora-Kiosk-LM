extends Control
const Model = preload("res://tycoon/economy.gd")
const SaveFile = preload("res://tycoon/save.gd")
const KioskView = preload("res://tycoon/kiosk_view.gd")
const DARK = Color("19383b")
const DARKER = Color("10272a")
const SAND = Color("f7f2e7")
const MUTED = Color("70837e")
const GOLD = Color("e8ad57")
var game = Model.new()
var saves = SaveFile.new()
var app: Control
var header: Control
var kiosk: Control
var summary: PanelContainer
var body: ScrollContainer
var content: VBoxContainer
var nav: HBoxContainer
var funds: Label
var subtitle: Label
var status: Label
var page = "LADEN"
var elapsed = 0.0
var save_elapsed = 0.0
var last_sales = 0
var last_event = ""
var font = ThemeDB.fallback_font

func _ready():
	var stored = saves.load_game()
	if not stored.is_empty():
		game.s = stored
		var away = clampi(int(Time.get_unix_time_from_system())-int(game.s.last_wall),0,600)
		for i in range(away):
			game.tick(1.0)
		if away > 0:
			game.event("Während deiner Abwesenheit lief das Geschäft %d Sekunden weiter." % away)
	build_ui()
	get_viewport().size_changed.connect(layout)
	layout()
	refresh()
	last_sales = int(game.s.sales)
	if "--capture-portrait" in OS.get_cmdline_user_args() or "--capture-small" in OS.get_cmdline_user_args():
		call_deferred("capture_preview")

func box_color(color: Color, radius: int = 16) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.content_margin_left = 13
	style.content_margin_right = 13
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style

func label(parent: Node, value: String, size_px: int = 16, color: Color = DARK, wrap: bool = false) -> Label:
	var l = Label.new()
	l.text = value
	l.add_theme_font_size_override("font_size",size_px)
	l.add_theme_color_override("font_color",color)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if wrap else TextServer.AUTOWRAP_OFF
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func button(parent: Node, title: String, action: Callable, fill: bool = false, muted: bool = false) -> Button:
	var b = Button.new()
	b.text = title
	b.custom_minimum_size.y = 43
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL if fill else Control.SIZE_SHRINK_END
	b.add_theme_font_size_override("font_size",14)
	b.add_theme_color_override("font_color",SAND if not muted else DARK)
	b.add_theme_stylebox_override("normal",box_color(DARK if not muted else Color("e4e8db"),10))
	b.add_theme_stylebox_override("hover",box_color(Color("335c5e"),10))
	b.add_theme_stylebox_override("pressed",box_color(Color("b9774b"),10))
	b.add_theme_stylebox_override("disabled",box_color(Color("bbc9bd"),10))
	b.add_theme_color_override("font_disabled_color",Color("55706a"))
	b.focus_mode = Control.FOCUS_NONE
	parent.add_child(b)
	b.pressed.connect(action)
	return b

func row(parent: Node = null) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation",8)
	(parent if parent else content).add_child(h)
	return h

func card(parent: Node = null, color: Color = Color("ffffff")) -> VBoxContainer:
	var container = PanelContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_stylebox_override("panel",box_color(color))
	(parent if parent else content).add_child(container)
	var vertical = VBoxContainer.new()
	vertical.add_theme_constant_override("separation",7)
	container.add_child(vertical)
	return vertical

func section(title: String, details: String = ""):
	label(content,title,21,DARK)
	if details != "":
		label(content,details,13,MUTED,true)

func build_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color("d8e2d5")
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)
	app = Control.new()
	add_child(app)
	var surface = PanelContainer.new()
	surface.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	surface.add_theme_stylebox_override("panel",box_color(SAND,0))
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	app.add_child(surface)
	header = Control.new()
	app.add_child(header)
	var header_bg = ColorRect.new()
	header_bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	header_bg.color = DARKER
	header_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	header.add_child(header_bg)
	var head = HBoxContainer.new()
	head.anchor_right = 1
	head.offset_left = 17
	head.offset_right = -17
	head.offset_top = 13
	head.offset_bottom = 75
	header.add_child(head)
	var brand = VBoxContainer.new()
	brand.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(brand)
	label(brand,"DIVORA",22,SAND)
	subtitle = label(brand,"KIOSK LM  ·  TAG 1",12,GOLD)
	var cash_box = VBoxContainer.new()
	head.add_child(cash_box)
	var cash_title = label(cash_box,"DEIN GELD",10,GOLD)
	cash_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	funds = label(cash_box,"0,00 €",22,SAND)
	funds.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	kiosk = KioskView.new()
	app.add_child(kiosk)
	kiosk.setup(game)
	summary = PanelContainer.new()
	summary.add_theme_stylebox_override("panel",box_color(Color("e4eee4"),12))
	app.add_child(summary)
	status = label(summary,"",14,DARK,true)
	body = ScrollContainer.new()
	body.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.follow_focus = true
	app.add_child(body)
	content = VBoxContainer.new()
	content.add_theme_constant_override("separation",9)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(content)
	nav = HBoxContainer.new()
	nav.add_theme_constant_override("separation",3)
	app.add_child(nav)
	for tab in ["LADEN","WAREN","ORTE","TEAM","KASSE","REGELN"]:
		var tab_value = tab
		var tab_button = button(nav,tab,func(): change_page(tab_value),true)
		tab_button.custom_minimum_size.y = 54
		tab_button.add_theme_font_size_override("font_size",11)
		tab_button.add_theme_stylebox_override("normal",box_color(Color("284549"),7))
		tab_button.set_meta("tab",tab)

func layout():
	if app == null:
		return
	var available = get_viewport_rect().size
	var width = minf(480,available.x)
	var height = available.y
	app.position = Vector2((available.x-width)*0.5,0)
	app.size = Vector2(width,height)
	header.position = Vector2.ZERO
	header.size = Vector2(width,82)
	kiosk.position = Vector2(12,90)
	kiosk.size = Vector2(maxf(100,width-24),clampf(height*0.29,150,245))
	summary.position = Vector2(12,kiosk.position.y+kiosk.size.y+8)
	summary.size = Vector2(width-24,58)
	body.position = Vector2(12,summary.position.y+summary.size.y+8)
	body.size = Vector2(width-24,maxf(70,height-body.position.y-75))
	nav.position = Vector2(10,height-67)
	nav.size = Vector2(width-20,58)
	for tab_button in nav.get_children():
		tab_button.add_theme_stylebox_override("normal",box_color(GOLD if tab_button.get_meta("tab") == page else DARK,7))
		tab_button.add_theme_color_override("font_color",DARKER if tab_button.get_meta("tab") == page else SAND)
	kiosk.queue_redraw()

func change_page(next_page: String):
	page = next_page
	body.scroll_vertical = 0
	refresh()
	layout()

func refresh():
	if content == null:
		return
	funds.text = Model.euro(int(game.s.cash))
	subtitle.text = "KIOSK LM  ·  TAG %d" % int(game.s.day)
	var store = game.s.stores[int(game.s.active)]
	var place = Model.LOCATIONS[int(game.s.active)]
	status.text = "%s · %s\n%d Verkäufe · Vermögen %s" % [place.name,"OFFEN" if store.open else "ZU",int(game.s.sales),Model.euro(game.wealth())]
	var previous = body.scroll_vertical
	for child in content.get_children():
		content.remove_child(child)
		child.queue_free()
	match page:
		"LADEN": show_kiosk()
		"WAREN": show_goods()
		"ORTE": show_locations()
		"TEAM": show_staff()
		"KASSE": show_finance()
		"REGELN": show_rules()
	body.scroll_vertical = previous
	layout()
	kiosk.queue_redraw()

func action(callable: Callable, success: String = ""):
	var result = callable.call()
	if result is bool and not result:
		game.event("Aktion derzeit nicht möglich. Geld, Vorrat oder Standort prüfen.")
	elif success != "":
		game.event(success)
	game.s.last_wall = int(Time.get_unix_time_from_system())
	saves.save_game(game.s)
	refresh()

func show_kiosk():
	section("Dein kleiner Laden","Starte bei 0 € und arbeite dich Standort für Standort hoch.")
	var welcome = card()
	label(welcome,"DEIN NÄCHSTER SCHRITT",12,Color("a36e36"))
	var goal = "Verkaufe die 12 geschenkten Wasserflaschen." if game.s.cash < 12000 else "Übernimm einen neuen Standort oder erweitere den Kiosk."
	label(welcome,goal,16,DARK,true)
	var active_store = game.s.stores[int(game.s.active)]
	var controls = row()
	button(controls,"Schließen" if active_store.open else "Öffnen",func(): action(func(): active_store.open = not active_store.open),true)
	var cost = 18000*(int(active_store.level)+1)
	button(controls,"Ausbau " + Model.euro(cost),func(): action(game.upgrade),true).disabled = game.s.cash < cost or active_store.level >= 4
	var overview = card()
	label(overview,"HEUTE IM KIOSK",12,Color("a36e36"))
	var stocked = 0
	for count in active_store.stock: stocked += int(count)
	label(overview,"%d Waren vorrätig   ·   %d Mitarbeiter" % [stocked,int(active_store.staff)],17)
	label(overview,"%s Umsatz gesamt   ·   Stufe %d / 4" % [Model.euro(int(game.s.revenue)),int(active_store.level)],14,MUTED)
	label(overview,"Rang %d / 6  ·  Nächstes Vermögensziel: %s" % [game.rank(),Model.euro(game.next_rival()) if game.next_rival() > 0 else "REICHSTER!"],13,Color("a36e36"),true)
	button(content,"Ware bestellen",func(): change_page("WAREN"),true)
	section("Was gerade passiert")
	for text_value in game.s.events.slice(0,4):
		label(card(),text_value,14,DARK,true)

func show_goods():
	section("Ware & Verkaufspreise","Ein Karton enthält 12 Stück. Kunden kaufen automatisch, solange geöffnet ist und Ware im Regal steht.")
	var store = game.s.stores[int(game.s.active)]
	for index in range(Model.PRODUCTS.size()):
		var p = Model.PRODUCTS[index]
		var product = index
		var block = card()
		var top = row(block)
		var name_label = label(top,p.name + ("  ·  18+" if p.regulated else ""),18,DARK)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label(top,"%d Stück" % int(store.stock[index]),15,Color("5d756f"))
		label(block,"EK %s · Verkauf %s · Haltbarkeit %d Tage" % [Model.euro(int(p.cost)),Model.euro(int(store.prices[index])),int(p.life)],13,MUTED)
		var buttons = row(block)
		button(buttons,"− Preis",func(): action(func(): game.set_price(product,-10)),true)
		button(buttons,"+ Preis",func(): action(func(): game.set_price(product,10)),true)
		var cost = int(p.cost)*12
		button(buttons,"12 kaufen · " + Model.euro(cost),func(): action(func(): game.buy_stock(product)),true).disabled = game.s.cash < cost or store.stock[index]+12 > 60+store.level*36
	label(content,"Hohe Preise können Kunden abschrecken. Verderbliche Ware wird nach ihrer Frist ausgebucht.",13,MUTED,true)

func show_locations():
	section("Deine Standorte","Mehr Laufkundschaft bedeutet höhere Miete. Angestellte betreiben Filialen weiter, wenn du anderswo bist.")
	for index in range(Model.LOCATIONS.size()):
		var site = Model.LOCATIONS[index]
		var store = game.s.stores[index]
		var selected = index
		var block = card()
		label(block,site.name + ("  ✓" if store.owned else ""),18,DARK)
		label(block,"%s · %d Kunden/Tag · Miete %s" % [site.area,int(site.traffic),Model.euro(int(site.rent))],13,MUTED,true)
		if store.owned:
			button(block,"Aktiver Standort" if game.s.active == index else "Hier arbeiten",func(): action(func(): game.choose_location(selected)),true).disabled = game.s.active == index
		else:
			button(block,"Übernehmen · " + Model.euro(int(site.unlock)),func(): action(func(): game.buy_location(selected)),true).disabled = game.s.cash < site.unlock

func show_staff():
	section("Personal & Schichten","Jede Arbeitskraft kostet %s pro Spieltag. Ohne Personal verkauft eine Filiale nur, wenn du dort bist." % Model.euro(Model.WAGE))
	var store = game.s.stores[int(game.s.active)]
	var block = card()
	label(block,"%s" % Model.LOCATIONS[int(game.s.active)].name,20)
	label(block,"%d / 5 Angestellte" % int(store.staff),17,MUTED)
	var controls = row(block)
	button(controls,"+ Einstellen",func(): action(game.hire),true).disabled = store.staff >= 5 or game.s.cash < Model.WAGE
	button(controls,"− Entlassen",func(): action(game.dismiss),true).disabled = store.staff < 1
	label(block,"Tageslohn dieser Filiale: %s" % Model.euro(int(store.staff)*Model.WAGE),14,MUTED)
	section("Deine Kioskkette")
	for i in range(Model.LOCATIONS.size()):
		if game.s.stores[i].owned:
			label(card(),"%s  ·  %d im Team" % [Model.LOCATIONS[i].name,int(game.s.stores[i].staff)],15)

func show_finance():
	section("Kasse & Vermögen","Umsatz allein macht dich nicht reich. Einkauf, Miete und Lohn müssen sich rechnen.")
	var block = card()
	for pair in [["Verfügbares Geld",game.s.cash],["Firmenwert",game.wealth()],["Gesamtumsatz",game.s.revenue],["Wareneinkäufe",game.s.total_stock_cost],["Bezahlte Mieten",game.s.rent_paid],["Gehälter",game.s.wages],["Strafen",game.s.fines],["Steuerrücklage",game.s.taxes]]:
		var line = row(block)
		label(line,pair[0],14,MUTED)
		var figure = label(line,Model.euro(int(pair[1])),15,DARK)
		figure.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	label(block,"Vermögensrang: %d von 6 · Ziel: der reichste Kioskbesitzer" % game.rank(),14,Color("a36e36"),true)
	section("Letzte Buchungen")
	for entry in game.s.ledger.slice(0,20):
		var line = row(card())
		label(line,entry.label,13,DARK,true)
		var amount = label(line,Model.euro(int(entry.amount)),13,Color("3f9278") if entry.amount >= 0 else Color("ae5f4f"))
		amount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func show_rules():
	section("Regeln für 18+ Ware","Vapes und Snus sind im Spiel regulierte Waren. Die Regeln und Beträge sind fiktive Spielwerte.")
	var safe = card()
	label(safe,"Altersprüfung",18)
	label(safe,"Minderjährige werden abgewiesen. Kein Verkauf, kein Verstoß.",14,MUTED,true)
	button(safe,"Aktiv ✓" if game.s.policy == "check" else "Altersprüfung aktivieren",func(): action(func(): game.set_policy("check")),true)
	var risk = card()
	label(risk,"Riskanter Verkauf",18)
	label(risk,"Verkäufe an Minderjährige erhöhen das Kontrollrisiko. Polizeikontrollen führen zu sehr hohen Strafen, Rufverlust und einer dreitägigen Sperre regulierter Ware.",14,MUTED,true)
	button(risk,"Aktiv ✓" if game.s.policy == "risk" else "Riskanten Verkauf wählen",func(): action(func(): game.set_policy("risk")),true)
	label(content,"Kontrollrisiko: %d / 100" % mini(100,int(game.s.heat)),16,Color("ae5f4f"))
	if game.s.suspended_until > game.s.day:
		label(content,"REGULIERTE WARE GESPERRT BIS TAG %d" % int(game.s.suspended_until),15,Color("ae5f4f"),true)
	for text_value in game.s.events:
		if text_value.contains("POLIZEI") or text_value.contains("Altersprüfung"):
			label(card(),text_value,13,DARK,true)

func _process(delta):
	elapsed += delta
	save_elapsed += delta
	if elapsed >= 1.0:
		var steps = mini(3,int(elapsed))
		elapsed -= steps
		for i in range(steps): game.tick(1.0)
		if game.s.sales > last_sales:
			kiosk.sale_animation()
			last_sales = int(game.s.sales)
		refresh()
	if save_elapsed >= 15:
		save_elapsed = 0
		persist()

func persist():
	game.s.last_wall = int(Time.get_unix_time_from_system())
	saves.save_game(game.s)

func _notification(what):
	if what in [NOTIFICATION_APPLICATION_PAUSED,NOTIFICATION_WM_CLOSE_REQUEST] and is_instance_valid(saves):
		persist()

func capture_preview():
	await get_tree().create_timer(2).timeout
	var filename = "tycoon-small.png" if "--capture-small" in OS.get_cmdline_user_args() else "tycoon-portrait.png"
	get_viewport().get_texture().get_image().save_png("res://build/" + filename)
	get_tree().quit()
