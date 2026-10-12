extends "res://tycoon/idle_art.gd"
const BACKDROP = preload("res://assets/kiosk-los-angeles.png")
var model
var clock = 0.0
var sale_time = 0.0
var earnings = 0
func _process(delta):
	if not is_visible_in_tree(): return
	clock += delta
	sale_time = maxf(0,sale_time-delta)
	queue_redraw()
func sold(amount: int):
	earnings = amount
	sale_time = 1.5
func _draw():
	if model == null: return
	draw_texture_rect(BACKDROP,Rect2(Vector2.ZERO,size),false)
	var w = size.x
	var h = size.y
	draw_string(ThemeDB.fallback_font,Vector2(w*0.27,h*0.31),"DIVORA KIOSK LM",HORIZONTAL_ALIGNMENT_CENTER,w*0.43,int(w*0.047),Color("fff3cb"))
	var moving = not model.s.reduced_motion
	# Manager is visible behind the counter; pedestrians walk past in front.
	person(Vector2(w*0.45,h*0.49),w/640,Color("35aaa6"),0,sin(clock*2) if moving else 0)
	for n in range(3):
		var x = fposmod(clock*(18+n*4)+n*w*0.39,w+80)-40 if moving else w*(0.2+n*0.28)
		var y = h*(0.77+n*0.045)
		person(Vector2(x,y),w/530,[Color("ec8b55"),Color("5598c8"),Color("e6bd50")][n],n,clock*7+n if moving else 0)
	if model.s.heat > 0 and fmod(clock,24)<8:
		var x = fmod(clock,24)*w/8-65
		draw_style_box(block(INK),Rect2(x,h*0.91,80,23))
		draw_style_box(block(Color("e6f0f4")),Rect2(x+14,h*0.87,44,19))
		draw_rect(Rect2(x+22,h*0.872,26,10),Color("77b9d7"))
		draw_rect(Rect2(x+28,h*0.85,12,5),Color("ef655d") if int(clock*5)%2 == 0 else Color("60aee8"))
		for offset in [17,64]: draw_circle(Vector2(x+offset,h*0.97),8,INK)
	if not model.current().open:
		draw_style_box(block(Color("173d50")),Rect2(w*0.36,h*0.58,w*0.28,28))
		draw_string(ThemeDB.fallback_font,Vector2(w*0.36,h*0.58+19),"PAUSE",HORIZONTAL_ALIGNMENT_CENTER,w*0.28,15,Color.WHITE)
	if sale_time > 0:
		var y = h*0.55-(1.5-sale_time)*18
		draw_string_outline(ThemeDB.fallback_font,Vector2(w*0.58,y),"+"+model.money(earnings),HORIZONTAL_ALIGNMENT_LEFT,-1,20,3,INK)
		draw_string(ThemeDB.fallback_font,Vector2(w*0.58,y),"+"+model.money(earnings),HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("fff29b"))
