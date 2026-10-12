extends "res://tycoon/idle_art.gd"
var model
func _draw():
	var w = size.x
	var h = size.y
	draw_style_box(block(Color("78d3e7")),Rect2(Vector2.ZERO,size))
	var coast = PackedVector2Array([Vector2(w*0.25,0),Vector2(w,0),Vector2(w,h),Vector2(w*0.05,h),Vector2(w*0.15,h*0.65),Vector2(w*0.29,h*0.45)])
	draw_colored_polygon(coast,Color("e5d9a9"))
	draw_colored_polygon(PackedVector2Array([Vector2(w*0.26,0),Vector2(w,0),Vector2(w,h*0.22),Vector2(w*0.5,h*0.35)]),Color("89ba79"))
	for y in range(5):
		for x in range(5):
			var p = Vector2(w*(0.35+x*0.12),h*(0.29+y*0.13))
			draw_style_box(block(Color("d2c8a3")),Rect2(p,Vector2(w*0.07,h*0.07)))
	var road = PackedVector2Array([Vector2(w*0.2,h*0.88),Vector2(w*0.3,h*0.6),Vector2(w*0.55,h*0.4),Vector2(w*0.82,h*0.25)])
	draw_polyline(road,Color("fdf3cc"),11,true)
	draw_polyline(road,Color("9ba7a3"),6,true)
	draw_line(Vector2(w*0.25,h*0.65),Vector2(w*0.95,h*0.7),Color("fff5d6"),7,true)
	# Pacific Park pier and wheel, skyline, Hollywood hills and Griffith dome.
	draw_rect(Rect2(w*0.06,h*0.55,w*0.21,7),Color("ae7753"))
	var wheel = Vector2(w*0.14,h*0.49)
	draw_arc(wheel,19,0,TAU,32,INK,2,true)
	for n in range(8):
		var p = wheel+Vector2.from_angle(n*TAU/8)*19
		draw_line(wheel,p,Color("f7efc8"),1,true)
		draw_circle(p,3,Color("f77857"))
	draw_line(wheel,Vector2(w*0.1,h*0.55),INK,2)
	draw_line(wheel,Vector2(w*0.18,h*0.55),INK,2)
	for n in range(6):
		var tall = 15+(n*17)%35
		var x = w*0.73+n*9
		draw_rect(Rect2(x,h*0.6-tall,7,tall),Color("5b8491"))
		for k in range(3): draw_rect(Rect2(x+2,h*0.6-tall+5+k*8,3,3),Color("f9db8c"))
	var dome = Vector2(w*0.77,h*0.12)
	draw_circle(dome,14,Color("f6e7cb"))
	draw_rect(Rect2(dome+Vector2(-26,0),Vector2(52,15)),Color("f6e7cb"))
	draw_string(ThemeDB.fallback_font,Vector2(w*0.34,h*0.12),"HOLLYWOOD",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color.WHITE)
	draw_string(ThemeDB.fallback_font,Vector2(w*0.02,h*0.88),"PACIFIC",HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("217c9d"))
	var pins = [Vector2(0.57,0.37),Vector2(0.28,0.79),Vector2(0.74,0.69),Vector2(0.27,0.52),Vector2(0.51,0.23),Vector2(0.73,0.27)]
	for i in range(pins.size()):
		var pos = pins[i]*size
		var owned = model != null and model.s.stores[i].owned
		draw_circle(pos,15,INK)
		draw_circle(pos,12,Color("ffd365") if owned else Color("eff0dc"))
		draw_string(ThemeDB.fallback_font,pos+Vector2(-4,5),str(i+1),HORIZONTAL_ALIGNMENT_LEFT,-1,14,INK)
		if model != null and model.s.active == i: draw_arc(pos,19,0,TAU,24,Color("f77857"),3,true)
