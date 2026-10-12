extends Control
## Small native vector artwork keeps animated elements crisp at every window size.
var kind = "gem"
var tint = Color("55bfe5")
const INK = Color("173d50")
func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
func _draw():
	var k = minf(size.x,size.y)/64.0
	draw_set_transform((size-Vector2(64,64)*k)*0.5,0,Vector2(k,k))
	match kind:
		"gem":
			var outline = PackedVector2Array([Vector2(6,24),Vector2(19,8),Vector2(45,8),Vector2(58,24),Vector2(32,58)])
			draw_colored_polygon(outline,Color("9c5fe8"))
			draw_polyline(outline+PackedVector2Array([outline[0]]),INK,3,true)
			draw_colored_polygon(PackedVector2Array([Vector2(19,9),Vector2(45,9),Vector2(39,25),Vector2(25,25)]),Color("efbcff"))
			draw_colored_polygon(PackedVector2Array([Vector2(25,25),Vector2(39,25),Vector2(32,57)]),Color("c48aff"))
			draw_line(Vector2(8,25),Vector2(56,25),Color("edc9ff"),2)
		"water","soda","vape":
			draw_style_box(block(INK),Rect2(19,8,26,51))
			draw_style_box(block(tint),Rect2(22,11,20,44))
			draw_rect(Rect2(22,29,20,17),Color("f8f2de"))
			draw_rect(Rect2(25,4,14,8),INK)
			draw_rect(Rect2(26,5,12,5),Color("f4f9f3"))
			draw_line(Vector2(26,16),Vector2(26,25),Color.WHITE,3)
		"chips":
			draw_colored_polygon(PackedVector2Array([Vector2(14,8),Vector2(50,8),Vector2(54,57),Vector2(10,57)]),INK)
			draw_colored_polygon(PackedVector2Array([Vector2(17,11),Vector2(47,11),Vector2(50,54),Vector2(14,54)]),tint)
			draw_circle(Vector2(32,33),13,Color("ffdc72"))
			draw_arc(Vector2(30,32),8,-1,2,14,Color("d39b3d"),2,true)
		"coffee":
			draw_arc(Vector2(45,31),12,-1.5,1.5,20,INK,5,true)
			draw_style_box(block(INK),Rect2(14,17,32,37))
			draw_style_box(block(Color("fff1d0")),Rect2(17,20,26,31))
			draw_circle(Vector2(30,35),9,tint)
			draw_line(Vector2(24,6),Vector2(21,12),Color("8ca9ad"),3)
			draw_line(Vector2(36,5),Vector2(33,12),Color("8ca9ad"),3)
		"sandwich":
			for entry in [[47,INK],[42,Color("ffc47b")],[36,Color("70b963")],[30,Color("f47254")],[24,Color("ffda88")]]:
				draw_colored_polygon(PackedVector2Array([Vector2(8,entry[0]),Vector2(56,entry[0]),Vector2(32,entry[0]-17)]),entry[1])
		"snus":
			draw_circle(Vector2(32,34),24,INK)
			draw_circle(Vector2(32,32),21,tint)
			draw_circle(Vector2(32,29),15,Color("e2f1dc"))
			draw_string(ThemeDB.fallback_font,Vector2(21,35),"18",HORIZONTAL_ALIGNMENT_LEFT,-1,17,INK)
		"star":
			var points = PackedVector2Array()
			for n in range(10):
				points.append(Vector2(32,32)+Vector2.from_angle(n*PI/5-PI/2)*(28 if n%2 == 0 else 13))
			draw_colored_polygon(points,Color("ffd453"))
			draw_polyline(points+PackedVector2Array([points[0]]),INK,3,true)
		"shop":
			draw_style_box(block(INK),Rect2(8,23,48,34))
			draw_rect(Rect2(12,26,40,27),Color("fff2d7"))
			for n in range(6): draw_rect(Rect2(5+n*9,12,9,17),Color("ff7c5e") if n%2 == 0 else Color("fff2d7"))
			draw_rect(Rect2(17,35,12,18),Color("49aaba"))
			draw_rect(Rect2(35,33,12,12),Color("49aaba"))
		"team":
			person(Vector2(31,10),0.8,Color("53baba"),0)
		"map":
			draw_colored_polygon(PackedVector2Array([Vector2(6,15),Vector2(23,8),Vector2(41,16),Vector2(58,9),Vector2(58,52),Vector2(41,59),Vector2(23,51),Vector2(6,58)]),Color("85c9a0"))
			draw_circle(Vector2(34,27),12,Color("f8795a"))
			draw_colored_polygon(PackedVector2Array([Vector2(24,33),Vector2(44,33),Vector2(34,46)]),Color("f8795a"))
			draw_circle(Vector2(34,26),5,Color("fff6dd"))
		"shield":
			var p = PackedVector2Array([Vector2(9,13),Vector2(32,5),Vector2(55,13),Vector2(51,42),Vector2(32,59),Vector2(13,42)])
			draw_colored_polygon(p,INK)
			draw_colored_polygon(PackedVector2Array([Vector2(13,16),Vector2(32,9),Vector2(51,16),Vector2(47,40),Vector2(32,54),Vector2(17,40)]),Color("62b8dc"))
			draw_line(Vector2(22,31),Vector2(30,39),Color.WHITE,5)
			draw_line(Vector2(30,39),Vector2(44,23),Color.WHITE,5)

func block(color: Color) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(5)
	return style

func person(at: Vector2, scale_value: float, shirt: Color, variant: int, phase: float = 0):
	var skin = [Color("e5a76c"),Color("a96c49"),Color("f5c39a")][variant%3]
	var bounce = sin(phase)*1.4
	draw_set_transform(at+Vector2(0,bounce),0,Vector2.ONE*scale_value)
	# Shadow, shoes, trouser legs, soft jacket, hands and large expressive face.
	draw_ellipse(Vector2(0,57),Vector2(15,4),Color(0,0,0,0.16))
	for side in [-1,1]:
		draw_line(Vector2(side*5,40),Vector2(side*6+sin(phase)*side*2,54),INK,7,true)
		draw_circle(Vector2(side*7,54),4,Color("263e51"))
	draw_style_box(block(INK),Rect2(-14,20,28,24))
	draw_style_box(block(shirt),Rect2(-11,21,22,20))
	for side in [-1,1]:
		draw_line(Vector2(side*13,25),Vector2(side*16,37),INK,7,true)
		draw_circle(Vector2(side*16,37),3.5,skin)
	draw_circle(Vector2(0,8),19,INK)
	draw_circle(Vector2(0,8),16,skin)
	draw_arc(Vector2(0,7),17,PI,TAU,20,Color("3e3434"),7,true)
	for side in [-1,1]:
		draw_circle(Vector2(side*6,7),4.5,Color.WHITE)
		draw_circle(Vector2(side*5,8),2.4,INK)
	draw_arc(Vector2(0,11),8,0.3,PI-0.3,12,INK,2,true)
	if variant%2 == 0:
		draw_style_box(block(shirt.darkened(0.2)),Rect2(-19,-10,38,7))
		draw_style_box(block(shirt),Rect2(-13,-18,26,12))
	draw_set_transform(Vector2.ZERO)

func draw_ellipse(center: Vector2, radius: Vector2, color: Color):
	var points = PackedVector2Array()
	for n in range(24): points.append(center+Vector2(cos(n*TAU/24)*radius.x,sin(n*TAU/24)*radius.y))
	draw_colored_polygon(points,color)
