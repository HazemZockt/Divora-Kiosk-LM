extends SceneTree
const Model = preload("res://tycoon/idle_economy.gd")
const Storage = preload("res://tycoon/idle_save.gd")
func _initialize():
	var e = Model.new()
	e.s.cash = 1000000000
	for shop in e.s.stores:
		shop.owned = true
		shop.level = 20
		shop.manager = true
		shop.staff = 5
		for p in range(7): shop.unlocked[p] = true; shop.stock[p] = 60
	var begin = Time.get_ticks_msec()
	var result = e.offline(8*3600)
	var ms = Time.get_ticks_msec()-begin
	if e.s.sales < 10000 or e.s.rent_paid <= 0 or e.s.wages <= 0 or not Storage.new().valid(e.s):
		printerr("Long-running economy failed: ",result)
		quit(1)
		return
	print("IDLE LONGRUN PASS: 8h, %d sales, %d ms, rents and wages charged, save valid" % [int(e.s.sales),ms])
	quit(0)
