extends Control
## Ana menü: Başla / Çıkış, rekor ve toplam altın.


func _ready() -> void:
	var d := Kayit.yukle()
	%RekorEtiketi.text = "Rekor: %d m" % d["rekor"]
	%AltinEtiketi.text = "Toplam altın: %d" % d["toplam_altin"]
	%BaslaDugme.pressed.connect(basla)
	%CikisDugme.pressed.connect(func() -> void: get_tree().quit())
	# Web ve mobilde "Çıkış" anlamsız.
	%CikisDugme.visible = not (OS.has_feature("web") or OS.has_feature("mobile"))
	%BaslaDugme.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("zipla") or (event is InputEventScreenTouch and event.pressed):
		get_viewport().set_input_as_handled()
		basla()


func basla() -> void:
	get_tree().change_scene_to_file("res://scenes/oyun.tscn")
