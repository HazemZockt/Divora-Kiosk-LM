extends RefCounted
const INK = Color("173d50")
const MUTED = Color("597780")
const CREAM = Color("fff9e8")
const TEAL = Color("1a8b94")
const CORAL = Color("e87750")
const GOLD = Color("ffcf61")
const Art = preload("res://tycoon/idle_art.gd")
var app

func style(color: Color, radius: int = 12, border: bool = false) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	if border:
		s.set_border_width_all(2)
		s.border_color = INK
		s.shadow_color = Color(0.07,0.2,0.24,0.12)
		s.shadow_size = 2
		s.shadow_offset = Vector2(0,3)
	s.content_margin_left = 12
	s.content_margin_right = 12
	s.content_margin_top = 10
	s.content_margin_bottom = 10
	return s

func label(parent: Node, value: String, font_size: int = 16, color: Color = INK) -> Label:
	var l = Label.new()
	l.text = value
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	l.add_theme_font_size_override("font_size",font_size)
	l.add_theme_color_override("font_color",color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func live(parent: Node, value: Callable, font_size: int = 16, color: Color = INK) -> Label:
	var l = label(parent,"",font_size,color)
	app.bind(func(): l.text = str(value.call()))
	return l

func row(parent: Node, separation: int = 8) -> HBoxContainer:
	var h = HBoxContainer.new()
	h.add_theme_constant_override("separation",separation)
	h.mouse_filter = Control.MOUSE_FILTER_PASS
	parent.add_child(h)
	return h

func card(parent: Node, color: Color = Color("ffffff")) -> VBoxContainer:
	var panel = PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel",style(color,12,true))
	parent.add_child(panel)
	var v = VBoxContainer.new()
	v.add_theme_constant_override("separation",8)
	v.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_child(v)
	return v

func icon(parent: Node, kind: String, tint: Color = TEAL, width: int = 52) -> Control:
	var art = Art.new()
	art.kind = kind
	art.tint = tint
	art.custom_minimum_size = Vector2(width,width)
	art.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	parent.add_child(art)
	return art

func button(parent: Node, title: String, action: Callable, color: Color = TEAL) -> Button:
	var b = Button.new()
	b.text = title
	b.custom_minimum_size.y = 48
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_size_override("font_size",15)
	b.add_theme_color_override("font_color",CREAM if color == TEAL else INK)
	b.add_theme_color_override("font_hover_color",CREAM if color == TEAL else INK)
	b.add_theme_color_override("font_focus_color",CREAM if color == TEAL else INK)
	b.add_theme_color_override("font_hover_pressed_color",INK)
	b.add_theme_color_override("font_pressed_color",INK)
	b.add_theme_color_override("font_disabled_color",Color("657d85"))
	b.add_theme_stylebox_override("normal",style(color,10,true))
	b.add_theme_stylebox_override("hover",style(color.lightened(0.09),10,true))
	b.add_theme_stylebox_override("pressed",style(GOLD,10,true))
	b.add_theme_stylebox_override("disabled",style(Color("dde6e4"),10,false))
	b.add_theme_stylebox_override("focus",style(Color(0,0,0,0),10,true))
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	b.action_mode = BaseButton.ACTION_MODE_BUTTON_RELEASE
	parent.add_child(b)
	b.pressed.connect(func():
		if app.can_activate(): action.call())
	return b

func live_button(parent: Node, title: Callable, action: Callable, enabled: Callable, color: Color = TEAL) -> Button:
	var b = button(parent,"",action,color)
	app.bind(func():
		b.text = str(title.call())
		b.disabled = not bool(enabled.call()))
	return b

func heading(parent: Node, title: String, hint: String = ""):
	label(parent,title,25)
	if hint != "": label(parent,hint,14,MUTED)
