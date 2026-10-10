extends Control
const Model = preload("res://tycoon/economy.gd")
const INK = Color("1b3437")
const IVORY = Color("f6ead1")
const GOLD = Color("f5c467")
var economy: RefCounted
var active_customer = 0.0

func setup(model):
	economy = model
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta):
	if active_customer > 0:
		active_customer -= delta
		queue_redraw()

func sale_animation():
	active_customer = 1.7
	queue_redraw()

func text(value: String, at: Vector2, size_px: int, color: Color, align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, width_px: float = -1):
	draw_string(ThemeDB.fallback_font,at,value,align,width_px,size_px,color)

func _draw():
	if economy == null:
		return
	var w = size.x
	var h = size.y
	var site = int(economy.s.active)
	var store = economy.s.stores[site]
	# Full kiosk front is drawn as original vector geometry and scales with the window.
	draw_rect(Rect2(0,0,w,h),Color("c8ded5"))
	draw_rect(Rect2(0,h*0.84,w,h*0.16),Color("a4b7aa"))
	for i in range(14):
		var x = float(i)*w/13
		draw_line(Vector2(x,h*0.86),Vector2(x-15,h),Color("93a69b"),1)
	draw_rect(Rect2(w*0.05,h*0.17,w*0.9,h*0.69),Color("b9976d"))
	draw_rect(Rect2(w*0.07,h*0.18,w*0.86,h*0.63),Color("f2dfba"))
	draw_rect(Rect2(w*0.045,h*0.11,w*0.91,h*0.12),INK)
	text("DIVORA KIOSK LM",Vector2(w*0.08,h*0.2),clampi(int(w*0.061),17,26),IVORY,HORIZONTAL_ALIGNMENT_CENTER,w*0.84)
	# Awning with alternating fabric panels.
	for stripe in range(12):
		var x = w*0.045 + stripe*w*0.91/12
		var tint = Color("c86e57") if stripe%2 == 0 else Color("ffedd0")
		draw_colored_polygon(PackedVector2Array([Vector2(x,h*0.235),Vector2(x+w*0.91/12,h*0.235),Vector2(x+w*0.91/12-4,h*0.34),Vector2(x+3,h*0.34)]),tint)
	draw_line(Vector2(w*0.04,h*0.34),Vector2(w*0.96,h*0.34),INK,3)
	# Shelves with the actual stock mix.
	draw_rect(Rect2(w*0.1,h*0.38,w*0.49,h*0.36),Color("44665f"))
	for row in range(3):
		var y = h*(0.48+row*0.11)
		draw_rect(Rect2(w*0.105,y,w*0.48,5),Color("b9895d"))
		for col in range(5):
			var idx = (row*5+col)%Model.PRODUCTS.size()
			if int(store.stock[idx]) <= col/2:
				continue
			var px = w*(0.13+col*0.085)
			var tint = Color(Model.PRODUCTS[idx].color)
			draw_rect(Rect2(px,y-18,12,17),tint)
			draw_rect(Rect2(px+2,y-11,8,4),IVORY)
	# Window, service hatch, front counter and side door.
	draw_rect(Rect2(w*0.60,h*0.38,w*0.28,h*0.33),Color("356063"))
	draw_rect(Rect2(w*0.612,h*0.39,w*0.256,h*0.29),Color("93bbc1"))
	draw_rect(Rect2(w*0.63,h*0.53,w*0.21,h*0.13),Color("dbc8a5"))
	draw_rect(Rect2(w*0.085,h*0.7,w*0.81,h*0.14),Color("a6704e"))
	draw_rect(Rect2(w*0.075,h*0.69,w*0.83,h*0.035),Color("453f39"))
	for line_no in range(1,12):
		var x = w*(0.085+line_no*0.067)
		draw_line(Vector2(x,h*0.74),Vector2(x,h*0.83),Color("8c5b42"),2)
	# Lighting and a customer silhouette make the illustration feel alive.
	draw_circle(Vector2(w*0.75,h*0.45),9,GOLD)
	if active_customer > 0:
		draw_circle(Vector2(w*0.73,h*0.61),h*0.065,Color("4f5861"))
		draw_rect(Rect2(w*0.68,h*0.66,w*0.1,h*0.14),Color("7a5961"))
		draw_rect(Rect2(w*0.59,h*0.37,w*0.3,h*0.055),Color("193a3c"))
		text("VERKAUF  +  " + Model.euro(int(store.prices[0])),Vector2(w*0.61,h*0.405),12,IVORY)
	if site > 0:
		text(Model.LOCATIONS[site].name.to_upper(),Vector2(w*0.085,h*0.81),12,Color("f5e7c9"))
	if not store.open:
		draw_rect(Rect2(w*0.6,h*0.42,w*0.28,h*0.13),Color("f5e8ce"))
		text("GESCHLOSSEN",Vector2(w*0.615,h*0.5),13,INK)
